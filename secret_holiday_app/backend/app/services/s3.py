"""
AWS S3 service for photo storage.

Handles uploading, listing, and deleting files from S3.
"""

import boto3
from botocore.config import Config

from app.config import settings


class S3Service:
    """
    AWS S3 service wrapper.
    
    Provides async-compatible methods for S3 operations.
    """
    
    def __init__(self):
        self._client = None
    
    @property
    def client(self):
        """Lazy-load the S3 client."""
        if self._client is None:
            self._client = boto3.client(
                "s3",
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                region_name=settings.AWS_REGION,
                config=Config(signature_version="s3v4"),
            )
        return self._client
    
    async def upload_file(
        self,
        file_content: bytes,
        key: str,
        content_type: str = "application/octet-stream",
    ) -> str:
        """
        Upload a file to S3.
        
        Args:
            file_content: The file bytes to upload
            key: The S3 key (path) for the file
            content_type: MIME type of the file
        
        Returns:
            The public URL of the uploaded file
        """
        self.client.put_object(
            Bucket=settings.AWS_S3_BUCKET,
            Key=key,
            Body=file_content,
            ContentType=content_type,
        )
        
        # Return a presigned URL (works even if bucket isn't public)
        return self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.AWS_S3_BUCKET, "Key": key},
            ExpiresIn=3600,  # 1 hour
        )
    
    async def list_files(self, prefix: str) -> list[dict]:
        """
        List files in S3 with a given prefix.
        
        Args:
            prefix: The S3 key prefix to filter by
        
        Returns:
            List of file metadata dicts
        """
        response = self.client.list_objects_v2(
            Bucket=settings.AWS_S3_BUCKET,
            Prefix=prefix,
        )
        
        files = []
        for obj in response.get("Contents", []):
            # Use presigned URLs so images can be viewed even if bucket isn't public
            presigned_url = self.client.generate_presigned_url(
                "get_object",
                Params={"Bucket": settings.AWS_S3_BUCKET, "Key": obj["Key"]},
                ExpiresIn=3600,  # 1 hour
            )
            files.append({
                "key": obj["Key"],
                "url": presigned_url,
                "size": obj["Size"],
                "last_modified": obj["LastModified"].isoformat(),
            })
        
        return files
    
    async def delete_file(self, key: str) -> None:
        """
        Delete a file from S3.
        
        Args:
            key: The S3 key of the file to delete (or prefix for wildcard)
        """
        # List all files matching the prefix
        response = self.client.list_objects_v2(
            Bucket=settings.AWS_S3_BUCKET,
            Prefix=key,
        )
        
        # Delete each matching file
        for obj in response.get("Contents", []):
            self.client.delete_object(
                Bucket=settings.AWS_S3_BUCKET,
                Key=obj["Key"],
            )
    
    async def get_presigned_url(self, key: str, expires_in: int = 3600) -> str:
        """
        Generate a presigned URL for temporary access.
        
        Args:
            key: The S3 key of the file
            expires_in: URL expiration time in seconds (default 1 hour)
        
        Returns:
            Presigned URL string
        """
        return self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.AWS_S3_BUCKET, "Key": key},
            ExpiresIn=expires_in,
        )


# Singleton instance
s3_service = S3Service()
