"""
Model exports for HealthCall AI database.
"""
from .patient import Patient
from .doctor import Doctor
from .admin import Admin
from .staff import Staff
from .consultation import Consultation
from .consultation_message import ConsultationMessage
from .availability import DoctorAvailability
from .appointment import Appointment

__all__ = [
    "Patient",
    "Doctor",
    "Admin",
    "Staff",
    "Consultation",
    "ConsultationMessage",
    "DoctorAvailability",
    "Appointment",
]
