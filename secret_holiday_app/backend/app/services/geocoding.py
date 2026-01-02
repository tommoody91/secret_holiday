"""
UK Location Geocoding Service

Resolves UK postcodes and city names to coordinates using:
- Postcodes.io (free, no API key needed) for postcodes
- A built-in mapping for major UK cities
"""

import logging
import re
from dataclasses import dataclass
from typing import Optional

import httpx

logger = logging.getLogger(__name__)


@dataclass
class GeoLocation:
    """Geocoded location with coordinates."""
    latitude: float
    longitude: float
    name: str  # Normalized name (city or postcode)
    region: Optional[str] = None


# Major UK cities with their coordinates and nearby airport codes
UK_CITIES = {
    # England
    "london": GeoLocation(51.5074, -0.1278, "London", "Greater London"),
    "manchester": GeoLocation(53.4808, -2.2426, "Manchester", "North West"),
    "birmingham": GeoLocation(52.4862, -1.8904, "Birmingham", "West Midlands"),
    "leeds": GeoLocation(53.8008, -1.5491, "Leeds", "Yorkshire"),
    "liverpool": GeoLocation(53.4084, -2.9916, "Liverpool", "North West"),
    "newcastle": GeoLocation(54.9783, -1.6178, "Newcastle", "North East"),
    "sheffield": GeoLocation(53.3811, -1.4701, "Sheffield", "Yorkshire"),
    "bristol": GeoLocation(51.4545, -2.5879, "Bristol", "South West"),
    "nottingham": GeoLocation(52.9548, -1.1581, "Nottingham", "East Midlands"),
    "leicester": GeoLocation(52.6369, -1.1398, "Leicester", "East Midlands"),
    "southampton": GeoLocation(50.9097, -1.4044, "Southampton", "South East"),
    "portsmouth": GeoLocation(50.8198, -1.0880, "Portsmouth", "South East"),
    "brighton": GeoLocation(50.8225, -0.1372, "Brighton", "South East"),
    "oxford": GeoLocation(51.7520, -1.2577, "Oxford", "South East"),
    "cambridge": GeoLocation(52.2053, 0.1218, "Cambridge", "East"),
    "norwich": GeoLocation(52.6309, 1.2974, "Norwich", "East"),
    "york": GeoLocation(53.9591, -1.0815, "York", "Yorkshire"),
    "bath": GeoLocation(51.3811, -2.3590, "Bath", "South West"),
    "exeter": GeoLocation(50.7184, -3.5339, "Exeter", "South West"),
    "plymouth": GeoLocation(50.3755, -4.1427, "Plymouth", "South West"),
    "coventry": GeoLocation(52.4068, -1.5197, "Coventry", "West Midlands"),
    "reading": GeoLocation(51.4543, -0.9781, "Reading", "South East"),
    "milton keynes": GeoLocation(52.0406, -0.7594, "Milton Keynes", "South East"),
    "luton": GeoLocation(51.8787, -0.4200, "Luton", "East"),
    "peterborough": GeoLocation(52.5695, -0.2405, "Peterborough", "East"),
    "hull": GeoLocation(53.7676, -0.3274, "Hull", "Yorkshire"),
    "stoke": GeoLocation(53.0027, -2.1794, "Stoke-on-Trent", "West Midlands"),
    "stoke-on-trent": GeoLocation(53.0027, -2.1794, "Stoke-on-Trent", "West Midlands"),
    "derby": GeoLocation(52.9225, -1.4746, "Derby", "East Midlands"),
    "wolverhampton": GeoLocation(52.5870, -2.1288, "Wolverhampton", "West Midlands"),
    "sunderland": GeoLocation(54.9069, -1.3838, "Sunderland", "North East"),
    "middlesbrough": GeoLocation(54.5742, -1.2350, "Middlesbrough", "North East"),
    
    # Scotland
    "edinburgh": GeoLocation(55.9533, -3.1883, "Edinburgh", "Scotland"),
    "glasgow": GeoLocation(55.8642, -4.2518, "Glasgow", "Scotland"),
    "aberdeen": GeoLocation(57.1497, -2.0943, "Aberdeen", "Scotland"),
    "dundee": GeoLocation(56.4620, -2.9707, "Dundee", "Scotland"),
    "inverness": GeoLocation(57.4778, -4.2247, "Inverness", "Scotland"),
    
    # Wales
    "cardiff": GeoLocation(51.4816, -3.1791, "Cardiff", "Wales"),
    "swansea": GeoLocation(51.6214, -3.9436, "Swansea", "Wales"),
    "newport": GeoLocation(51.5842, -2.9977, "Newport", "Wales"),
    
    # Northern Ireland
    "belfast": GeoLocation(54.5973, -5.9301, "Belfast", "Northern Ireland"),
    "derry": GeoLocation(54.9966, -7.3086, "Derry", "Northern Ireland"),
    "londonderry": GeoLocation(54.9966, -7.3086, "Londonderry", "Northern Ireland"),
}

