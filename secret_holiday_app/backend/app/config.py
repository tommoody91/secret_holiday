"""
Application configuration loaded from environment variables.

Usage:
    from app.config import settings
    print(settings.AWS_S3_BUCKET)
"""

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings loaded from .env file.
    
    All fields with defaults are optional.
    Fields without defaults are required and will raise an error if missing.
    """
    
    # Server
    DEBUG: bool = True
    PORT: int = 8000
    SECRET_KEY: str
    
    # Firebase
    FIREBASE_PROJECT_ID: str
    GOOGLE_APPLICATION_CREDENTIALS: str = "./credentials/firebase-service-account.json"
    
    # AWS S3
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    AWS_REGION: str = "eu-west-2"
    AWS_S3_BUCKET: str
    
    # CORS
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8080"
    
    # Amadeus API (for flight/hotel searches)
    AMADEUS_API_KEY: str = ""
    AMADEUS_API_SECRET: str = ""
    AMADEUS_BASE_URL: str = "https://test.api.amadeus.com"  # Use production URL when ready
    
    @property
    def allowed_origins_list(self) -> list[str]:
        """Parse comma-separated origins into a list."""
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )


@lru_cache
def get_settings() -> Settings:
    """
    Get cached settings instance.
    
    Uses lru_cache to avoid reading .env file on every request.
    """
    return Settings()


# Convenience export
settings = get_settings()
