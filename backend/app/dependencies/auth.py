"""
Authentication and Role-Based Authorization Dependencies for HealthCall AI.
Validates JWT tokens and enforces strict role separation (PATIENT, DOCTOR, ADMIN).
"""
from typing import Optional, List, Dict, Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from ..database.database import get_db
from ..services.auth_service import decode_access_token
from ..models.patient import Patient
from ..models.doctor import Doctor
from ..models.admin import Admin

security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """
    Extracts and verifies JWT token from Authorization header.
    Returns user payload dictionary: {"user_id": ..., "role": ..., "user": <SQLAlchemy model>}
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication credentials were not provided.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("user_id")
    role = payload.get("role", "").upper()

    if not user_id or not role:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Malformed token claims.",
        )

    # Resolve database user based on claimed role
    user_obj = None
    if role == "PATIENT":
        user_obj = db.query(Patient).filter(Patient.patient_id == user_id, Patient.is_active == True).first()
    elif role == "DOCTOR":
        user_obj = db.query(Doctor).filter(Doctor.doctor_id == user_id, Doctor.status == "ACTIVE").first()
    elif role == "ADMIN":
        user_obj = db.query(Admin).filter(Admin.admin_id == user_id, Admin.status == "ACTIVE").first()

    if not user_obj:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"User with ID {user_id} ({role}) not found or account is inactive.",
        )

    return {
        "user_id": user_id,
        "role": role,
        "user": user_obj,
    }


def require_role(allowed_roles: List[str]):
    """
    Dependency factory to enforce role-based access control.
    Example: Depends(require_role(["PATIENT"]))
    """
    allowed_upper = [r.upper() for r in allowed_roles]

    async def role_checker(current_user: Dict[str, Any] = Depends(get_current_user)):
        user_role = current_user.get("role", "").upper()
        if user_role not in allowed_upper:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: User role '{user_role}' does not have required permissions.",
            )
        return current_user

    return role_checker