# UK postcode regex pattern
# Matches formats like: SW1A 1AA, M1 1AA, B1 1AA, etc.
UK_POSTCODE_PATTERN = re.compile(
    r"^([A-Z]{1,2}\d{1,2}[A-Z]?\s*\d[A-Z]{2})$",
    re.IGNORECASE
)


class GeocodingService:
    """Service for geocoding UK locations."""
    
    @staticmethod
    def is_uk_postcode(text: str) -> bool:
        """Check if text looks like a UK postcode."""
        return bool(UK_POSTCODE_PATTERN.match(text.strip()))
    
    @staticmethod
    def normalize_postcode(postcode: str) -> str:
        """Normalize postcode format (e.g., 'sw1a1aa' -> 'SW1A 1AA')."""
        clean = postcode.upper().replace(" ", "")
        # Insert space before last 3 characters
        if len(clean) > 3:
            return f"{clean[:-3]} {clean[-3:]}"
        return clean
    
    @staticmethod
    async def geocode_postcode(postcode: str) -> Optional[GeoLocation]:
        """
        Geocode a UK postcode using Postcodes.io.
        
        Args:
            postcode: UK postcode (any format)
            
        Returns:
            GeoLocation if found, None otherwise
        """
        normalized = GeocodingService.normalize_postcode(postcode)
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.get(
                    f"https://api.postcodes.io/postcodes/{normalized.replace(' ', '%20')}"
                )
                
                if response.status_code == 200:
                    data = response.json()
                    if data.get("status") == 200 and data.get("result"):
                        result = data["result"]
                        return GeoLocation(
                            latitude=result["latitude"],
                            longitude=result["longitude"],
                            name=normalized,
                            region=result.get("region"),
                        )
                
                logger.warning(f"Postcode not found: {normalized}")
                return None
                
            except Exception as e:
                logger.error(f"Postcodes.io error: {e}")
                return None
    
    @staticmethod
    def geocode_city(city_name: str) -> Optional[GeoLocation]:
        """
        Look up a UK city by name.
        
        Args:
            city_name: City name (case insensitive)
            
        Returns:
            GeoLocation if found, None otherwise
        """
        normalized = city_name.lower().strip()
        return UK_CITIES.get(normalized)
    
    @classmethod
    async def geocode(cls, location: str) -> Optional[GeoLocation]:
        """
        Geocode any UK location (postcode or city name).
        
        Args:
            location: UK postcode or city name
            
        Returns:
            GeoLocation if found, None otherwise
        """
        location = location.strip()
        
        # Try as postcode first
        if cls.is_uk_postcode(location):
            result = await cls.geocode_postcode(location)
            if result:
                return result
        
        # Try as city name
        city_result = cls.geocode_city(location)
        if city_result:
            return city_result
        
        # If not a recognized city, try postcode API anyway
        # (handles edge cases like partial postcodes)
        if not cls.is_uk_postcode(location):
            # Last resort: try it as a postcode
            return await cls.geocode_postcode(location)
        
        return None


# Convenience function
async def geocode_uk_location(location: str) -> Optional[GeoLocation]:
    """Geocode a UK postcode or city name."""
    return await GeocodingService.geocode(location)
