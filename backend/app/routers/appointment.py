"""
Appointment router for HealthCall AI.
Provides Doctor Recommendation, Availability lookup, and Patient Appointment booking requests.
"""
import json
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from ..database.database import get_db
from ..models.consultation import Consultation
from ..schemas.appointment import (
    AppointmentCreateRequest,
    AppointmentResponse,
    RecommendedDoctorResponse,
)
from ..schemas.availability import AvailabilityResponse
from ..services.doctor_matching_service import DoctorMatchingService
from ..services.availability_service import AvailabilityService
from ..services.appointment_service import AppointmentService
from ..dependencies.auth import get_current_user, require_role

router = APIRouter(prefix="/api", tags=["Appointments"])


@router.get("/appointments/recommended-doctors", response_model=List[RecommendedDoctorResponse])
def get_recommended_doctors(
    consultation_id: Optional[str] = Query(None, description="ID of completed AI consultation"),
    chief_complaint: Optional[str] = Query(None),
    specialization: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """
    Returns recommended active doctors with available slots based on AI consultation symptoms.
    Includes medical disclaimer that this is a specialty matching aid, not a diagnosis.
    """
    symptoms = []
    if consultation_id:
        consultation = (
            db.query(Consultation)
            .filter(
                (Consultation.consultation_id == consultation_id)
                | (Consultation.session_id == consultation_id)
            )
            .first()
        )
        if consultation:
            if not chief_complaint and consultation.chief_complaint:
                chief_complaint = consultation.chief_complaint
            if consultation.symptoms:
                try:
                    symptoms = json.loads(consultation.symptoms)
                except Exception:
                    symptoms = [consultation.symptoms]

    return DoctorMatchingService.get_recommended_doctors(
        db=db,
        chief_complaint=chief_complaint,
        symptoms=symptoms,
        preferred_specialization=specialization,
    )


@router.get("/doctors/{doctor_id}/availability", response_model=List[AvailabilityResponse])
def get_doctor_availability(
    doctor_id: str,
    only_available: bool = Query(True),
    db: Session = Depends(get_db),
):
    """
    Fetches real-time availability slots for a doctor from SQLite.
    """
    slots = AvailabilityService.get_doctor_slots(db, doctor_id, only_available=only_available)
    return [
        AvailabilityResponse(
            id=s.id,
            doctor_id=s.doctor_id,
            date=s.date,
            start_time=s.start_time,
            end_time=s.end_time,
            status=s.status,
            created_at=s.created_at,
        )
        for s in slots
    ]


@router.post("/appointments/request", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
def request_appointment(
    req: AppointmentCreateRequest,
    current_user: dict = Depends(require_role(["PATIENT"])),
    db: Session = Depends(get_db),
):
    """
    Patient submits an appointment request.
    Status is created as REQUESTED and awaits Doctor review.
    """
    patient_id = current_user["user_id"]
    appt = AppointmentService.request_appointment(
        db=db,
        patient_id=patient_id,
        req=req,
    )

    from ..services.audit_service import log_audit_action
    doctor_name = appt.doctor.name if appt.doctor else req.doctor_id
    patient_name = appt.patient.name if appt.patient else "Patient"
    
    # Log for Patient
    log_audit_action(
        db=db,
        user_id=patient_id,
        user_role="Patient",
        action=f"Booked an appointment with Dr. {doctor_name}"
    )
    
    # Log for Doctor
    log_audit_action(
        db=db,
        user_id=appt.doctor_id,
        user_role="Doctor",
        action=f"New appointment booked by Patient {patient_name}"
    )

    doctor_name = appt.doctor.name if appt.doctor else None
    doctor_spec = appt.doctor.specialization if appt.doctor else None
    patient_name = appt.patient.name if appt.patient else None

    return AppointmentResponse(
        id=appt.id,
        appointment_id=appt.appointment_id,
        patient_id=appt.patient_id,
        patient_name=patient_name,
        doctor_id=appt.doctor_id,
        doctor_name=doctor_name,
        doctor_specialization=doctor_spec,
        consultation_id=appt.consultation_id,
        availability_id=appt.availability_id,
        appointment_date=appt.appointment_date,
        start_time=appt.start_time,
        end_time=appt.end_time,
        consultation_type=appt.consultation_type,
        reason=appt.reason,
        status=appt.status,
        patient_notes=appt.patient_notes,
        doctor_notes=appt.doctor_notes,
        rejection_reason=appt.rejection_reason,
        created_at=appt.created_at,
    )


@router.get("/patient/appointments", response_model=List[AppointmentResponse])
def get_my_appointments(
    status: Optional[str] = Query(None, description="Filter: REQUESTED, APPROVED, REJECTED, CANCELLED, COMPLETED"),
    current_user: dict = Depends(require_role(["PATIENT"])),
    db: Session = Depends(get_db),
):
    """
    Returns the authenticated patient's appointments across all statuses.
    """
    patient_id = current_user["user_id"]
    appts = AppointmentService.get_patient_appointments(db, patient_id, status_filter=status)

    results = []
    for a in appts:
        results.append(
            AppointmentResponse(
                id=a.id,
                appointment_id=a.appointment_id,
                patient_id=a.patient_id,
                patient_name=a.patient.name if a.patient else None,
                doctor_id=a.doctor_id,
                doctor_name=a.doctor.name if a.doctor else None,
                doctor_specialization=a.doctor.specialization if a.doctor else None,
                consultation_id=a.consultation_id,
                availability_id=a.availability_id,
                appointment_date=a.appointment_date,
                start_time=a.start_time,
                end_time=a.end_time,
                consultation_type=a.consultation_type,
                reason=a.reason,
                status=a.status,
                patient_notes=a.patient_notes,
                doctor_notes=a.doctor_notes,
                rejection_reason=a.rejection_reason,
                created_at=a.created_at,
            )
        )
    return results
