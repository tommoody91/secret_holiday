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
        Upload a file to S3 (private bucket).
        
        Args:
            file_content: The file bytes to upload
            key: The S3 key (path) for the file
            content_type: MIME type of the file
        
        Returns:
            The S3 key of the uploaded file (NOT a presigned URL)
        """
        self.client.put_object(
            Bucket=settings.AWS_S3_BUCKET,
            Key=key,
            Body=file_content,
            ContentType=content_type,
        )
        
        # Return the S3 key - clients should use get_presigned_url() to get access URLs
        return key
    
    async def list_files(self, prefix: str) -> list[dict]:
        """
        List files in S3 with a given prefix.
        
        Args:
            prefix: The S3 key prefix to filter by
        
        Returns:
            List of file metadata dicts with keys (NOT presigned URLs)
        """
        response = self.client.list_objects_v2(
            Bucket=settings.AWS_S3_BUCKET,
            Prefix=prefix,
        )
        
        files = []
        for obj in response.get("Contents", []):
            files.append({
                "key": obj["Key"],
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
    
    async def get_presigned_url(self, key: str, expires_in: int = 86400) -> str:
        """
        Generate a presigned URL for temporary access.
        
        Args:
            key: The S3 key of the file
            expires_in: URL expiration time in seconds (default 24 hours)
        
        Returns:
            Presigned URL string
        """
        return self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.AWS_S3_BUCKET, "Key": key},
            ExpiresIn=expires_in,
        )
    
    async def delete_all_files(self) -> int:
        """
        Delete ALL files from the S3 bucket.
        
        WARNING: This is destructive and cannot be undone!
        
        Returns:
            Number of files deleted
        """
        deleted_count = 0
        paginator = self.client.get_paginator('list_objects_v2')
        
        for page in paginator.paginate(Bucket=settings.AWS_S3_BUCKET):
            if 'Contents' not in page:
                continue
                
            objects = [{'Key': obj['Key']} for obj in page['Contents']]
            if objects:
                self.client.delete_objects(
                    Bucket=settings.AWS_S3_BUCKET,
                    Delete={'Objects': objects}
                )
                deleted_count += len(objects)
        
        return deleted_count


# Singleton instance
s3_service = S3Service()
