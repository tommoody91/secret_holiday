"""
Amadeus API Service

Handles authentication and API calls to Amadeus for:
- Flight Inspiration Search (destination suggestions by price)
- Airport Nearest Relevant (find airports near a location)
- Future: Hotel Search, Points of Interest, etc.
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Optional

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class AmadeusService:
    """
    Amadeus API client with OAuth token caching.
    
    Tokens are valid for ~30 minutes, so we cache and reuse them.
    """
    
    _instance: Optional["AmadeusService"] = None
    
    def __init__(self):
        self._access_token: Optional[str] = None
        self._token_expires_at: Optional[datetime] = None
        self._lock = asyncio.Lock()
        self.base_url = settings.AMADEUS_BASE_URL
        
    @classmethod
    def get_instance(cls) -> "AmadeusService":
        """Get singleton instance."""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    async def _get_token(self) -> str:
        """
        Get a valid access token, refreshing if needed.
        
        Uses double-checked locking to avoid race conditions.
        """
        # Quick check without lock
        if self._is_token_valid():
            return self._access_token  # type: ignore
        
        async with self._lock:
            # Re-check after acquiring lock
            if self._is_token_valid():
                return self._access_token  # type: ignore
            
            # Token expired or missing, get a new one
            await self._refresh_token()
            return self._access_token  # type: ignore
    
    def _is_token_valid(self) -> bool:
        """Check if current token is still valid (with 60s buffer)."""
        if not self._access_token or not self._token_expires_at:
            return False
        return datetime.now() < self._token_expires_at - timedelta(seconds=60)
    
    async def _refresh_token(self) -> None:
        """Get a new OAuth token from Amadeus."""
        logger.info("Refreshing Amadeus OAuth token...")
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/v1/security/oauth2/token",
                data={
                    "grant_type": "client_credentials",
                    "client_id": settings.AMADEUS_API_KEY,
                    "client_secret": settings.AMADEUS_API_SECRET,
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            
            if response.status_code != 200:
                logger.error(f"Failed to get Amadeus token: {response.text}")
                raise Exception(f"Amadeus auth failed: {response.status_code}")
            
            data = response.json()
            self._access_token = data["access_token"]
            expires_in = data.get("expires_in", 1799)  # Default ~30 mins
            self._token_expires_at = datetime.now() + timedelta(seconds=expires_in)
            
            logger.info(f"Amadeus token refreshed, expires in {expires_in}s")
    
    async def _request(
        self,
        method: str,
        endpoint: str,
        params: Optional[dict] = None,
        json_data: Optional[dict] = None,
    ) -> dict:
        """
        Make an authenticated request to Amadeus API.
        
        Args:
            method: HTTP method (GET, POST, etc.)
            endpoint: API endpoint (e.g., /v1/shopping/flight-destinations)
            params: Query parameters
            json_data: JSON body for POST requests
            
        Returns:
            Response JSON as dict
        """
        token = await self._get_token()
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.request(
                method=method,
                url=f"{self.base_url}{endpoint}",
                params=params,
                json=json_data,
                headers={
                    "Authorization": f"Bearer {token}",
                    "Accept": "application/json",
                },
            )
            
            if response.status_code == 401:
                # Token might have expired, try once more
                logger.warning("Amadeus returned 401, refreshing token...")
                await self._refresh_token()
                token = self._access_token
                
                response = await client.request(
                    method=method,
                    url=f"{self.base_url}{endpoint}",
                    params=params,
                    json=json_data,
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Accept": "application/json",
                    },
                )
            
            if response.status_code != 200:
                logger.error(f"Amadeus API error: {response.status_code} - {response.text}")
                raise Exception(f"Amadeus API error: {response.status_code}")
            
            return response.json()
    
    async def get_nearest_airports(
        self,
        latitude: float,
        longitude: float,
        radius: int = 100,
        max_results: int = 5,
    ) -> list[dict]:
        """
        Find airports near a location.
        
        Args:
            latitude: Location latitude
            longitude: Location longitude
            radius: Search radius in km (default 100)
            max_results: Maximum airports to return
            
        Returns:
            List of airport dicts with iataCode, name, distance, etc.
        """
        try:
            result = await self._request(
                "GET",
                "/v1/reference-data/locations/airports",
                params={
                    "latitude": latitude,
                    "longitude": longitude,
                    "radius": radius,
                    "page[limit]": max_results,
                    "sort": "relevance",
                },
            )
            return result.get("data", [])
        except Exception as e:
            logger.error(f"Failed to get nearest airports: {e}")
            return []
    
    async def get_flight_destinations(
        self,
        origin: str,
        departure_date: Optional[str] = None,
        one_way: bool = False,
        duration: Optional[str] = None,
        max_price: Optional[int] = None,
        view_by: str = "DATE",
    ) -> list[dict]:
        """
        Get flight destination suggestions from an origin.
        
        This uses the Flight Inspiration Search API which returns
        destinations sorted by price.
        
        Args:
            origin: IATA airport/city code (e.g., "LON", "LTN")
            departure_date: Date or date range (e.g., "2025-06" for whole month)
            one_way: If True, search one-way flights only
            duration: Trip duration (e.g., "1" for 1 night, "1,2,3" for range)
            max_price: Maximum price in the currency of the origin
            view_by: "DATE", "DURATION", "WEEK", or "DESTINATION"
            
        Returns:
            List of destination dicts with destination, price, departureDate, etc.
        """
        params = {
            "origin": origin,
            "oneWay": str(one_way).lower(),
            "viewBy": view_by,
        }
        
        if departure_date:
            params["departureDate"] = departure_date
        if duration:
            params["duration"] = duration
        if max_price:
            params["maxPrice"] = max_price
        
        try:
            result = await self._request(
                "GET",
                "/v1/shopping/flight-destinations",
                params=params,
            )
            return result.get("data", [])
        except Exception as e:
            logger.error(f"Failed to get flight destinations: {e}")
            return []
    
    async def get_flight_offers(
        self,
        origin: str,
        destination: str,
        departure_date: str,
        return_date: Optional[str] = None,
        adults: int = 1,
        max_results: int = 10,
        max_price: Optional[int] = None,
        currency: str = "GBP",
    ) -> list[dict]:
        """
        Search for actual bookable flight offers.
        
        This is more expensive (API quota) than inspiration search,
        use only when user selects a specific destination.
        
        Args:
            origin: Origin IATA code
            destination: Destination IATA code
            departure_date: Departure date (YYYY-MM-DD)
            return_date: Return date for round trips
            adults: Number of adult passengers
            max_results: Maximum offers to return
            max_price: Maximum total price
            currency: Currency code (default GBP)
            
        Returns:
            List of flight offer dicts
        """
        params = {
            "originLocationCode": origin,
            "destinationLocationCode": destination,
            "departureDate": departure_date,
            "adults": adults,
            "max": max_results,
            "currencyCode": currency,
        }
        
        if return_date:
            params["returnDate"] = return_date
        if max_price:
            params["maxPrice"] = max_price
        
        try:
            result = await self._request(
                "GET",
                "/v2/shopping/flight-offers",
                params=params,
            )
            return result.get("data", [])
        except Exception as e:
            logger.error(f"Failed to get flight offers: {e}")
            return []


# Convenience function for dependency injection
def get_amadeus_service() -> AmadeusService:
    """Get the Amadeus service singleton."""
    return AmadeusService.get_instance()
