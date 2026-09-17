"""
Staff database model for HealthCall AI.
Staff are managed strictly by Admins.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from ..database.database import Base


class Staff(Base):
    __tablename__ = "staff"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    staff_id = Column(String(50), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    phone = Column(String(25), nullable=False)
    role = Column(String(50), nullable=False)  # Nurse, Receptionist, Pharmacist, Triage Officer
    department = Column(String(100), nullable=False)
    status = Column(String(20), default="ACTIVE", nullable=False)  # ACTIVE, INACTIVE
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
