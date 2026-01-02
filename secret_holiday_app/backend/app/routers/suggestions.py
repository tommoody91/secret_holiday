"""
Destination Suggestions API Router

Provides AI-powered destination suggestions based on:
- Starting location (UK postcode or city)
- Budget per person
- Travel dates (specific or flexible)
- Number of travelers
"""

import logging
from calendar import monthrange
from collections import defaultdict
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException

from app.models.suggestions import (
    DestinationSuggestion,
    OriginAirport,
    SuggestionRequest,
    SuggestionResponse,
    TravelDateType,
)
from app.services.amadeus import AmadeusService, get_amadeus_service
from app.services.auth import FirebaseUser, get_current_user
from app.services.geocoding import geocode_uk_location

logger = logging.getLogger(__name__)

router = APIRouter()

# IATA code to city/country mapping for enrichment
# This covers common European destinations
DESTINATION_INFO = {
    # Spain
    "BCN": ("Barcelona", "Spain", "ES"),
    "MAD": ("Madrid", "Spain", "ES"),
    "AGP": ("Malaga", "Spain", "ES"),
    "ALC": ("Alicante", "Spain", "ES"),
    "PMI": ("Palma de Mallorca", "Spain", "ES"),
    "IBZ": ("Ibiza", "Spain", "ES"),
    "VLC": ("Valencia", "Spain", "ES"),
    "SVQ": ("Seville", "Spain", "ES"),
    "BIO": ("Bilbao", "Spain", "ES"),
    "TFS": ("Tenerife South", "Spain", "ES"),
    "LPA": ("Gran Canaria", "Spain", "ES"),
    "ACE": ("Lanzarote", "Spain", "ES"),
    "FUE": ("Fuerteventura", "Spain", "ES"),
    
    # France
    "CDG": ("Paris", "France", "FR"),
    "ORY": ("Paris Orly", "France", "FR"),
    "NCE": ("Nice", "France", "FR"),
    "LYS": ("Lyon", "France", "FR"),
    "MRS": ("Marseille", "France", "FR"),
    "TLS": ("Toulouse", "France", "FR"),
    "BOD": ("Bordeaux", "France", "FR"),
    
    # Italy
    "FCO": ("Rome", "Italy", "IT"),
    "MXP": ("Milan Malpensa", "Italy", "IT"),
    "LIN": ("Milan Linate", "Italy", "IT"),
    "VCE": ("Venice", "Italy", "IT"),
    "NAP": ("Naples", "Italy", "IT"),
    "FLR": ("Florence", "Italy", "IT"),
    "PSA": ("Pisa", "Italy", "IT"),
    "BLQ": ("Bologna", "Italy", "IT"),
    "CTA": ("Catania", "Italy", "IT"),
    "PMO": ("Palermo", "Italy", "IT"),
    
    # Germany
    "FRA": ("Frankfurt", "Germany", "DE"),
    "MUC": ("Munich", "Germany", "DE"),
    "BER": ("Berlin", "Germany", "DE"),
    "DUS": ("Dusseldorf", "Germany", "DE"),
    "HAM": ("Hamburg", "Germany", "DE"),
    "CGN": ("Cologne", "Germany", "DE"),
    "STR": ("Stuttgart", "Germany", "DE"),
    
    # Netherlands
    "AMS": ("Amsterdam", "Netherlands", "NL"),
    "RTM": ("Rotterdam", "Netherlands", "NL"),
    "EIN": ("Eindhoven", "Netherlands", "NL"),
    
    # Belgium
    "BRU": ("Brussels", "Belgium", "BE"),
    "CRL": ("Brussels Charleroi", "Belgium", "BE"),
    
    # Portugal
    "LIS": ("Lisbon", "Portugal", "PT"),
    "OPO": ("Porto", "Portugal", "PT"),
    "FAO": ("Faro", "Portugal", "PT"),
    "FNC": ("Funchal", "Portugal", "PT"),
    
    # Greece
    "ATH": ("Athens", "Greece", "GR"),
    "SKG": ("Thessaloniki", "Greece", "GR"),
    "HER": ("Heraklion", "Greece", "GR"),
    "RHO": ("Rhodes", "Greece", "GR"),
    "CFU": ("Corfu", "Greece", "GR"),
    "JTR": ("Santorini", "Greece", "GR"),
    "JMK": ("Mykonos", "Greece", "GR"),
    
    # Croatia
    "DBV": ("Dubrovnik", "Croatia", "HR"),
    "SPU": ("Split", "Croatia", "HR"),
    "ZAG": ("Zagreb", "Croatia", "HR"),
    
    # Czech Republic
    "PRG": ("Prague", "Czech Republic", "CZ"),
    
    # Poland
    "WAW": ("Warsaw", "Poland", "PL"),
    "KRK": ("Krakow", "Poland", "PL"),
    "GDN": ("Gdansk", "Poland", "PL"),
    
    # Hungary
    "BUD": ("Budapest", "Hungary", "HU"),
    
    # Austria
    "VIE": ("Vienna", "Austria", "AT"),
    "SZG": ("Salzburg", "Austria", "AT"),
    
    # Switzerland
    "ZRH": ("Zurich", "Switzerland", "CH"),
    "GVA": ("Geneva", "Switzerland", "CH"),
    
    # Ireland
    "DUB": ("Dublin", "Ireland", "IE"),
    "SNN": ("Shannon", "Ireland", "IE"),
    "ORK": ("Cork", "Ireland", "IE"),
    
    # Scandinavia
    "CPH": ("Copenhagen", "Denmark", "DK"),
    "OSL": ("Oslo", "Norway", "NO"),
    "ARN": ("Stockholm", "Sweden", "SE"),
    "HEL": ("Helsinki", "Finland", "FI"),
    "KEF": ("Reykjavik", "Iceland", "IS"),
    
    # Baltic
    "TLL": ("Tallinn", "Estonia", "EE"),
    "RIX": ("Riga", "Latvia", "LV"),
    "VNO": ("Vilnius", "Lithuania", "LT"),
    
    # Turkey
    "IST": ("Istanbul", "Turkey", "TR"),
    "SAW": ("Istanbul Sabiha", "Turkey", "TR"),
    "AYT": ("Antalya", "Turkey", "TR"),
    "DLM": ("Dalaman", "Turkey", "TR"),
    "BJV": ("Bodrum", "Turkey", "TR"),
    
    # Cyprus
    "LCA": ("Larnaca", "Cyprus", "CY"),
    "PFO": ("Paphos", "Cyprus", "CY"),
    
    # Malta
    "MLA": ("Malta", "Malta", "MT"),
    
    # Morocco
    "RAK": ("Marrakech", "Morocco", "MA"),
    "CMN": ("Casablanca", "Morocco", "MA"),
    
    # Other
    "GIB": ("Gibraltar", "Gibraltar", "GI"),
    "TGD": ("Podgorica", "Montenegro", "ME"),
    "TIV": ("Tivat", "Montenegro", "ME"),
}


