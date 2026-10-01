import os
import logging
import cloudinary
import cloudinary.uploader
from typing import Optional

logger = logging.getLogger(__name__)

class CloudinaryService:
    def __init__(self):
        cloudinary.config(
            cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME", "mock_cloud"),
            api_key=os.getenv("CLOUDINARY_API_KEY", "mock_key"),
            api_secret=os.getenv("CLOUDINARY_API_SECRET", "mock_secret")
        )
        self.configured = os.getenv("CLOUDINARY_CLOUD_NAME") is not None

    def upload_base64_image(self, base64_data: str) -> Optional[str]:
        if not self.configured:
            logger.warning("Mock Cloudinary Upload: returning mock URL.")
            return "https://res.cloudinary.com/mock_cloud/image/upload/v1/mock_image.jpg"
            
        try:
            # Cloudinary accepts base64 data URIs (e.g., "data:image/jpeg;base64,...")
            if not base64_data.startswith("data:image"):
                base64_data = f"data:image/jpeg;base64,{base64_data}"
                
            response = cloudinary.uploader.upload(base64_data)
            return response.get("secure_url")
        except Exception as e:
            logger.error(f"Cloudinary upload failed: {e}")
            return None

cloudinary_service = CloudinaryService()
