"""
Doctor Availability schemas for HealthCall AI.
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field


class AvailabilityCreateRequest(BaseModel):
    doctor_id: str
    date: str = Field(..., description="e.g. 2026-08-30 or 30 Aug 2026")
    start_time: str = Field(..., description="e.g. 10:30 AM")
    end_time: str = Field(..., description="e.g. 11:00 AM")


class AvailabilityUpdateRequest(BaseModel):
    date: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    status: Optional[str] = None  # AVAILABLE, BLOCKED, INACTIVE


class AvailabilityResponse(BaseModel):
    id: int
    doctor_id: str
    date: str
    start_time: str
    end_time: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
