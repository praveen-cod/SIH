"""
Doctor Pydantic schemas for HealthCall AI.
Doctors are created and updated strictly by Admins.
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class DoctorCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    phone: str = Field(..., min_length=7, max_length=20)
    password: str = Field(..., min_length=6)
    specialization: str = Field(..., min_length=2, max_length=100)
    qualification: str = Field(..., min_length=2, max_length=100)
    experience: int = Field(default=0, ge=0)
    license_number: str = Field(..., min_length=3, max_length=100)
    department: str = Field(..., min_length=2, max_length=100)
    status: Optional[str] = "ACTIVE"


class DoctorUpdateRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    specialization: Optional[str] = None
    qualification: Optional[str] = None
    experience: Optional[int] = None
    department: Optional[str] = None
    status: Optional[str] = None


class DoctorResponse(BaseModel):
    id: int
    doctor_id: str
    name: str
    email: str
    phone: str
    specialization: str
    qualification: str
    experience: int
    license_number: str
    department: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
