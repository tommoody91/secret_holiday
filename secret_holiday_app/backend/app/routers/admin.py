"""
Admin endpoints for maintenance operations.

WARNING: These endpoints are destructive and should only be used in development!
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

from app.services.s3 import s3_service
from app.services.firebase import firebase_admin_service
from app.config import settings


router = APIRouter()


class CleanupResponse(BaseModel):
    """Response model for cleanup operations."""
    success: bool
    message: str
    details: dict


class CleanupStats(BaseModel):
    """Statistics about what was deleted."""
    groups_deleted: int = 0
    trips_deleted: int = 0
    memories_deleted: int = 0
    activities_deleted: int = 0
    users_deleted: int = 0
    s3_files_deleted: int = 0
    errors: list[str] = []


@router.post("/cleanup-all", response_model=CleanupResponse)
async def cleanup_all_data(confirm: str = "", delete_users: bool = False):
    """
    Delete ALL data from Firestore and S3.
    
    WARNING: This is destructive and cannot be undone!
    
    To confirm, pass `confirm=DELETE_EVERYTHING` as a query parameter.
    
    Args:
        confirm: Must be "DELETE_EVERYTHING" to proceed
        delete_users: If True, also deletes all user documents (default: False)
    
    This will:
    1. Delete all groups (and their trips, memories, activities)
    2. Delete all user documents (if delete_users=True)
    3. Delete all S3 files in the bucket
    """
    if confirm != "DELETE_EVERYTHING":
        raise HTTPException(
            status_code=400,
            detail="Must confirm with ?confirm=DELETE_EVERYTHING"
        )
    
    if not settings.DEBUG:
        raise HTTPException(
            status_code=403,
            detail="Cleanup is only allowed in DEBUG mode"
        )
    
    stats = CleanupStats()
    
    try:
        # Initialize Firebase Admin if not already done
        db = firebase_admin_service.get_firestore()
        
        # Step 1: Get all groups
        print("📋 Fetching all groups...")
        groups_ref = db.collection('groups')
        groups = list(groups_ref.stream())
        print(f"   Found {len(groups)} groups")
        
        # Step 2: For each group, delete subcollections first
        for group_doc in groups:
            group_id = group_doc.id
            print(f"\n🗑️  Processing group: {group_id}")
            
            # Delete trips subcollection (and their nested subcollections)
            trips_ref = groups_ref.document(group_id).collection('trips')
            trips = list(trips_ref.stream())
            print(f"   Found {len(trips)} trips")
            
            for trip_doc in trips:
                trip_id = trip_doc.id
                
                # Delete memories subcollection
                memories_ref = trips_ref.document(trip_id).collection('memories')
                memories = list(memories_ref.stream())
                for memory in memories:
                    memory.reference.delete()
                    stats.memories_deleted += 1
                
                # Delete activities subcollection
                activities_ref = trips_ref.document(trip_id).collection('activities')
                activities = list(activities_ref.stream())
                for activity in activities:
                    activity.reference.delete()
                    stats.activities_deleted += 1
                
                # Delete the trip document
                trip_doc.reference.delete()
                stats.trips_deleted += 1
                print(f"   ✓ Deleted trip {trip_id} with {len(memories)} memories, {len(activities)} activities")
            
            # Delete the group document
            group_doc.reference.delete()
            stats.groups_deleted += 1
            print(f"   ✓ Deleted group {group_id}")
        
        # Step 3: Delete user documents (if requested)
        print("\n👤 Processing user documents...")
        users_ref = db.collection('users')
        users = list(users_ref.stream())
        
        if delete_users:
            for user_doc in users:
                user_doc.reference.delete()
                stats.users_deleted += 1
                print(f"   ✓ Deleted user {user_doc.id}")
        else:
            print(f"   Skipping {len(users)} users (use delete_users=true to remove)")
        
        # Step 4: Delete all S3 files
        print("\n🪣 Cleaning S3 bucket...")
        try:
            s3_stats = await cleanup_s3_bucket()
            stats.s3_files_deleted = s3_stats
            print(f"   ✓ Deleted {stats.s3_files_deleted} files from S3")
        except Exception as e:
            error_msg = f"S3 cleanup error: {str(e)}"
            stats.errors.append(error_msg)
            print(f"   ❌ {error_msg}")
        
        print("\n✅ Cleanup complete!")
        
        return CleanupResponse(
            success=True,
            message="All data has been deleted",
            details={
                "groups_deleted": stats.groups_deleted,
                "trips_deleted": stats.trips_deleted,
                "memories_deleted": stats.memories_deleted,
                "activities_deleted": stats.activities_deleted,
                "users_deleted": stats.users_deleted,
                "s3_files_deleted": stats.s3_files_deleted,
                "errors": stats.errors,
            }
        )
        
    except Exception as e:
        print(f"❌ Cleanup failed: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Cleanup failed: {str(e)}"
        )


async def cleanup_s3_bucket() -> int:
    """
    Delete all files in the S3 bucket.
    
    Returns the number of files deleted.
    """
    deleted_count = 0
    
    # List all objects in the bucket
    response = s3_service.client.list_objects_v2(
        Bucket=settings.AWS_S3_BUCKET,
    )
    
    # Delete each object
    while True:
        contents = response.get('Contents', [])
        
        if not contents:
            break
        
        for obj in contents:
            s3_service.client.delete_object(
                Bucket=settings.AWS_S3_BUCKET,
                Key=obj['Key'],
            )
            deleted_count += 1
            print(f"      Deleted: {obj['Key']}")
        
        # Check if there are more objects (pagination)
        if response.get('IsTruncated'):
            response = s3_service.client.list_objects_v2(
                Bucket=settings.AWS_S3_BUCKET,
                ContinuationToken=response['NextContinuationToken'],
            )
        else:
            break
    
    return deleted_count


@router.get("/stats")
async def get_data_stats():
    """
    Get statistics about current data in Firestore and S3.
    """
    try:
        db = firebase_admin_service.get_firestore()
        
        # Count groups
        groups = list(db.collection('groups').stream())
        group_count = len(groups)
        
        # Count trips and nested data
        trip_count = 0
        memory_count = 0
        activity_count = 0
        
        for group_doc in groups:
            trips = list(db.collection('groups').document(group_doc.id).collection('trips').stream())
            trip_count += len(trips)
            
            for trip_doc in trips:
                memories = list(db.collection('groups').document(group_doc.id)
                              .collection('trips').document(trip_doc.id)
                              .collection('memories').stream())
                memory_count += len(memories)
                
                activities = list(db.collection('groups').document(group_doc.id)
                                 .collection('trips').document(trip_doc.id)
                                 .collection('activities').stream())
                activity_count += len(activities)
        
        # Count users with groups
        users = list(db.collection('users').stream())
        users_with_groups = sum(
            1 for u in users 
            if u.to_dict() and u.to_dict().get('groupIds')
        )
        
        # Count S3 files
        s3_count = 0
        try:
            response = s3_service.client.list_objects_v2(
                Bucket=settings.AWS_S3_BUCKET,
            )
            s3_count = response.get('KeyCount', 0)
        except Exception:
            s3_count = -1  # Error getting count
        
        return {
            "firestore": {
                "groups": group_count,
                "trips": trip_count,
                "memories": memory_count,
                "activities": activity_count,
                "users_total": len(users),
                "users_with_groups": users_with_groups,
            },
            "s3": {
                "files": s3_count,
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get stats: {str(e)}"
        )
