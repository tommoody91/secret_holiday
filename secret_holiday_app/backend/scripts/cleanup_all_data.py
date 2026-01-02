#!/usr/bin/env python3
"""
Cleanup Script for Secret Holiday

Deletes ALL data from Firebase Firestore and AWS S3.
WARNING: This is destructive and cannot be undone!

Usage:
    python scripts/cleanup_all_data.py              # Keep user accounts
    python scripts/cleanup_all_data.py --all       # Delete everything including users

Requirements:
    - Backend server must be running (uvicorn app.main:app --reload)
    - Server must be in DEBUG mode
"""

import requests
import sys

BACKEND_URL = "http://localhost:8000"
CLEANUP_ENDPOINT = f"{BACKEND_URL}/admin/cleanup-all"


def main():
    # Check for --all flag
    delete_users = "--all" in sys.argv
    
    print("=" * 60)
    print("🚨 SECRET HOLIDAY DATA CLEANUP SCRIPT 🚨")
    print("=" * 60)
    print()
    print("⚠️  WARNING: This will DELETE ALL DATA including:")
    print("    - All groups")
    print("    - All trips")
    print("    - All memories")
    print("    - All activities")
    print("    - All photos in S3")
    if delete_users:
        print("    - All user documents (--all flag)")
    else:
        print("    - (User accounts will remain - use --all to delete)")
    print()
    print("❗ This action CANNOT be undone!")
    print()
    
    confirmation = input("Type 'DELETE EVERYTHING' to confirm: ")
    
    if confirmation != "DELETE EVERYTHING":
        print("\n❌ Cleanup cancelled. Your data is safe.")
        sys.exit(0)
    
    print("\n🔄 Calling cleanup endpoint...")
    
    try:
        response = requests.post(
            CLEANUP_ENDPOINT,
            params={
                "confirm": "DELETE_EVERYTHING",
                "delete_users": str(delete_users).lower(),
            },
            timeout=300,
        )
        
        if response.status_code == 200:
            result = response.json()
            print("\n✅ Cleanup completed successfully!")
            print()
            print("📊 Cleanup Statistics:")
            details = result.get("details", {})
            print(f"   Groups deleted:     {details.get('groups_deleted', 0)}")
            print(f"   Trips deleted:      {details.get('trips_deleted', 0)}")
            print(f"   Memories deleted:   {details.get('memories_deleted', 0)}")
            print(f"   Activities deleted: {details.get('activities_deleted', 0)}")
            print(f"   Users deleted:      {details.get('users_deleted', 0)}")
            print(f"   S3 files deleted:   {details.get('s3_files_deleted', 0)}")
            
            errors = details.get("errors", [])
            if errors:
                print()
                print("⚠️  Errors encountered:")
                for error in errors:
                    print(f"   - {error}")
        
        elif response.status_code == 400:
            print(f"\n❌ Bad request: {response.json().get('detail', 'Unknown error')}")
            sys.exit(1)
        
        elif response.status_code == 403:
            print("\n❌ Server is not in DEBUG mode. Cleanup is only allowed in development.")
            sys.exit(1)
        
        elif response.status_code == 500:
            print(f"\n❌ Server error: {response.json().get('detail', 'Unknown error')}")
            sys.exit(1)
        
        else:
            print(f"\n❌ Unexpected response: {response.status_code}")
            print(response.text)
            sys.exit(1)
            
    except requests.exceptions.ConnectionError:
        print("\n❌ Could not connect to backend server.")
        print("   Make sure the server is running:")
        print("   cd backend && uvicorn app.main:app --reload")
        sys.exit(1)
        
    except requests.exceptions.Timeout:
        print("\n❌ Request timed out. Check server logs.")
        sys.exit(1)
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
