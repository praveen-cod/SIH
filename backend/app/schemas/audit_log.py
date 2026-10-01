from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class AuditLogResponse(BaseModel):
    id: int
    user_id: Optional[str] = None
    user_role: str
    action: str
    details: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
