"""
Secret Holiday Backend - Main Application Entry Point

Run with:
    uvicorn app.main:app --reload
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import upload, admin, photos, suggestions


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan handler.
    
    Runs startup code before the app starts serving requests,
    and cleanup code when the app shuts down.
    """
    # Startup
    print(f"🚀 Starting Secret Holiday Backend")
    print(f"   Debug mode: {settings.DEBUG}")
    print(f"   S3 Bucket: {settings.AWS_S3_BUCKET}")
    yield
    # Shutdown
    print("👋 Shutting down...")


app = FastAPI(
    title="Secret Holiday API",
    description="Backend API for the Secret Holiday app - photo uploads and more",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware - allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(upload.router, prefix="/upload", tags=["Upload"])
app.include_router(photos.router, prefix="/photos", tags=["Photos"])
app.include_router(admin.router, prefix="/admin", tags=["Admin"])
app.include_router(suggestions.router, prefix="/v1/destinations", tags=["Suggestions"])


@app.get("/")
async def root():
    """Root endpoint - basic health check."""
    return {"status": "ok", "message": "Secret Holiday API"}


@app.get("/health")
async def health_check():
    """Detailed health check endpoint."""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "debug": settings.DEBUG,
        "s3_bucket": settings.AWS_S3_BUCKET,
        "firebase_project": settings.FIREBASE_PROJECT_ID,
    }
