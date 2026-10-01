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

@router.get("/me/activity", response_model=List[dict])
def get_doctor_activity(
    skip: int = 0,
    limit: int = 20,
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """Get recent activity for the current doctor."""
    from ..models.audit_log import AuditLog
    doctor_id = current_user["user_id"]
    activities = db.query(AuditLog).filter(AuditLog.user_id == doctor_id).order_by(AuditLog.created_at.desc()).offset(skip).limit(limit).all()
    return [{"action": a.action, "details": a.details, "created_at": a.created_at} for a in activities]


@router.get("/availability")
def get_doctor_availability(
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """Get the weekly availability schedule for the current doctor."""
    from ..models.availability import DoctorAvailability

    doctor_id = current_user["user_id"]
    availabilities = db.query(DoctorAvailability).filter(DoctorAvailability.doctor_id == doctor_id).all()
    
    # Group by date (which acts as day of week)
    schedule = {}
    for a in availabilities:
        day = a.date
        if day not in schedule:
            schedule[day] = []
        schedule[day].append({
            "start": a.start_time,
            "end": a.end_time,
            "enabled": a.status == "AVAILABLE"
        })
        
    return schedule

from pydantic import BaseModel
class TimeSlot(BaseModel):
    start: str
    end: str
    enabled: bool

class AvailabilityUpdate(BaseModel):
    schedule: dict[str, list[TimeSlot]]

@router.post("/availability")
def update_doctor_availability(
    data: AvailabilityUpdate,
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """Update the weekly availability schedule for the current doctor."""
    from ..models.availability import DoctorAvailability

    doctor_id = current_user["user_id"]
    
    # Delete existing
    db.query(DoctorAvailability).filter(DoctorAvailability.doctor_id == doctor_id).delete()
    
    # Create new
    for day, slots in data.schedule.items():
        for slot in slots:
            db.add(DoctorAvailability(
                doctor_id=doctor_id,
                date=day,
                start_time=slot.start,
                end_time=slot.end,
                status="AVAILABLE" if slot.enabled else "INACTIVE",
                created_by=doctor_id,
            ))
            
    db.commit()
    return {"message": "Availability updated successfully"}

@router.get("/patients")
def get_doctor_patients(
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """Get all patients for the doctor to view in the portal."""
    from ..models.patient import Patient

    # Currently returning ALL patients in the system for testing/demo purposes
    patients = db.query(Patient).all()
    
    if not patients:
        return []
    
    return [
        {
            "id": p.id,
            "patient_id": p.patient_id,
            "name": p.name,
            "age": p.age,
            "gender": p.gender,
            "email": p.email,
            "phone": p.phone,
        }
        for p in patients
    ]

@router.get("/patients/{patient_id}/profile")
def get_patient_profile_for_doctor(
    patient_id: str,
    current_user: dict = Depends(require_role(["DOCTOR"])),
    db: Session = Depends(get_db),
):
    """Allow a doctor to view full details of a patient profile."""
    from ..models.patient import Patient
    from ..models.patient_data import PatientDemographics
    from sqlalchemy.orm import joinedload

    patient = (
        db.query(Patient)
        .options(
            joinedload(Patient.demographics),
            joinedload(Patient.medical_history),
            joinedload(Patient.medications),
            joinedload(Patient.lab_results),
            joinedload(Patient.vital_signs),
            joinedload(Patient.diagnoses),
            joinedload(Patient.documents),
            joinedload(Patient.allergies),
        )
        .filter(Patient.patient_id == patient_id)
        .first()
    )

    if not patient:
        # Try searching by numeric ID
        try:
            pid = int(patient_id)
            patient = (
                db.query(Patient)
                .options(
                    joinedload(Patient.demographics),
                    joinedload(Patient.medical_history),
                    joinedload(Patient.medications),
                    joinedload(Patient.lab_results),
                    joinedload(Patient.vital_signs),
                    joinedload(Patient.diagnoses),
                    joinedload(Patient.documents),
                    joinedload(Patient.allergies),
                )
                .filter(Patient.id == pid)
                .first()
            )
        except (ValueError, TypeError):
            pass

    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    demo = patient.demographics
    return {
        "id": patient.id,
        "patient_id": patient.patient_id,
        "name": patient.name,
        "age": patient.age,
        "gender": patient.gender,
        "phone": patient.phone,
        "email": patient.email,
        "emergency_contact": patient.emergency_contact,
        "blood_group": patient.blood_group,
        "city": patient.city,
        "country": patient.country,
        "medical_history": [
            {"condition": h.condition, "status": h.status}
            for h in (patient.medical_history or [])
        ],
        "medications": [
            {"name": m.drug_name, "dosage": m.dosage, "frequency": m.frequency}
            for m in (patient.medications or [])
        ],
        "lab_results": [
            {"test_name": l.test_name, "result_value": l.value, "unit": l.unit, "reference_range": f"{l.reference_min}-{l.reference_max}"}
            for l in (patient.lab_results or [])
        ],
        "vital_signs": [
            {
                "measurement_date": str(v.measurement_date),
                "heart_rate": v.heart_rate,
                "systolic_bp": v.systolic_bp,
                "diastolic_bp": v.diastolic_bp,
                "temperature": v.temperature,
                "oxygen_saturation": v.oxygen_saturation,
            }
            for v in (patient.vital_signs or [])
        ],
        "diagnoses": [
            {"diagnosis": d.diagnosis_name, "icd_code": d.diagnosis_code}
            for d in (patient.diagnoses or [])
        ],
        "allergies": [
            {"allergen": a.allergen, "severity": a.severity}
            for a in (patient.allergies or [])
        ],
        "documents": [
            {"file_name": doc.file_name, "processing_status": doc.processing_status}
            for doc in (patient.documents or [])
        ],
    }

