"""
Staff Pydantic schemas for HealthCall AI.
Staff are managed strictly by Admins.
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class StaffCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    phone: str = Field(..., min_length=7, max_length=20)
    role: str = Field(..., min_length=2, max_length=50)
    department: str = Field(..., min_length=2, max_length=100)
    status: Optional[str] = "ACTIVE"


class StaffUpdateRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = None
    department: Optional[str] = None
    status: Optional[str] = None


class StaffResponse(BaseModel):
    id: int
    staff_id: str
    name: str
    email: str
    phone: str
    role: str
    department: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
