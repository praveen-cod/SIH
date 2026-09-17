"""
Appointment Service for HealthCall AI.
Enforces transaction-safe appointment booking, double-booking prevention, and clinical workflow.
"""
import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from ..models.appointment import Appointment
from ..models.availability import DoctorAvailability
from ..models.doctor import Doctor
from ..models.patient import Patient
from ..schemas.appointment import AppointmentCreateRequest, AppointmentActionRequest


class AppointmentService:

    @staticmethod
    def request_appointment(
        db: Session,
        patient_id: str,
        req: AppointmentCreateRequest,
    ) -> Appointment:
        """
        Patient creates an appointment request.
        Slot remains in AVAILABLE state with appointment marked as REQUESTED.
        """
        # Validate patient
        patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
        if not patient:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Patient {patient_id} not found.",
            )

        # Validate doctor
        doctor = db.query(Doctor).filter(Doctor.doctor_id == req.doctor_id, Doctor.status == "ACTIVE").first()
        if not doctor:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Doctor {req.doctor_id} is not available or inactive.",
            )

        # Validate availability slot if specified
        if req.availability_id:
            slot = (
                db.query(DoctorAvailability)
                .filter(
                    DoctorAvailability.id == req.availability_id,
                    DoctorAvailability.doctor_id == req.doctor_id,
                )
                .first()
            )
            if not slot or slot.status != "AVAILABLE":
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="The requested time slot is no longer available. Please select another time.",
                )

        appt_id = f"HC-APT-{uuid.uuid4().hex[:6].upper()}"

        appointment = Appointment(
            appointment_id=appt_id,
            patient_id=patient_id,
            doctor_id=req.doctor_id,
            consultation_id=req.consultation_id,
            availability_id=req.availability_id,
            appointment_date=req.appointment_date,
            start_time=req.start_time,
            end_time=req.end_time or req.start_time,
            consultation_type=req.consultation_type or "Video",
            reason=req.reason,
            status="REQUESTED",
            patient_notes=req.patient_notes,
        )

        db.add(appointment)
        db.commit()
        db.refresh(appointment)
        return appointment

    @staticmethod
    def approve_appointment(
        db: Session,
        doctor_id: str,
        appointment_id: str,
        action: Optional[AppointmentActionRequest] = None,
    ) -> Appointment:
        """
        Doctor approves an appointment request.
        Executed within an isolated database transaction to prevent double booking.
        """
        # Begin transaction
        try:
            appt = (
                db.query(Appointment)
                .filter(
                    Appointment.appointment_id == appointment_id,
                    Appointment.doctor_id == doctor_id,
                )
                .with_for_update(nowait=False)
                .first()
            )

            if not appt:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Appointment {appointment_id} not found for doctor {doctor_id}.",
                )

            # 1. Verify appointment still has REQUESTED status
            if appt.status != "REQUESTED":
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"This appointment has already been processed (Current status: {appt.status}).",
                )

            # 2. Verify doctor is still ACTIVE
            doctor = db.query(Doctor).filter(Doctor.doctor_id == doctor_id).first()
            if not doctor or doctor.status != "ACTIVE":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Doctor profile is currently inactive.",
                )

            # 3. Verify availability slot still exists and has not been blocked
            if appt.availability_id:
                slot = (
                    db.query(DoctorAvailability)
                    .filter(DoctorAvailability.id == appt.availability_id)
                    .with_for_update(nowait=False)
                    .first()
                )
                if not slot:
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail="The requested slot was removed from schedule.",
                    )
                if slot.status != "AVAILABLE":
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail="This time slot is no longer available (slot status: " + slot.status + ").",
                    )

                # 4. Mark slot as BLOCKED / BOOKED
                slot.status = "BLOCKED"

            # 5. Confirm appointment
            appt.status = "APPROVED"
            if action and action.doctor_notes:
                appt.doctor_notes = action.doctor_notes

            db.commit()
            db.refresh(appt)
            return appt
        except HTTPException:
            db.rollback()
            raise
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to confirm appointment due to database error: {str(e)}",
            )

    @staticmethod
    def reject_appointment(
        db: Session,
        doctor_id: str,
        appointment_id: str,
        action: Optional[AppointmentActionRequest] = None,
    ) -> Appointment:
        """
        Doctor rejects an appointment request.
        Slot remains AVAILABLE so another patient can book.
        """
        appt = (
            db.query(Appointment)
            .filter(
                Appointment.appointment_id == appointment_id,
                Appointment.doctor_id == doctor_id,
            )
            .first()
        )

        if not appt:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Appointment {appointment_id} not found for doctor {doctor_id}.",
            )

        if appt.status != "REQUESTED":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Appointment cannot be rejected; current status is '{appt.status}'.",
            )

        appt.status = "REJECTED"
        appt.rejection_reason = (
            action.rejection_reason
            if (action and action.rejection_reason)
            else "Doctor unavailable due to urgent clinical duty."
        )
        if action and action.doctor_notes:
            appt.doctor_notes = action.doctor_notes

        # Ensure slot remains AVAILABLE
        if appt.availability_id:
            slot = db.query(DoctorAvailability).filter(DoctorAvailability.id == appt.availability_id).first()
            if slot and slot.status != "INACTIVE":
                slot.status = "AVAILABLE"

        db.commit()
        db.refresh(appt)
        return appt

    @staticmethod
    def get_doctor_appointments(
        db: Session,
        doctor_id: str,
        status_filter: Optional[str] = None,
    ) -> List[Appointment]:
        """Retrieves appointments for a doctor."""
        query = db.query(Appointment).filter(Appointment.doctor_id == doctor_id)
        if status_filter:
            query = query.filter(Appointment.status == status_filter.upper())
        return query.order_by(Appointment.created_at.desc()).all()

    @staticmethod
    def get_patient_appointments(
        db: Session,
        patient_id: str,
        status_filter: Optional[str] = None,
    ) -> List[Appointment]:
        """Retrieves appointments for a patient."""
        query = db.query(Appointment).filter(Appointment.patient_id == patient_id)
        if status_filter:
            query = query.filter(Appointment.status == status_filter.upper())
        return query.order_by(Appointment.created_at.desc()).all()

    @staticmethod
    def get_all_appointments(
        db: Session,
        status_filter: Optional[str] = None,
    ) -> List[Appointment]:
        """Admin overview of all appointments."""
        query = db.query(Appointment)
        if status_filter:
            query = query.filter(Appointment.status == status_filter.upper())
        return query.order_by(Appointment.created_at.desc()).all()
