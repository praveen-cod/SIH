"""
Patient database model for HealthCall AI.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Date
from sqlalchemy.orm import relationship
from ..database.database import Base


class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), unique=True, index=True, nullable=False)
    patient_code = Column(String(50), unique=True, index=True, nullable=True)
    first_name = Column(String(100), nullable=True)
    last_name = Column(String(100), nullable=True)
    name = Column(String(100), nullable=False)
    date_of_birth = Column(Date, nullable=True)
    age = Column(Integer, nullable=False)
    gender = Column(String(20), nullable=False)
    phone = Column(String(25), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    city = Column(String(100), nullable=True)
    country = Column(String(100), nullable=True)
    blood_group = Column(String(10), nullable=True)
    emergency_contact = Column(String(25), nullable=True)
    password_hash = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Core Relationships
    consultations = relationship("Consultation", back_populates="patient", cascade="all, delete-orphan")
    appointments = relationship("Appointment", back_populates="patient", cascade="all, delete-orphan")

    # Expanded Medical Profile Relationships
    demographics = relationship("PatientDemographics", backref="patient", uselist=False, cascade="all, delete-orphan")
    medical_history = relationship("MedicalHistory", backref="patient", cascade="all, delete-orphan")
    medications = relationship("Medication", backref="patient", cascade="all, delete-orphan")
    lab_results = relationship("LabResult", backref="patient", cascade="all, delete-orphan")
    vital_signs = relationship("VitalSign", backref="patient", cascade="all, delete-orphan")
    diagnoses = relationship("Diagnosis", backref="patient", cascade="all, delete-orphan")
    documents = relationship("PatientDocument", backref="patient", cascade="all, delete-orphan")
    allergies = relationship("Allergy", backref="patient", cascade="all, delete-orphan")
    procedures = relationship("Procedure", backref="patient", cascade="all, delete-orphan")
    family_history = relationship("FamilyHistory", backref="patient", cascade="all, delete-orphan")
    reproductive_status = relationship("ReproductiveStatus", backref="patient", uselist=False, cascade="all, delete-orphan")
