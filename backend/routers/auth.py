"""
Authentication routes for HealthCall AI (supports login, registration, profile retrieval).
"""
from fastapi import APIRouter, HTTPException, status
from models import LoginRequest, LoginResponse, RegisterRequest, PatientProfile, UserRole
from session_store import MOCK_PATIENTS
import uuid

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/login", response_model=LoginResponse)
async def login(req: LoginRequest):
    # Match mock users
    for p_id, patient in MOCK_PATIENTS.items():
        if patient.email.lower() == req.email.lower():
            return LoginResponse(
                success=True,
                token=f"token_{p_id}",
                patient_id=p_id,
                name=patient.name,
                role=req.role.value,
            )

    # General default fallback for demo accounts
    return LoginResponse(
        success=True,
        token="token_patient_001",
        patient_id="patient_001",
        name="Praveen Kumar",
        role=req.role.value,
    )


@router.post("/register", response_model=LoginResponse)
async def register(req: RegisterRequest):
    new_id = f"HC-{uuid.uuid4().hex[:6].upper()}"
    new_profile = PatientProfile(
        patient_id=new_id,
        name=req.name,
        age=req.age,
        gender=req.gender,
        phone=req.phone,
        email=req.email,
        emergency_contact=req.emergency_contact,
    )
    MOCK_PATIENTS[new_id] = new_profile

    return LoginResponse(
        success=True,
        token=f"token_{new_id}",
        patient_id=new_id,
        name=req.name,
        role=UserRole.patient.value,
    )
