"""
Patient profile router for HealthCall AI.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database.database import get_db
from ..models.patient import Patient
from ..schemas.patient import PatientProfileResponse, PatientUpdateRequest
from ..dependencies.auth import get_current_user, require_role

router = APIRouter(prefix="/api/patients", tags=["Patient Profile"])


@router.get("/me", response_model=PatientProfileResponse)
def get_my_profile(
    current_user: dict = Depends(require_role(["PATIENT"])),
    db: Session = Depends(get_db),
):
    """Retrieves the authenticated patient's profile from SQLite."""
    patient_id = current_user["user_id"]
    patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient profile not found.",
        )
    return patient


@router.put("/me", response_model=PatientProfileResponse)
def update_my_profile(
    req: PatientUpdateRequest,
    current_user: dict = Depends(require_role(["PATIENT"])),
    db: Session = Depends(get_db),
):
    """Updates the authenticated patient's profile in SQLite."""
    patient_id = current_user["user_id"]
    patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient profile not found.",
        )

    if req.name is not None:
        patient.name = req.name.strip()
    if req.age is not None:
        patient.age = req.age
    if req.gender is not None:
        patient.gender = req.gender.strip()
    if req.phone is not None:
        patient.phone = req.phone.strip()
    if req.emergency_contact is not None:
        patient.emergency_contact = req.emergency_contact.strip()

    db.commit()
    db.refresh(patient)
    return patient
