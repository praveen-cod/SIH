
from typing import Optional, List
from datetime import datetime, date
from pydantic import BaseModel, EmailStr

class PatientDemographicsResponse(BaseModel):
    age: Optional[int] = None
    gender: Optional[str] = None
    ethnicity: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    bmi: Optional[float] = None
    smoking_status: Optional[str] = None
    alcohol_use: Optional[str] = None
    class Config:
        from_attributes = True

class MedicalHistoryResponse(BaseModel):
    condition: str
    diagnosis_date: Optional[date] = None
    duration: Optional[str] = None
    severity: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    class Config:
        from_attributes = True

class MedicationResponse(BaseModel):
    drug_name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    route: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    status: Optional[str] = None
    class Config:
        from_attributes = True

class LabResultResponse(BaseModel):
    test_name: str
    test_code: Optional[str] = None
    value: Optional[str] = None
    unit: Optional[str] = None
    reference_min: Optional[str] = None
    reference_max: Optional[str] = None
    test_date: Optional[date] = None
    abnormal_flag: bool
    lab_report_id: Optional[str] = None
    class Config:
        from_attributes = True

class VitalSignResponse(BaseModel):
    measurement_date: datetime
    heart_rate: Optional[str] = None
    systolic_bp: Optional[str] = None
    diastolic_bp: Optional[str] = None
    respiratory_rate: Optional[str] = None
    temperature: Optional[str] = None
    oxygen_saturation: Optional[str] = None
    weight: Optional[str] = None
    height: Optional[str] = None
    class Config:
        from_attributes = True

class DiagnosisResponse(BaseModel):
    diagnosis_code: Optional[str] = None
    diagnosis_name: str
    diagnosis_date: Optional[date] = None
    status: Optional[str] = None
    severity: Optional[str] = None
    class Config:
        from_attributes = True

class PatientDocumentResponse(BaseModel):
    document_type: Optional[str] = None
    file_name: str
    file_url: Optional[str] = None
    document_date: Optional[date] = None
    uploaded_date: datetime
    processing_status: Optional[str] = None
    class Config:
        from_attributes = True

class AllergyResponse(BaseModel):
    allergen: str
    reaction: Optional[str] = None
    severity: Optional[str] = None
    status: Optional[str] = None
    class Config:
        from_attributes = True

class ProcedureResponse(BaseModel):
    procedure_name: str
    procedure_date: Optional[date] = None
    body_site: Optional[str] = None
    outcome: Optional[str] = None
    class Config:
        from_attributes = True

class FamilyHistoryResponse(BaseModel):
    condition: str
    relationship: Optional[str] = None
    age_of_onset: Optional[int] = None
    class Config:
        from_attributes = True

class ReproductiveStatusResponse(BaseModel):
    pregnancy_status: Optional[str] = None
    pregnancy_test: Optional[str] = None
    pregnancy_test_date: Optional[date] = None
    contraception_method: Optional[str] = None
    menopause_status: Optional[str] = None
    class Config:
        from_attributes = True

class PatientProfileResponse(BaseModel):
    id: int
    patient_id: str
    patient_code: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    name: str
    date_of_birth: Optional[date] = None
    age: int
    gender: str
    phone: str
    email: EmailStr
    city: Optional[str] = None
    country: Optional[str] = None
    blood_group: Optional[str] = None
    emergency_contact: Optional[str] = None
    is_active: bool
    created_at: datetime
    
    demographics: Optional[PatientDemographicsResponse] = None
    medical_history: List[MedicalHistoryResponse] = []
    medications: List[MedicationResponse] = []
    lab_results: List[LabResultResponse] = []
    vital_signs: List[VitalSignResponse] = []
    diagnoses: List[DiagnosisResponse] = []
    documents: List[PatientDocumentResponse] = []
    allergies: List[AllergyResponse] = []
    procedures: List[ProcedureResponse] = []
    family_history: List[FamilyHistoryResponse] = []
    reproductive_status: Optional[ReproductiveStatusResponse] = None

    class Config:
        from_attributes = True

class PatientUpdateRequest(BaseModel):
    name: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    date_of_birth: Optional[date] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    blood_group: Optional[str] = None
    emergency_contact: Optional[str] = None

