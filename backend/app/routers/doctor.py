"""
Doctor clinical router for HealthCall AI.
Provides Doctor appointment request review, AI consultation summary viewing, and approval/rejection.
"""
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from ..database.database import get_db
from ..models.appointment import Appointment
from ..models.consultation import Consultation
from ..schemas.appointment import AppointmentResponse, AppointmentActionRequest
from ..schemas.consultation import ConsultationSummaryResponse
from ..services.appointment_service import AppointmentService
from ..services.consultation_service import ConsultationService
from ..dependencies.auth import require_role

router = APIRouter(prefix="/api/doctor", tags=["Doctor Clinical Workspace"])


@router.get("/appointments/requests", response_model=List[AppointmentResponse])
def get_pending_appointment_requests(
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """
    Retrieves all pending appointment requests (status: REQUESTED) assigned to the logged-in doctor.
    """
    doctor_id = current_user["user_id"]
    appts = AppointmentService.get_doctor_appointments(db, doctor_id, status_filter="REQUESTED")

    return [
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
        for a in appts
    ]


@router.get("/appointments", response_model=List[AppointmentResponse])
def get_doctor_appointments(
    status: Optional[str] = Query(None, description="Filter: REQUESTED, APPROVED, REJECTED, CANCELLED, COMPLETED"),
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """
    Retrieves all appointments for the logged-in doctor.
    """
    doctor_id = current_user["user_id"]
    appts = AppointmentService.get_doctor_appointments(db, doctor_id, status_filter=status)

    return [
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
        for a in appts
    ]


@router.get("/appointments/{appointment_id}/consultation-summary", response_model=ConsultationSummaryResponse)
def get_appointment_consultation_summary(
    appointment_id: str,
    current_user: dict = Depends(require_role(["DOCTOR", "ADMIN"])),
    db: Session = Depends(get_db),
):
    """
    Doctor reviews the AI consultation summary associated with the appointment request before approving.
    Validates that the doctor is assigned to this appointment or is an admin.
    """
    doctor_id = current_user["user_id"]
    role = current_user["role"]

    query = db.query(Appointment).filter(Appointment.appointment_id == appointment_id)
    if role == "DOCTOR":
        query = query.filter(Appointment.doctor_id == doctor_id)

    appt = query.first()
    if not appt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Appointment {appointment_id} not found or you are not authorized to view it.",
        )

    if not appt.consultation_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No AI Consultation is associated with this appointment.",
        )

    summary = ConsultationService.get_summary(db, appt.consultation_id)
    if not summary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultation intake record could not be found in the database.",
        )

    return summary


@router.post("/appointments/{appointment_id}/approve", response_model=AppointmentResponse)
def approve_appointment(
    appointment_id: str,
    action: Optional[AppointmentActionRequest] = None,
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """
    Doctor approves an appointment request.
    Transaction-safe: verifies slot availability, marks slot as BLOCKED, and confirms appointment as APPROVED.
    """
    doctor_id = current_user["user_id"]
    appt = AppointmentService.approve_appointment(
        db=db,
        doctor_id=doctor_id,
        appointment_id=appointment_id,
        action=action,
    )

    return AppointmentResponse(
        id=appt.id,
        appointment_id=appt.appointment_id,
        patient_id=appt.patient_id,
        patient_name=appt.patient.name if appt.patient else None,
        doctor_id=appt.doctor_id,
        doctor_name=appt.doctor.name if appt.doctor else None,
        doctor_specialization=appt.doctor.specialization if appt.doctor else None,
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


@router.post("/appointments/{appointment_id}/reject", response_model=AppointmentResponse)
def reject_appointment(
    appointment_id: str,
    action: Optional[AppointmentActionRequest] = None,
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """
    Doctor rejects an appointment request with optional clinical explanation.
    Slot remains AVAILABLE for other patients.
    """
    doctor_id = current_user["user_id"]
    appt = AppointmentService.reject_appointment(
        db=db,
        doctor_id=doctor_id,
        appointment_id=appointment_id,
        action=action,
    )

    return AppointmentResponse(
        id=appt.id,
        appointment_id=appt.appointment_id,
        patient_id=appt.patient_id,
        patient_name=appt.patient.name if appt.patient else None,
        doctor_id=appt.doctor_id,
        doctor_name=appt.doctor.name if appt.doctor else None,
        doctor_specialization=appt.doctor.specialization if appt.doctor else None,
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
