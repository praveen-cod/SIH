"""
Consultation database model for HealthCall AI.
Stores completed patient AI intakes and summaries in SQLite.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from ..database.database import Base


class Consultation(Base):
    __tablename__ = "consultations"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    consultation_id = Column(String(50), unique=True, index=True, nullable=False)
    patient_id = Column(String(50), ForeignKey("patients.patient_id"), nullable=True, index=True)
    session_id = Column(String(100), unique=True, index=True, nullable=False)
    chief_complaint = Column(String(255), nullable=True)
    symptoms = Column(Text, nullable=True)  # JSON-encoded list of symptoms
    duration = Column(String(50), nullable=True)
    severity = Column(String(50), nullable=True)
    preferred_language = Column(String(10), default="en", nullable=False)
    emergency_flag = Column(Boolean, default=False, nullable=False)
    emergency_reason = Column(String(255), nullable=True)
    emergency_image_url = Column(Text, nullable=True)
    latitude = Column(String(50), nullable=True)
    longitude = Column(String(50), nullable=True)
    intake_complete = Column(Boolean, default=False, nullable=False)
    summary = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    patient = relationship("Patient", back_populates="consultations")
    messages = relationship("ConsultationMessage", back_populates="consultation", cascade="all, delete-orphan")
    appointments = relationship("Appointment", back_populates="consultation")
