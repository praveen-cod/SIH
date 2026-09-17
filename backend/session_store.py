"""
In-memory session store for consultation sessions and simulated registered patient profiles.
"""
from typing import Dict, Optional
from datetime import datetime
from models import ConsultationSession, PatientProfile, ConsultationStatus, ExtractedIntakeData

# Mock registered patient database (keyed by patient_id or token)
# In real production, this would query Postgres or MongoDB
MOCK_PATIENTS: Dict[str, PatientProfile] = {
    "patient_001": PatientProfile(
        patient_id="patient_001",
        name="Praveen Kumar",
        age=22,
        gender="Male",
        phone="+91 9876543210",
        email="praveen@healthcall.ai",
        emergency_contact="+91 9876543211",
    ),
    "HC-P001": PatientProfile(
        patient_id="HC-P001",
        name="John Doe",
        age=34,
        gender="Male",
        phone="+1 555 0100",
        email="john.doe@email.com",
        emergency_contact="+1 555 0199",
    ),
}

# Key: session_id -> ConsultationSession
SESSION_STORE: Dict[str, ConsultationSession] = {}


def get_patient_by_id(patient_id: str) -> Optional[PatientProfile]:
    return MOCK_PATIENTS.get(patient_id)


def create_session(patient_id: Optional[str] = None) -> ConsultationSession:
    """
    Creates and stores a consultation session.
    If patient_id is provided, automatically loads patient profile and pre-populates intake_data.
    """
    patient: Optional[PatientProfile] = None
    is_guest = True
    intake = ExtractedIntakeData()

    if patient_id:
        patient = get_patient_by_id(patient_id)
        if patient:
            is_guest = False
            # Pre-populate known patient details so the AI never asks for them
            intake.name = patient.name
            intake.age = patient.age
            intake.gender = patient.gender
            intake.phone = patient.phone
            intake.email = patient.email

    session = ConsultationSession(
        patient_id=patient_id if not is_guest else None,
        is_guest=is_guest,
        patient=patient,
        intake_data=intake,
        status=ConsultationStatus.active,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    SESSION_STORE[session.session_id] = session
    return session


def get_session(session_id: str) -> Optional[ConsultationSession]:
    return SESSION_STORE.get(session_id)


def update_session(session: ConsultationSession) -> None:
    session.updated_at = datetime.utcnow()
    SESSION_STORE[session.session_id] = session


def delete_session(session_id: str) -> bool:
    if session_id in SESSION_STORE:
        del SESSION_STORE[session_id]
        return True
    return False
