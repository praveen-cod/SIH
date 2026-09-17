"""
Doctor Availability database model for HealthCall AI.
Doctor availability is strictly created and managed by Admins.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from ..database.database import Base


class DoctorAvailability(Base):
    __tablename__ = "doctor_availability"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    doctor_id = Column(String(50), ForeignKey("doctors.doctor_id"), nullable=False, index=True)
    date = Column(String(20), nullable=False, index=True)  # e.g. "2026-08-30" or "30 Aug 2026"
    start_time = Column(String(20), nullable=False)        # e.g. "10:30 AM"
    end_time = Column(String(20), nullable=False)          # e.g. "11:00 AM"
    status = Column(String(20), default="AVAILABLE", nullable=False, index=True)  # AVAILABLE, BLOCKED, INACTIVE
    created_by = Column(String(50), nullable=False)        # admin_id
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    doctor = relationship("Doctor", back_populates="availability")
