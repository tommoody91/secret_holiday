"""
Photo URL endpoints.

Provides fresh presigned URLs for accessing photos stored in S3.
This keeps the S3 bucket private while allowing temporary access.
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List

from app.services.auth import get_current_user, FirebaseUser
from app.services.s3 import s3_service


router = APIRouter()


@router.get("/url")
async def get_photo_url(
    key: str = Query(..., description="The S3 key of the photo"),
    current_user: FirebaseUser = Depends(get_current_user),
):
    """
    Get a fresh presigned URL for a photo.
    
    The URL is valid for 24 hours. Clients should cache this URL
    and only request a new one when needed (e.g., on 403 error).
    
    Args:
        key: The S3 key (path) of the photo
        current_user: Authenticated user (injected by dependency)
    
    Returns:
        Fresh presigned URL with 24-hour expiry
    """
    if not key:
        raise HTTPException(status_code=400, detail="Key parameter is required")
    
    try:
        url = await s3_service.get_presigned_url(key)
        return {
            "key": key,
            "url": url,
            "expires_in_seconds": 86400,  # 24 hours
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate URL: {str(e)}")


@router.post("/urls")
async def get_photo_urls(
    keys: List[str],
    current_user: FirebaseUser = Depends(get_current_user),
):
    """
    Get fresh presigned URLs for multiple photos at once.
    
    This is more efficient than calling /url multiple times.
    
    Args:
        keys: List of S3 keys to generate URLs for
        current_user: Authenticated user (injected by dependency)
    
    Returns:
        Dict mapping keys to presigned URLs
    """
    if not keys:
        raise HTTPException(status_code=400, detail="Keys list cannot be empty")
    
    if len(keys) > 100:
        raise HTTPException(status_code=400, detail="Maximum 100 keys per request")
    
    try:
        urls = {}
        for key in keys:
            urls[key] = await s3_service.get_presigned_url(key)
        
        return {
            "urls": urls,
            "expires_in_seconds": 86400,  # 24 hours
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate URLs: {str(e)}")
