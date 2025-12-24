"""
Firebase authentication service.

Verifies Firebase ID tokens from the Flutter app.
In DEBUG mode, can work without Firebase credentials for testing.
"""

import os
from dataclasses import dataclass
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import settings


# Security scheme for Swagger UI
security = HTTPBearer()


@dataclass
class FirebaseUser:
    """Represents an authenticated Firebase user."""
    uid: str
    email: str | None
    name: str | None
    picture: str | None


# Try to initialize Firebase Admin SDK
_firebase_initialized = False
try:
    if os.path.exists(settings.GOOGLE_APPLICATION_CREDENTIALS):
        import firebase_admin
        from firebase_admin import auth, credentials
        
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.GOOGLE_APPLICATION_CREDENTIALS)
            firebase_admin.initialize_app(cred, {
                "projectId": settings.FIREBASE_PROJECT_ID,
            })
        _firebase_initialized = True
        print("✅ Firebase Admin SDK initialized")
    else:
        print(f"⚠️  Firebase credentials not found at {settings.GOOGLE_APPLICATION_CREDENTIALS}")
        print("   Running in DEBUG mode - auth will accept any token")
except Exception as e:
    print(f"⚠️  Firebase init failed: {e}")
    print("   Running in DEBUG mode - auth will accept any token")


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> FirebaseUser:
    """
    Dependency that verifies Firebase ID token and returns the user.
    
    In DEBUG mode without Firebase credentials, accepts any token.
    """
    token = credentials.credentials
    
    # If Firebase is initialized, verify the token properly
    if _firebase_initialized:
        try:
            from firebase_admin import auth
            decoded_token = auth.verify_id_token(token)
            
            return FirebaseUser(
                uid=decoded_token["uid"],
                email=decoded_token.get("email"),
                name=decoded_token.get("name"),
                picture=decoded_token.get("picture"),
            )
        
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Authentication failed: {str(e)}",
                headers={"WWW-Authenticate": "Bearer"},
            )
    
    # DEBUG mode: accept any token and return a test user
    if settings.DEBUG:
        print(f"⚠️  DEBUG MODE: Accepting token without verification")
        return FirebaseUser(
            uid="debug-user-123",
            email="debug@test.com",
            name="Debug User",
            picture=None,
        )
    
    # Production without Firebase = error
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Firebase not configured",
    )
