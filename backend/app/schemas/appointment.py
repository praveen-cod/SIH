"""
Appointment schemas for HealthCall AI.
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field
from .availability import AvailabilityResponse


class AppointmentCreateRequest(BaseModel):
    doctor_id: str
    consultation_id: Optional[str] = None
    availability_id: Optional[int] = None
    appointment_date: str
    start_time: str
    end_time: Optional[str] = None
    consultation_type: Optional[str] = "Video"
    reason: str
    patient_notes: Optional[str] = None


class AppointmentActionRequest(BaseModel):
    doctor_notes: Optional[str] = None
    rejection_reason: Optional[str] = None


class AppointmentResponse(BaseModel):
    id: int
    appointment_id: str
    patient_id: str
    patient_name: Optional[str] = None
    doctor_id: str
    doctor_name: Optional[str] = None
    doctor_specialization: Optional[str] = None
    consultation_id: Optional[str] = None
    availability_id: Optional[int] = None
    appointment_date: str
    start_time: str
    end_time: str
    consultation_type: str
    reason: str
    status: str  # REQUESTED, APPROVED, REJECTED, CANCELLED, COMPLETED
    patient_notes: Optional[str] = None
    doctor_notes: Optional[str] = None
    rejection_reason: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class RecommendedDoctorResponse(BaseModel):
    doctor_id: str
    name: str
    specialization: str
    qualification: str
    experience: int
    department: str
    status: str
    available_slots: List[AvailabilityResponse] = Field(default_factory=list)
    recommendation_rationale: Optional[str] = None
