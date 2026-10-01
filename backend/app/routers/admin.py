"""
Admin operations router for HealthCall AI.
Provides Doctor management, Staff control, Availability schedule maintenance, and System appointment monitoring.
"""
import uuid
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from ..database.database import get_db
from ..models.doctor import Doctor
from ..models.staff import Staff
from ..models.availability import DoctorAvailability
from ..models.patient import Patient
from ..schemas.doctor import DoctorCreateRequest, DoctorUpdateRequest, DoctorResponse
from ..schemas.staff import StaffCreateRequest, StaffUpdateRequest, StaffResponse
from ..schemas.availability import AvailabilityCreateRequest, AvailabilityUpdateRequest, AvailabilityResponse
from ..schemas.appointment import AppointmentResponse
from ..schemas.patient import PatientProfileResponse
from ..services.auth_service import get_password_hash
from ..services.availability_service import AvailabilityService
from ..services.appointment_service import AppointmentService
from ..dependencies.auth import require_role

router = APIRouter(prefix="/api/admin", tags=["Admin Operations"])


# ---------------------------------------------------------------------------
# Doctor Management
# ---------------------------------------------------------------------------

@router.post("/doctors", response_model=DoctorResponse, status_code=status.HTTP_201_CREATED)
def create_doctor(
    req: DoctorCreateRequest,
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin creates a new Doctor account. Assigns unique HC-D-1000+ ID and bcrypt hash."""
    clean_email = req.email.lower().strip()
    existing = db.query(Doctor).filter(Doctor.email.ilike(clean_email)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A doctor with email '{req.email}' already exists.",
        )

    count = db.query(Doctor).count()
    doctor_id = f"HC-D-{1001 + count}"

    new_doc = Doctor(
        doctor_id=doctor_id,
        name=req.name.strip(),
        email=clean_email,
        phone=req.phone.strip(),
        password_hash=get_password_hash(req.password),
        specialization=req.specialization.strip(),
        qualification=req.qualification.strip(),
        experience=req.experience,
        license_number=req.license_number.strip(),
        department=req.department.strip(),
        status=req.status or "ACTIVE",
    )
    db.add(new_doc)
    db.commit()
    db.refresh(new_doc)
    return new_doc


@router.put("/doctors/{doctor_id}", response_model=DoctorResponse)
def update_doctor(
    doctor_id: str,
    req: DoctorUpdateRequest,
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin updates doctor information."""
    doc = db.query(Doctor).filter(Doctor.doctor_id == doctor_id).first()
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Doctor {doctor_id} not found.",
        )

    if req.name is not None:
        doc.name = req.name.strip()
    if req.phone is not None:
        doc.phone = req.phone.strip()
    if req.specialization is not None:
        doc.specialization = req.specialization.strip()
    if req.qualification is not None:
        doc.qualification = req.qualification.strip()
    if req.experience is not None:
        doc.experience = req.experience
    if req.department is not None:
        doc.department = req.department.strip()
    if req.status is not None:
        doc.status = req.status.upper().strip()

    db.commit()
    db.refresh(doc)
    return doc


@router.get("/doctors", response_model=List[DoctorResponse])
def list_doctors(
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin lists all doctors."""
    return db.query(Doctor).order_by(Doctor.name).all()


@router.get("/patients", response_model=List[PatientProfileResponse])
def list_patients(
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin lists all registered patients."""
    return db.query(Patient).order_by(Patient.name).all()


# ---------------------------------------------------------------------------
# Staff Management
# ---------------------------------------------------------------------------

@router.post("/staff", response_model=StaffResponse, status_code=status.HTTP_201_CREATED)
def create_staff(
    req: StaffCreateRequest,
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin registers a healthcare staff member."""
    clean_email = req.email.lower().strip()
    existing = db.query(Staff).filter(Staff.email.ilike(clean_email)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Staff member with email '{req.email}' already exists.",
        )

    count = db.query(Staff).count()
    staff_id = f"HC-S-{101 + count}"

    new_staff = Staff(
        staff_id=staff_id,
        name=req.name.strip(),
        email=clean_email,
        phone=req.phone.strip(),
        role=req.role.strip(),
        department=req.department.strip(),
        status=req.status or "ACTIVE",
    )
    db.add(new_staff)
    db.commit()
    db.refresh(new_staff)
    return new_staff


@router.put("/staff/{staff_id}", response_model=StaffResponse)
def update_staff(
    staff_id: str,
    req: StaffUpdateRequest,
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin updates staff details or deactivates member."""
    staff = db.query(Staff).filter(Staff.staff_id == staff_id).first()
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Staff member {staff_id} not found.",
        )

    if req.name is not None:
        staff.name = req.name.strip()
    if req.phone is not None:
        staff.phone = req.phone.strip()
    if req.role is not None:
        staff.role = req.role.strip()
    if req.department is not None:
        staff.department = req.department.strip()
    if req.status is not None:
        staff.status = req.status.upper().strip()

    db.commit()
    db.refresh(staff)
    return staff


@router.get("/staff", response_model=List[StaffResponse])
def list_staff(
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin lists all healthcare staff."""
    return db.query(Staff).order_by(Staff.name).all()


# ---------------------------------------------------------------------------
# Availability Schedule Control
# ---------------------------------------------------------------------------

@router.post("/availability", response_model=AvailabilityResponse, status_code=status.HTTP_201_CREATED)
def create_doctor_availability(
    req: AvailabilityCreateRequest,
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin creates an availability slot for a doctor."""
    admin_id = current_user["user_id"]
    slot = AvailabilityService.create_availability(db, admin_id, req)
    return AvailabilityResponse(
        id=slot.id,
        doctor_id=slot.doctor_id,
        date=slot.date,
        start_time=slot.start_time,
        end_time=slot.end_time,
        status=slot.status,
        created_at=slot.created_at,
    )


@router.put("/availability/{availability_id}", response_model=AvailabilityResponse)
def update_doctor_availability(
    availability_id: int,
    req: AvailabilityUpdateRequest,
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin updates or blocks an availability slot. Cascades cancellation to pending requests."""
    slot = AvailabilityService.update_availability(db, availability_id, req)
    return AvailabilityResponse(
        id=slot.id,
        doctor_id=slot.doctor_id,
        date=slot.date,
        start_time=slot.start_time,
        end_time=slot.end_time,
        status=slot.status,
        created_at=slot.created_at,
    )


@router.delete("/availability/{availability_id}")
def delete_doctor_availability(
    availability_id: int,
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin deletes an availability slot."""
    AvailabilityService.delete_availability(db, availability_id)
    return {"success": True, "message": f"Availability slot {availability_id} removed."}


# ---------------------------------------------------------------------------
# System Appointment Management
# ---------------------------------------------------------------------------

@router.get("/appointments", response_model=List[AppointmentResponse])
def list_system_appointments(
    status: Optional[str] = Query(None),
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin overview of all platform appointments."""
    appts = AppointmentService.get_all_appointments(db, status_filter=status)
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

# ---------------------------------------------------------------------------
# Audit Logs
# ---------------------------------------------------------------------------

from ..models.audit_log import AuditLog
from ..schemas.audit_log import AuditLogResponse

@router.get("/audit-logs", response_model=List[AuditLogResponse])
def get_audit_logs(
    skip: int = 0,
    limit: int = 100,
    current_user: dict = Depends(require_role(["ADMIN"])),
    db: Session = Depends(get_db),
):
    """Admin view of all audit logs."""
    return db.query(AuditLog).order_by(AuditLog.created_at.desc()).offset(skip).limit(limit).all()
