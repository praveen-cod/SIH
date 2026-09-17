"""
Pydantic models for HealthCall AI backend.
"""
from __future__ import annotations
from typing import Any, List, Optional
from pydantic import BaseModel, Field
from enum import Enum
from datetime import datetime
import uuid


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class UserRole(str, Enum):
    patient = "patient"
    doctor  = "doctor"
    admin   = "admin"


class MessageRole(str, Enum):
    ai      = "ai"
    patient = "patient"
    system  = "system"


class ConsultationStatus(str, Enum):
    active    = "active"
    completed = "completed"
    emergency = "emergency"
    abandoned = "abandoned"


# ---------------------------------------------------------------------------
# Patient / User
# ---------------------------------------------------------------------------

class PatientProfile(BaseModel):
    """Represents a registered (logged-in) patient."""
    patient_id:        str
    name:              str
    age:               int
    gender:            str
    phone:             str
    email:             str
    emergency_contact: Optional[str] = None


# ---------------------------------------------------------------------------
# Consultation Data (structured medical intake)
# ---------------------------------------------------------------------------

class ExtractedIntakeData(BaseModel):
    """Incrementally built during the consultation conversation."""
    # Personal (only populated for guests)
    name:              Optional[str] = None
    age:               Optional[int] = None
    gender:            Optional[str] = None
    phone:             Optional[str] = None
    email:             Optional[str] = None

    # Medical intake
    chief_complaint:   Optional[str] = None
    symptoms:          List[str]     = Field(default_factory=list)
    duration:          Optional[str] = None
    severity:          Optional[str] = None
    relevant_answers:  dict          = Field(default_factory=dict)

    # Meta
    preferred_language:    str  = "en"
    should_flag_emergency: bool = False
    intake_complete:       bool = False

    # Enhanced AI Clinical Summary fields
    clinical_summary:       Optional[str] = None
    recommended_specialist: Optional[str] = None
    key_observations:       List[str]     = Field(default_factory=list)
    preliminary_guidance:   Optional[str] = None
    triage_level:           Optional[str] = "Routine"


# ---------------------------------------------------------------------------
# Chat Message
# ---------------------------------------------------------------------------

class ChatMessage(BaseModel):
    id:        str          = Field(default_factory=lambda: str(uuid.uuid4()))
    role:      MessageRole
    content:   str
    timestamp: datetime     = Field(default_factory=datetime.utcnow)
    language:  Optional[str] = "en"


# ---------------------------------------------------------------------------
# Session
# ---------------------------------------------------------------------------

class ConsultationSession(BaseModel):
    session_id:    str                = Field(default_factory=lambda: str(uuid.uuid4()))
    patient_id:    Optional[str]      = None      # None → guest
    is_guest:      bool               = True
    patient:       Optional[PatientProfile] = None
    messages:      List[ChatMessage]  = Field(default_factory=list)
    intake_data:   ExtractedIntakeData = Field(default_factory=ExtractedIntakeData)
    status:        ConsultationStatus = ConsultationStatus.active
    created_at:    datetime           = Field(default_factory=datetime.utcnow)
    updated_at:    datetime           = Field(default_factory=datetime.utcnow)


# ---------------------------------------------------------------------------
# API Request / Response Models
# ---------------------------------------------------------------------------

class CreateSessionRequest(BaseModel):
    """Sent by Flutter when starting a consultation."""
    patient_id: Optional[str] = None    # None → guest
    auth_token: Optional[str] = None    # Simulated auth token


class MessageRequest(BaseModel):
    message:    str
    language:   Optional[str] = None    # Optional hint; Gemini will detect


class MessageResponse(BaseModel):
    session_id:            str
    response_text:         str
    language:              str
    extracted_data:        ExtractedIntakeData
    missing_fields:        List[str]
    should_flag_emergency: bool
    intake_complete:       bool
    status:                ConsultationStatus


class ConsultationSummary(BaseModel):
    session_id:    str
    patient_name:  str
    age:           Optional[int]
    gender:        Optional[str]
    chief_complaint: Optional[str]
    symptoms:      List[str]
    duration:      Optional[str]
    severity:      Optional[str]
    language:      str
    emergency:     bool
    clinical_summary:       Optional[str] = None
    recommended_specialist: Optional[str] = None
    key_observations:       List[str]     = Field(default_factory=list)
    preliminary_guidance:   Optional[str] = None
    triage_level:           Optional[str] = "Routine"
    completed_at:  datetime = Field(default_factory=datetime.utcnow)


# ---------------------------------------------------------------------------
# Auth Models (mock)
# ---------------------------------------------------------------------------

class LoginRequest(BaseModel):
    email:    str
    password: str
    role:     UserRole = UserRole.patient


class LoginResponse(BaseModel):
    success:    bool
    token:      Optional[str] = None
    patient_id: Optional[str] = None
    name:       Optional[str] = None
    role:       Optional[str] = None
    error:      Optional[str] = None


class RegisterRequest(BaseModel):
    name:              str
    email:             str
    password:          str
    phone:             str
    age:               int
    gender:            str
    emergency_contact: Optional[str] = None
