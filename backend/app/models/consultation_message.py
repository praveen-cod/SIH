"""
Consultation Message database model for HealthCall AI.
Persists full dialog history between Patient and AI.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from ..database.database import Base


class ConsultationMessage(Base):
    __tablename__ = "consultation_messages"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    consultation_id = Column(String(50), ForeignKey("consultations.consultation_id"), nullable=False, index=True)
    role = Column(String(20), nullable=False)  # USER, AI, SYSTEM
    message = Column(Text, nullable=False)
    language = Column(String(10), default="en", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    consultation = relationship("Consultation", back_populates="messages")
