"""
Photo upload endpoints.

Handles uploading photos to AWS S3 with Firebase authentication.
"""

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from typing import Annotated
import uuid

from app.services.auth import get_current_user, FirebaseUser
from app.services.s3 import s3_service


router = APIRouter()


@router.post("/photo")
async def upload_photo(
    file: Annotated[UploadFile, File(description="Photo to upload")],
    trip_id: str,
    current_user: FirebaseUser = Depends(get_current_user),
):
    """
    Upload a photo to S3.
    
    Requires Firebase authentication token in Authorization header.
    
    Args:
        file: The photo file to upload (JPEG, PNG, etc.)
        trip_id: The trip this photo belongs to
        current_user: Authenticated user (injected by dependency)
    
    Returns:
        Photo metadata including S3 URL
    """
    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "image/webp", "image/heic"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"File type {file.content_type} not allowed. Use: {allowed_types}"
        )
    
    # Generate unique filename
    extension = file.filename.split(".")[-1] if file.filename else "jpg"
    photo_id = str(uuid.uuid4())
    s3_key = f"trips/{trip_id}/photos/{photo_id}.{extension}"
    
    # Upload to S3
    try:
        file_content = await file.read()
        s3_key = await s3_service.upload_file(
            file_content=file_content,
            key=s3_key,
            content_type=file.content_type,
        )
        # Generate initial presigned URL for immediate use
        url = await s3_service.get_presigned_url(s3_key)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")
    
    return {
        "photo_id": photo_id,
        "trip_id": trip_id,
        "s3_key": s3_key,  # Store this in DB - it never expires
        "url": url,        # Presigned URL - valid for 24 hours
        "filename": file.filename,
        "uploaded_by": current_user.uid,
    }


@router.get("/photos/{trip_id}")
async def list_photos(
    trip_id: str,
    current_user: FirebaseUser = Depends(get_current_user),
):
    """
    List all photos for a trip.
    
    Args:
        trip_id: The trip to list photos for
        current_user: Authenticated user (injected by dependency)
    
    Returns:
        List of photo URLs
    """
    prefix = f"trips/{trip_id}/photos/"
    
    try:
        photos = await s3_service.list_files(prefix=prefix)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list photos: {str(e)}")
    
    return {"trip_id": trip_id, "photos": photos}


@router.delete("/photo/{photo_id}")
async def delete_photo(
    photo_id: str,
    trip_id: str,
    current_user: FirebaseUser = Depends(get_current_user),
):
    """
    Delete a photo from S3.
    
    Args:
        photo_id: The photo ID to delete
        trip_id: The trip the photo belongs to
        current_user: Authenticated user (injected by dependency)
    
    Returns:
        Deletion confirmation
    """
    # We'd need to check that the user owns this photo or is trip admin
    # For now, just delete it
    prefix = f"trips/{trip_id}/photos/{photo_id}"
    
    try:
        await s3_service.delete_file(prefix)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Delete failed: {str(e)}")
    
    return {"deleted": True, "photo_id": photo_id}
