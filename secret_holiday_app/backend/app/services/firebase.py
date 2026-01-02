"""
Firebase Admin service for server-side operations.

Provides access to Firestore for admin operations like cleanup.
"""

import os
from typing import Optional

from app.config import settings


class FirebaseAdminService:
    """
    Firebase Admin SDK wrapper for server-side operations.
    
    Provides lazy-loaded access to Firestore client.
    """
    
    def __init__(self):
        self._app = None
        self._db = None
        self._initialized = False
    
    def _ensure_initialized(self):
        """Initialize Firebase Admin if not already done."""
        if self._initialized:
            return
        
        import firebase_admin
        from firebase_admin import credentials
        
        # Check if already initialized
        if firebase_admin._apps:
            self._app = firebase_admin.get_app()
            self._initialized = True
            return
        
        # Initialize with credentials
        cred_path = settings.GOOGLE_APPLICATION_CREDENTIALS
        
        if not os.path.exists(cred_path):
            raise RuntimeError(
                f"Firebase credentials not found at {cred_path}. "
                "Please download the service account key from Firebase Console."
            )
        
        cred = credentials.Certificate(cred_path)
        self._app = firebase_admin.initialize_app(cred, {
            "projectId": settings.FIREBASE_PROJECT_ID,
        })
        self._initialized = True
        print("✅ Firebase Admin SDK initialized for admin operations")
    
    def get_firestore(self):
        """
        Get the Firestore client.
        
        Returns:
            google.cloud.firestore.Client: Firestore client instance
        """
        self._ensure_initialized()
        
        if self._db is None:
            from firebase_admin import firestore
            self._db = firestore.client()
        
        return self._db
    
    def get_auth(self):
        """
        Get the Firebase Auth client.
        
        Returns:
            firebase_admin.auth module
        """
        self._ensure_initialized()
        from firebase_admin import auth
        return auth


# Singleton instance
firebase_admin_service = FirebaseAdminService()
