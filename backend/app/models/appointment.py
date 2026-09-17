"""
Appointment database model for HealthCall AI.
Tracks the lifecycle: REQUESTED -> APPROVED / REJECTED -> COMPLETED / CANCELLED.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from ..database.database import Base


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    appointment_id = Column(String(50), unique=True, index=True, nullable=False)
    patient_id = Column(String(50), ForeignKey("patients.patient_id"), nullable=False, index=True)
    doctor_id = Column(String(50), ForeignKey("doctors.doctor_id"), nullable=False, index=True)
    consultation_id = Column(String(50), ForeignKey("consultations.consultation_id"), nullable=True, index=True)
    availability_id = Column(Integer, ForeignKey("doctor_availability.id"), nullable=True)

    appointment_date = Column(String(20), nullable=False)  # e.g. "30 Aug 2026"
    start_time = Column(String(20), nullable=False)        # e.g. "10:30 AM"
    end_time = Column(String(20), nullable=False)          # e.g. "11:00 AM"
    consultation_type = Column(String(50), default="Video", nullable=False)
    reason = Column(Text, nullable=False)
    status = Column(String(20), default="REQUESTED", nullable=False, index=True)  # REQUESTED, APPROVED, REJECTED, CANCELLED, COMPLETED

    patient_notes = Column(Text, nullable=True)
    doctor_notes = Column(Text, nullable=True)
    rejection_reason = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    patient = relationship("Patient", back_populates="appointments")
    doctor = relationship("Doctor", back_populates="appointments")
    consultation = relationship("Consultation", back_populates="appointments")
    availability = relationship("DoctorAvailability")