def get_destination_info(iata_code: str) -> tuple[str | None, str | None, str | None]:
    """Get city name, country, and country code for an IATA code."""
    return DESTINATION_INFO.get(iata_code.upper(), (None, None, None))


def build_date_params(request: SuggestionRequest) -> list[dict]:
    """
    Convert travel date specification into Amadeus API parameters.
    
    Returns a list of date parameter dicts to search.
    """
    params_list = []
    travel = request.travel_dates
    duration = str(request.trip_length_nights)
    
    if travel.type == TravelDateType.SPECIFIC:
        # Specific date range
        if travel.start_date and travel.end_date:
            params_list.append({
                "departureDate": travel.start_date.isoformat(),
                "duration": duration,
            })
    
    elif travel.type == TravelDateType.MONTH:
        # Whole month - Amadeus needs yyyy-MM-dd format, use first day of month
        if travel.month:
            # Convert "2026-03" to "2026-03-01"
            departure_date = f"{travel.month}-01"
            params_list.append({
                "departureDate": departure_date,
                "duration": duration,
            })
    
    elif travel.type == TravelDateType.FLEXIBLE:
        # Multiple months - use first day of each month
        if travel.preferred_months:
            for month in travel.preferred_months[:3]:  # Limit to 3 months
                departure_date = f"{month}-01"
                params_list.append({
                    "departureDate": departure_date,
                    "duration": duration,
                })
    
    # Default: next 3 months if nothing specified
    if not params_list:
        today = date.today()
        for i in range(1, 4):
            month = (today.month + i - 1) % 12 + 1
            year = today.year + ((today.month + i - 1) // 12)
            params_list.append({
                "departureDate": f"{year}-{month:02d}-01",
                "duration": duration,
            })
    
    return params_list


@router.post(
    "/suggest",
    response_model=SuggestionResponse,
    summary="Get destination suggestions",
    description="Get destination suggestions based on starting location, budget, and travel dates",
)
async def suggest_destinations(
    request: SuggestionRequest,
    user: FirebaseUser = Depends(get_current_user),
    amadeus: AmadeusService = Depends(get_amadeus_service),
) -> SuggestionResponse:
    """
    Get destination suggestions under budget.
    
    Flow:
    1. Geocode starting location (postcode/city)
    2. Find nearby airports
    3. Search flight destinations from each airport
    4. Merge and rank by price
    5. Return top results
    """
    logger.info(f"Suggestion request from user {user.uid}: {request.starting_location}")
    
    # Step 1: Geocode the starting location
    location = await geocode_uk_location(request.starting_location)
    if not location:
        raise HTTPException(
            status_code=400,
            detail=f"Could not find location: {request.starting_location}. Please enter a valid UK postcode or city name."
        )
    
    logger.info(f"Geocoded {request.starting_location} to {location.latitude}, {location.longitude}")
    
    # Step 2: Find nearby airports
    airports = await amadeus.get_nearest_airports(
        latitude=location.latitude,
        longitude=location.longitude,
        radius=150,  # 150km radius
        max_results=request.max_origins,
    )
    
    if not airports:
        raise HTTPException(
            status_code=404,
            detail=f"No airports found near {request.starting_location}"
        )
    
    origins_used = [
        OriginAirport(
            iata_code=a["iataCode"],
            name=a.get("name", a["iataCode"]),
            distance_km=a.get("distance", {}).get("value"),
        )
        for a in airports
    ]
    
    logger.info(f"Found {len(origins_used)} airports: {[o.iata_code for o in origins_used]}")
    
    # Step 3: Build date parameters
    date_params_list = build_date_params(request)
    
    # Step 4: Search destinations from each airport
    # Collect all results, keeping best price per destination
    destination_prices: dict[str, dict] = defaultdict(lambda: {
        "price": float("inf"),
        "origin": None,
        "departure_date": None,
        "return_date": None,
    })
    
    for origin in origins_used:
        for date_params in date_params_list:
            try:
                results = await amadeus.get_flight_destinations(
                    origin=origin.iata_code,
                    departure_date=date_params.get("departureDate"),
                    duration=date_params.get("duration"),
                    max_price=request.budget_per_person,
                    view_by="DESTINATION",
                )
                
                for dest in results:
                    dest_code = dest.get("destination")
                    if not dest_code:
                        continue
                    
                    price = float(dest.get("price", {}).get("total", float("inf")))
                    
                    # Keep the cheapest option for each destination
                    if price < destination_prices[dest_code]["price"]:
                        destination_prices[dest_code] = {
                            "price": price,
                            "origin": origin.iata_code,
                            "departure_date": dest.get("departureDate"),
                            "return_date": dest.get("returnDate"),
                        }
                        
            except Exception as e:
                logger.warning(f"Search failed for {origin.iata_code}: {e}")
                continue
    
    # Step 5: Build and sort results
    suggestions: list[DestinationSuggestion] = []
    
    for dest_code, data in destination_prices.items():
        if data["price"] == float("inf"):
            continue
        
        city_name, country, country_code = get_destination_info(dest_code)
        
        # Build reasons
        reasons = []
        if data["price"] <= request.budget_per_person * 0.5:
            reasons.append("Great value - well under budget")
        elif data["price"] <= request.budget_per_person * 0.75:
            reasons.append("Good value")
        else:
            reasons.append("Within budget")
        
        suggestions.append(DestinationSuggestion(
            destination_code=dest_code,
            destination_name=city_name,
            country=country,
            country_code=country_code,
            best_origin=data["origin"],
            price_per_person=data["price"],
            total_price=data["price"] * request.travelers,
            departure_date=data["departure_date"],
            return_date=data["return_date"],
            reasons=reasons,
        ))
    
    # Sort by price (ascending)
    suggestions.sort(key=lambda s: s.price_per_person)
    
    total_found = len(suggestions)
    suggestions = suggestions[:request.max_results]
    
    logger.info(f"Found {total_found} destinations, returning top {len(suggestions)}")
    
    return SuggestionResponse(
        origins_used=origins_used,
        search_criteria={
            "starting_location": request.starting_location,
            "budget_per_person": request.budget_per_person,
            "travelers": request.travelers,
            "trip_length_nights": request.trip_length_nights,
            "travel_dates": request.travel_dates.model_dump(),
        },
        destinations=suggestions,
        total_found=total_found,
    )


@router.post(
    "/test",
    response_model=SuggestionResponse,
    summary="Test destination suggestions (no auth)",
    description="Test endpoint without authentication for debugging",
)
async def test_suggest_destinations(
    request: SuggestionRequest,
    amadeus: AmadeusService = Depends(get_amadeus_service),
) -> SuggestionResponse:
    """
    Test endpoint - same as /suggest but without auth.
    Remove this in production!
    """
    logger.info(f"TEST suggestion request: {request.starting_location}")
    
    # Step 1: Geocode the starting location
    location = await geocode_uk_location(request.starting_location)
    if not location:
        raise HTTPException(
            status_code=400,
            detail=f"Could not find location: {request.starting_location}. Please enter a valid UK postcode or city name."
        )
    
    logger.info(f"Geocoded {request.starting_location} to {location.latitude}, {location.longitude}")
    
    # Step 2: Find nearby airports
    airports = await amadeus.get_nearest_airports(
        latitude=location.latitude,
        longitude=location.longitude,
        radius=150,
        max_results=request.max_origins,
    )
    
    if not airports:
        raise HTTPException(
            status_code=404,
            detail=f"No airports found near {request.starting_location}"
        )
    
    origins_used = [
        OriginAirport(
            iata_code=a["iataCode"],
            name=a.get("name", a["iataCode"]),
            distance_km=a.get("distance", {}).get("value"),
        )
        for a in airports
    ]
    
    logger.info(f"Found {len(origins_used)} airports: {[o.iata_code for o in origins_used]}")
    
    # Step 3: Build date parameters
    date_params_list = build_date_params(request)
    
    # Step 4: Search destinations from each airport
    destination_prices: dict[str, dict] = defaultdict(lambda: {
        "price": float("inf"),
        "origin": None,
        "departure_date": None,
        "return_date": None,
    })
    
    for origin in origins_used:
        for date_params in date_params_list:
            try:
                logger.info(f"Searching from {origin.iata_code} with params: {date_params}")
                results = await amadeus.get_flight_destinations(
                    origin=origin.iata_code,
                    departure_date=date_params.get("departureDate"),
                    duration=date_params.get("duration"),
                    max_price=request.budget_per_person,
                    view_by="DESTINATION",
                )
                
                logger.info(f"Got {len(results)} results from {origin.iata_code}")
                
                for dest in results:
                    dest_code = dest.get("destination")
                    if not dest_code:
                        continue
                    
                    price = float(dest.get("price", {}).get("total", float("inf")))
                    
                    if price < destination_prices[dest_code]["price"]:
                        destination_prices[dest_code] = {
                            "price": price,
                            "origin": origin.iata_code,
                            "departure_date": dest.get("departureDate"),
                            "return_date": dest.get("returnDate"),
                        }
                        
            except Exception as e:
                logger.warning(f"Search failed for {origin.iata_code}: {e}")
                continue
    
    # Step 5: Build and sort results
    suggestions: list[DestinationSuggestion] = []
    
    for dest_code, data in destination_prices.items():
        if data["price"] == float("inf"):
            continue
        
        city_name, country, country_code = get_destination_info(dest_code)
        
        reasons = []
        if data["price"] <= request.budget_per_person * 0.5:
            reasons.append("Great value - well under budget")
        elif data["price"] <= request.budget_per_person * 0.75:
            reasons.append("Good value")
        else:
            reasons.append("Within budget")
        
        suggestions.append(DestinationSuggestion(
            destination_code=dest_code,
            destination_name=city_name,
            country=country,
            country_code=country_code,
            best_origin=data["origin"],
            price_per_person=data["price"],
            total_price=data["price"] * request.travelers,
            departure_date=data["departure_date"],
            return_date=data["return_date"],
            reasons=reasons,
        ))
    
    suggestions.sort(key=lambda s: s.price_per_person)
    
    total_found = len(suggestions)
    suggestions = suggestions[:request.max_results]
    
    logger.info(f"TEST: Found {total_found} destinations, returning top {len(suggestions)}")
    
    return SuggestionResponse(
        origins_used=origins_used,
        search_criteria={
            "starting_location": request.starting_location,
            "budget_per_person": request.budget_per_person,
            "travelers": request.travelers,
            "trip_length_nights": request.trip_length_nights,
            "travel_dates": request.travel_dates.model_dump(),
        },
        destinations=suggestions,
        total_found=total_found,
    )
