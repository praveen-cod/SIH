"""
Doctor Availability Service for HealthCall AI.
Enforces admin control over doctor availability and cascades status changes.
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from ..models.availability import DoctorAvailability
from ..models.doctor import Doctor
from ..models.appointment import Appointment
from ..schemas.availability import AvailabilityCreateRequest, AvailabilityUpdateRequest


class AvailabilityService:

    @staticmethod
    def create_availability(
        db: Session,
        admin_id: str,
        req: AvailabilityCreateRequest,
    ) -> DoctorAvailability:
        """Admin creates a new availability slot for a doctor."""
        doctor = db.query(Doctor).filter(Doctor.doctor_id == req.doctor_id).first()
        if not doctor:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Doctor {req.doctor_id} not found.",
            )

        slot = DoctorAvailability(
            doctor_id=req.doctor_id,
            date=req.date,
            start_time=req.start_time,
            end_time=req.end_time,
            status="AVAILABLE",
            created_by=admin_id,
        )
        db.add(slot)
        db.commit()
        db.refresh(slot)
        return slot

    @staticmethod
    def update_availability(
        db: Session,
        availability_id: int,
        req: AvailabilityUpdateRequest,
    ) -> DoctorAvailability:
        """Admin updates an availability slot, with cascade cancellation for blocked slots."""
        slot = db.query(DoctorAvailability).filter(DoctorAvailability.id == availability_id).first()
        if not slot:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Availability slot {availability_id} not found.",
            )

        if req.date is not None:
            slot.date = req.date
        if req.start_time is not None:
            slot.start_time = req.start_time
        if req.end_time is not None:
            slot.end_time = req.end_time
        if req.status is not None:
            new_status = req.status.upper()
            slot.status = new_status

            # If admin blocks or deactivates the slot, invalidate any pending requests on it
            if new_status in ["BLOCKED", "INACTIVE"]:
                pending_appts = (
                    db.query(Appointment)
                    .filter(
                        Appointment.availability_id == slot.id,
                        Appointment.status == "REQUESTED",
                    )
                    .all()
                )
                for appt in pending_appts:
                    appt.status = "CANCELLED"
                    appt.rejection_reason = "Requested time slot is no longer available due to administrative schedule adjustment."

        db.commit()
        db.refresh(slot)
        return slot

    @staticmethod
    def delete_availability(db: Session, availability_id: int) -> bool:
        """Admin removes an availability slot, canceling any pending requests."""
        slot = db.query(DoctorAvailability).filter(DoctorAvailability.id == availability_id).first()
        if not slot:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Availability slot {availability_id} not found.",
            )

        # Cancel any pending appointments
        pending_appts = (
            db.query(Appointment)
            .filter(
                Appointment.availability_id == slot.id,
                Appointment.status == "REQUESTED",
            )
            .all()
        )
        for appt in pending_appts:
            appt.status = "CANCELLED"
            appt.rejection_reason = "Requested time slot was removed from schedule."

        db.delete(slot)
        db.commit()
        return True

    @staticmethod
    def get_doctor_slots(
        db: Session,
        doctor_id: str,
        only_available: bool = True,
    ) -> List[DoctorAvailability]:
        """Retrieves slots for a specific doctor."""
        query = db.query(DoctorAvailability).filter(DoctorAvailability.doctor_id == doctor_id)
        if only_available:
            query = query.filter(DoctorAvailability.status == "AVAILABLE")
        return query.order_by(DoctorAvailability.date, DoctorAvailability.start_time).all()
