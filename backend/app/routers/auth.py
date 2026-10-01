"""
Authentication router for HealthCall AI.
Provides Patient registration, Multi-role Login, and JWT Token issuance.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database.database import get_db
from ..models.patient import Patient
from ..models.doctor import Doctor
from ..models.admin import Admin
from ..schemas.auth import LoginRequest, LoginResponse, PatientRegisterRequest
from ..services.auth_service import verify_password, get_password_hash, create_access_token

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/patient/register", response_model=LoginResponse, status_code=status.HTTP_201_CREATED)
def register_patient(req: PatientRegisterRequest, db: Session = Depends(get_db)):
    """
    Public registration endpoint for Patients only.
    Generates unique Patient ID (HC-P-10001+), hashes password, and creates SQLite record.
    """
    # 1. Validate confirm password if provided
    if req.confirm_password and req.password != req.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password and confirmation password do not match.",
        )

    # 2. Check for duplicate email
    existing_patient = db.query(Patient).filter(Patient.email.ilike(req.email)).first()
    if existing_patient:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A patient account with this email address already exists.",
        )

    # 3. Generate sequential/unique Patient ID
    total_count = db.query(Patient).count()
    patient_id = f"HC-P-{10001 + total_count}"

    # 4. Hash password and persist
    hashed_pwd = get_password_hash(req.password)
    new_patient = Patient(
        patient_id=patient_id,
        name=req.name.strip(),
        age=req.age,
        gender=req.gender.strip(),
        phone=req.phone.strip(),
        emergency_contact=req.emergency_contact.strip() if req.emergency_contact else None,
        email=req.email.lower().strip(),
        password_hash=hashed_pwd,
        is_active=True,
    )
    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)

    # 5. Issue JWT access token
    from ..services.audit_service import log_audit_action
    log_audit_action(
        db=db,
        user_id=new_patient.patient_id,
        user_role="Patient",
        action="Registered a new patient account"
    )

    token = create_access_token({
        "user_id": new_patient.patient_id,
        "role": "PATIENT",
        "email": new_patient.email,
    })

    return LoginResponse(
        success=True,
        token=token,
        user_id=new_patient.patient_id,
        name=new_patient.name,
        role="PATIENT",
        email=new_patient.email,
        phone=new_patient.phone,
        emergency_contact=new_patient.emergency_contact,
    )


@router.post("/login", response_model=LoginResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    """
    Unified multi-role login endpoint for Patient, Doctor, and Admin.
    Checks password hash and returns signed JWT token.
    """
    clean_email = req.email.lower().strip()
    plain_password = req.password

    # Determine requested role hint if provided
    role_hint = (req.role or "patient").lower()

    # Search in order: hinted role first, then others
    if role_hint == "doctor":
        doctor = db.query(Doctor).filter(Doctor.email.ilike(clean_email)).first()
        if doctor:
            if not verify_password(plain_password, doctor.password_hash):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password.",
                )
            if doctor.status != "ACTIVE":
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Doctor account is {doctor.status}. Please contact the administrator.",
                )
            token = create_access_token({
                "user_id": doctor.doctor_id,
                "role": "DOCTOR",
                "email": doctor.email,
            })
            return LoginResponse(
                success=True,
                token=token,
                user_id=doctor.doctor_id,
                name=doctor.name,
                role="DOCTOR",
                email=doctor.email,
            )

    elif role_hint == "admin":
        admin = db.query(Admin).filter(Admin.email.ilike(clean_email)).first()
        if admin:
            if not verify_password(plain_password, admin.password_hash):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid email or password.",
                )
            if admin.status != "ACTIVE":
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Admin account is inactive.",
                )
            token = create_access_token({
                "user_id": admin.admin_id,
                "role": "ADMIN",
                "email": admin.email,
            })
            return LoginResponse(
                success=True,
                token=token,
                user_id=admin.admin_id,
                name=admin.name,
                role="ADMIN",
                email=admin.email,
            )

    # Check Patient table
    patient = db.query(Patient).filter(Patient.email.ilike(clean_email)).first()
    if patient:
        if not verify_password(plain_password, patient.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
            )
        if not patient.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Patient account has been deactivated.",
            )
        token = create_access_token({
            "user_id": patient.patient_id,
            "role": "PATIENT",
            "email": patient.email,
        })
        
        from ..services.audit_service import log_audit_action
        log_audit_action(
            db=db,
            user_id=patient.patient_id,
            user_role="Patient",
            action="Logged into the system"
        )
        
        return LoginResponse(
            success=True,
            token=token,
            user_id=patient.patient_id,
            name=patient.name,
            role="PATIENT",
            email=patient.email,
            phone=patient.phone,
            emergency_contact=patient.emergency_contact,
        )

    # Fallback search across remaining tables if role hint didn't match
    doctor = db.query(Doctor).filter(Doctor.email.ilike(clean_email)).first()
    if doctor and verify_password(plain_password, doctor.password_hash):
        token = create_access_token({"user_id": doctor.doctor_id, "role": "DOCTOR", "email": doctor.email})
        return LoginResponse(success=True, token=token, user_id=doctor.doctor_id, name=doctor.name, role="DOCTOR", email=doctor.email)

    admin = db.query(Admin).filter(Admin.email.ilike(clean_email)).first()
    if admin and verify_password(plain_password, admin.password_hash):
        token = create_access_token({"user_id": admin.admin_id, "role": "ADMIN", "email": admin.email})
        return LoginResponse(success=True, token=token, user_id=admin.admin_id, name=admin.name, role="ADMIN", email=admin.email)

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid email or password.",
    )
