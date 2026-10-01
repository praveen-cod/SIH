
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Date, Text, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from ..database.database import Base

class PatientDemographics(Base):
    __tablename__ = 'patient_demographics'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    age = Column(Integer, nullable=True)
    gender = Column(String(50), nullable=True)
    ethnicity = Column(String(100), nullable=True)
    height_cm = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)
    bmi = Column(Float, nullable=True)
    smoking_status = Column(String(50), nullable=True)
    alcohol_use = Column(String(50), nullable=True)

class MedicalHistory(Base):
    __tablename__ = 'medical_history'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    condition = Column(String(200), nullable=False)
    diagnosis_date = Column(Date, nullable=True)
    duration = Column(String(50), nullable=True)
    severity = Column(String(50), nullable=True)
    status = Column(String(50), nullable=True)
    notes = Column(Text, nullable=True)

class Medication(Base):
    __tablename__ = 'medications'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    drug_name = Column(String(200), nullable=False)
    dosage = Column(String(100), nullable=True)
    frequency = Column(String(100), nullable=True)
    route = Column(String(100), nullable=True)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    status = Column(String(50), nullable=True)

class LabResult(Base):
    __tablename__ = 'lab_results'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    test_name = Column(String(200), nullable=False)
    test_code = Column(String(100), nullable=True)
    value = Column(String(100), nullable=True)
    unit = Column(String(50), nullable=True)
    reference_min = Column(String(50), nullable=True)
    reference_max = Column(String(50), nullable=True)
    test_date = Column(Date, nullable=True)
    abnormal_flag = Column(Boolean, default=False)
    lab_report_id = Column(String(100), nullable=True)

class VitalSign(Base):
    __tablename__ = 'vital_signs'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    measurement_date = Column(DateTime, default=datetime.utcnow)
    heart_rate = Column(String(50), nullable=True)
    systolic_bp = Column(String(50), nullable=True)
    diastolic_bp = Column(String(50), nullable=True)
    respiratory_rate = Column(String(50), nullable=True)
    temperature = Column(String(50), nullable=True)
    oxygen_saturation = Column(String(50), nullable=True)
    weight = Column(String(50), nullable=True)
    height = Column(String(50), nullable=True)

class Diagnosis(Base):
    __tablename__ = 'diagnoses'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    diagnosis_code = Column(String(50), nullable=True)
    diagnosis_name = Column(String(200), nullable=False)
    diagnosis_date = Column(Date, nullable=True)
    status = Column(String(50), nullable=True)
    severity = Column(String(50), nullable=True)

class PatientDocument(Base):
    __tablename__ = 'patient_documents'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    document_type = Column(String(100), nullable=True)
    file_name = Column(String(200), nullable=False)
    file_url = Column(Text, nullable=True)
    document_date = Column(Date, nullable=True)
    uploaded_date = Column(DateTime, default=datetime.utcnow)
    extracted_text = Column(Text, nullable=True)
    processing_status = Column(String(50), nullable=True)

class Allergy(Base):
    __tablename__ = 'allergies'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    allergen = Column(String(200), nullable=False)
    reaction = Column(String(200), nullable=True)
    severity = Column(String(50), nullable=True)
    status = Column(String(50), nullable=True)

class Procedure(Base):
    __tablename__ = 'procedures'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    procedure_name = Column(String(200), nullable=False)
    procedure_date = Column(Date, nullable=True)
    body_site = Column(String(100), nullable=True)
    outcome = Column(String(100), nullable=True)

class FamilyHistory(Base):
    __tablename__ = 'family_history'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    condition = Column(String(200), nullable=False)
    relationship = Column(String(100), nullable=True)
    age_of_onset = Column(Integer, nullable=True)

class ReproductiveStatus(Base):
    __tablename__ = 'reproductive_status'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(String(50), ForeignKey('patients.patient_id', ondelete='CASCADE'), index=True, nullable=False)
    pregnancy_status = Column(String(100), nullable=True)
    pregnancy_test = Column(String(100), nullable=True)
    pregnancy_test_date = Column(Date, nullable=True)
    contraception_method = Column(String(200), nullable=True)
    menopause_status = Column(String(100), nullable=True)


