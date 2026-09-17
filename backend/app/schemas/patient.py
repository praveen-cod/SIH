"""
Patient Pydantic schemas for HealthCall AI.
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr


class PatientProfileResponse(BaseModel):
    id: int
    patient_id: str
    name: str
    age: int
    gender: str
    phone: str
    emergency_contact: Optional[str] = None
    email: EmailStr
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class PatientUpdateRequest(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    emergency_contact: Optional[str] = None
