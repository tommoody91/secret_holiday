"""
Pydantic models for destination suggestions API.
"""

from datetime import date
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class TravelDateType(str, Enum):
    """Type of travel date specification."""
    SPECIFIC = "specific"  # Exact date range
    MONTH = "month"        # Any time in a month
    FLEXIBLE = "flexible"  # Multiple months


class TravelDates(BaseModel):
    """Travel date specification."""
    type: TravelDateType
    # For SPECIFIC: start and end dates
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    # For MONTH: single month (YYYY-MM)
    month: Optional[str] = None
    # For FLEXIBLE: list of preferred months
    preferred_months: Optional[list[str]] = None


class SuggestionRequest(BaseModel):
    """Request for destination suggestions."""
    starting_location: str = Field(
        ...,
        description="UK postcode or city name",
        examples=["EN7 6TB", "London", "Manchester"]
    )
    travel_dates: TravelDates
    budget_per_person: int = Field(
        ...,
        gt=0,
        description="Maximum budget per person in GBP"
    )
    travelers: int = Field(
        default=1,
        ge=1,
        le=20,
        description="Number of travelers"
    )
    trip_length_nights: int = Field(
        default=3,
        ge=1,
        le=14,
        description="Trip duration in nights"
    )
    max_origins: int = Field(
        default=4,
        ge=1,
        le=6,
        description="Maximum number of origin airports to search"
    )
    max_results: int = Field(
        default=30,
        ge=1,
        le=100,
        description="Maximum destinations to return"
    )
    non_stop_only: bool = Field(
        default=False,
        description="Only return non-stop flights"
    )
    
    class Config:
        json_schema_extra = {
            "example": {
                "starting_location": "EN7 6TB",
                "travel_dates": {
                    "type": "month",
                    "month": "2025-05"
                },
                "budget_per_person": 200,
                "travelers": 4,
                "trip_length_nights": 3,
            }
        }


class OriginAirport(BaseModel):
    """An origin airport used in the search."""
    iata_code: str
    name: str
    distance_km: Optional[float] = None


class DestinationSuggestion(BaseModel):
    """A suggested destination."""
    destination_code: str = Field(
        ...,
        description="IATA airport/city code"
    )
    destination_name: Optional[str] = Field(
        None,
        description="Destination city/airport name"
    )
    country: Optional[str] = Field(
        None,
        description="Destination country"
    )
    country_code: Optional[str] = Field(
        None,
        description="ISO country code"
    )
    best_origin: str = Field(
        ...,
        description="Best origin airport for this destination"
    )
    price_per_person: float = Field(
        ...,
        description="Indicative price per person in GBP"
    )
    total_price: Optional[float] = Field(
        None,
        description="Total price for all travelers"
    )
    departure_date: Optional[str] = Field(
        None,
        description="Suggested departure date"
    )
    return_date: Optional[str] = Field(
        None,
        description="Suggested return date"
    )
    currency: str = "GBP"
    reasons: list[str] = Field(
        default_factory=list,
        description="Why this destination is suggested"
    )
    
    # Optional enrichment data (can be added later)
    image_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class SuggestionResponse(BaseModel):
    """Response containing destination suggestions."""
    origins_used: list[OriginAirport] = Field(
        ...,
        description="Origin airports that were searched"
    )
    search_criteria: dict = Field(
        ...,
        description="Summary of search parameters"
    )
    destinations: list[DestinationSuggestion] = Field(
        ...,
        description="Suggested destinations sorted by price"
    )
    total_found: int = Field(
        ...,
        description="Total destinations found before limiting"
    )


class SuggestionError(BaseModel):
    """Error response."""
    error: str
    detail: Optional[str] = None
