"""
Consultation Pydantic schemas for HealthCall AI.
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field


class StartConsultationRequest(BaseModel):
    patient_id: Optional[str] = None
    auth_token: Optional[str] = None
    language: Optional[str] = "en"


class SendMessageRequest(BaseModel):
    message: str
    language: Optional[str] = None


class ExtractedIntakeData(BaseModel):
    chief_complaint: Optional[str] = None
    symptoms: List[str] = Field(default_factory=list)
    duration: Optional[str] = None
    severity: Optional[str] = None
    preferred_language: str = "en"
    should_flag_emergency: bool = False
    emergency_reason: Optional[str] = None
    intake_complete: bool = False
    clinical_summary: Optional[str] = None
    recommended_specialist: Optional[str] = None
    key_observations: List[str] = Field(default_factory=list)
    preliminary_guidance: Optional[str] = None
    triage_level: Optional[str] = "Routine"


class ConsultationSummaryResponse(BaseModel):
    consultation_id: str
    patient_id: Optional[str] = None
    session_id: str
    patient_name: Optional[str] = "Patient"
    age: Optional[int] = None
    gender: Optional[str] = None
    chief_complaint: Optional[str] = None
    symptoms: List[str] = Field(default_factory=list)
    duration: Optional[str] = None
    severity: Optional[str] = None
    preferred_language: str = "en"
    emergency_flag: bool = False
    emergency_reason: Optional[str] = None
    intake_complete: bool = False
    clinical_summary: Optional[str] = None
    recommended_specialist: Optional[str] = None
    key_observations: List[str] = Field(default_factory=list)
    preliminary_guidance: Optional[str] = None
    triage_level: Optional[str] = "Routine"
    created_at: datetime

    class Config:
        from_attributes = True


class ConsultationSummaryUpdateRequest(BaseModel):
    chief_complaint: Optional[str] = None
    symptoms: Optional[List[str]] = None
    duration: Optional[str] = None
    severity: Optional[str] = None
    clinical_summary: Optional[str] = None
    recommended_specialist: Optional[str] = None
    notes: Optional[str] = None
