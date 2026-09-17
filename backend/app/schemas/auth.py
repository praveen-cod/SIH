"""
Authentication schemas for HealthCall AI.
"""
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: str
    password: str
    role: Optional[str] = "patient"


class LoginResponse(BaseModel):
    success: bool
    token: Optional[str] = None
    user_id: Optional[str] = None
    name: Optional[str] = None
    role: Optional[str] = None
    email: Optional[str] = None
    error: Optional[str] = None


class PatientRegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    age: int = Field(..., ge=1, le=120)
    gender: str = Field(..., min_length=1, max_length=20)
    phone: str = Field(..., min_length=7, max_length=20)
    emergency_contact: Optional[str] = None
    email: EmailStr
    password: str = Field(..., min_length=6)
    confirm_password: Optional[str] = None


class TokenPayload(BaseModel):
    user_id: str
    role: str
    email: Optional[str] = None
    exp: Optional[int] = None
