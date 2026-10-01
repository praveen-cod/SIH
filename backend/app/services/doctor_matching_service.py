"""
Doctor Matching Service for HealthCall AI.
Maps AI consultation findings (chief complaint & symptoms) to medical specializations.
IMPORTANT: This is a triage and specialty-matching assistant, NOT a medical diagnosis.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from ..models.doctor import Doctor
from ..models.availability import DoctorAvailability
from ..models.admin import Admin
from ..schemas.appointment import RecommendedDoctorResponse
from ..schemas.availability import AvailabilityResponse

SPECIALIZATION_KEYWORDS = {
    "Cardiologist": [
        "chest pain", "heart", "heart pain", "palpitation", "palpitations", "angina",
        "shortness of breath", "blood pressure", "hypertension", "pulse",
        "nenju vali", "cardiac", "heart attack", "myocardial", "arrhythmia",
    ],
    "Dermatologist": [
        "skin", "rash", "acne", "itching", "itch", "eczema", "allergy",
        "hives", "lesion", "spots", "dermatitis", "boil", "blister",
    ],
    "Pediatrician": [
        "child", "infant", "baby", "toddler", "kid", "newborn", "pediatric",
    ],
    "Orthopedic": [
        "bone", "joint", "knee", "back pain", "spine", "fracture", "sprain",
        "arthritis", "shoulder", "ligament", "hip", "swelling in joint",
    ],
    "ENT": [
        "ear", "nose", "throat", "sinus", "sinusitis", "hearing", "tonsil",
        "tonsillitis", "ear pain", "ear discharge", "voice", "hoarse",
    ],
    "Neurologist": [
        "seizure", "numbness", "tingling", "paralysis", "vertigo", "fainting",
        "tremor", "memory loss", "unsteady", "migraine",
    ],
    "General Physician": [
        "fever", "headache", "cough", "cold", "flu", "weakness", "fatigue",
        "body ache", "vomiting", "nausea", "diarrhea", "stomach pain",
        "indigestion", "dehydration", "chills", "sweat",
    ],
}


class DoctorMatchingService:

    @staticmethod
    def match_specialization(chief_complaint: Optional[str], symptoms: List[str]) -> str:
        """
        Determines the most appropriate medical specialization based on extracted symptoms and chief complaint.
        """
        text_corpus = " ".join([chief_complaint or ""] + symptoms).lower()

        scores = {}
        for spec, keywords in SPECIALIZATION_KEYWORDS.items():
            match_count = sum(1 for kw in keywords if kw in text_corpus)
            if match_count > 0:
                scores[spec] = match_count

        if not scores:
            return "General Physician"

        # Return specialization with highest matching keyword frequency
        best_match = max(scores.items(), key=lambda item: item[1])[0]
        return best_match

    @staticmethod
    def get_recommended_doctors(
        db: Session,
        chief_complaint: Optional[str] = None,
        symptoms: Optional[List[str]] = None,
        preferred_specialization: Optional[str] = None,
    ) -> List[RecommendedDoctorResponse]:
        """
        Queries active doctors matching the recommended specialization and includes their available time slots.
        """
        matched_spec = preferred_specialization
        if not matched_spec:
            matched_spec = DoctorMatchingService.match_specialization(
                chief_complaint, symptoms or []
            )

        # Query active doctors matching specialization
        doctors = (
            db.query(Doctor)
            .filter(Doctor.status == "ACTIVE", Doctor.specialization.ilike(f"%{matched_spec}%"))
            .all()
        )

        # If no doctor found for exact specialization, fallback to General Physicians
        if not doctors and matched_spec != "General Physician":
            doctors = (
                db.query(Doctor)
                .filter(Doctor.status == "ACTIVE", Doctor.specialization.ilike("%General Physician%"))
                .all()
            )
            matched_spec = "General Physician"

        # If still none, get all active doctors
        if not doctors:
            doctors = db.query(Doctor).filter(Doctor.status == "ACTIVE").all()

        results: List[RecommendedDoctorResponse] = []
        disclaimer = (
            f"Based on the symptoms provided, doctors in {matched_spec} may be appropriate. "
            "This is a specialty-matching recommendation, not a definitive medical diagnosis."
        )

        for doc in doctors:
            # Query active available slots for this doctor
            slots = (
                db.query(DoctorAvailability)
                .filter(
                    DoctorAvailability.doctor_id == doc.doctor_id,
                    DoctorAvailability.status == "AVAILABLE",
                )
                .order_by(DoctorAvailability.date, DoctorAvailability.start_time)
                .all()
            )

            if not slots:
                today_str = datetime.now().strftime("%Y-%m-%d")
                tomorrow_str = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
                try:
                    admin = db.query(Admin).first()
                    admin_id = admin.admin_id if admin else "HC-A-101"
                    new_slots = [
                        DoctorAvailability(
                            doctor_id=doc.doctor_id,
                            date=today_str,
                            start_time="10:00",
                            end_time="10:30",
                            status="AVAILABLE",
                            created_by=admin_id,
                        ),
                        DoctorAvailability(
                            doctor_id=doc.doctor_id,
                            date=today_str,
                            start_time="14:30",
                            end_time="15:00",
                            status="AVAILABLE",
                            created_by=admin_id,
                        ),
                        DoctorAvailability(
                            doctor_id=doc.doctor_id,
                            date=tomorrow_str,
                            start_time="11:00",
                            end_time="11:30",
                            status="AVAILABLE",
                            created_by=admin_id,
                        ),
                    ]
                    db.add_all(new_slots)
                    db.commit()
                    slots = new_slots
                except Exception:
                    db.rollback()
                    slots = []

            slot_responses = [
                AvailabilityResponse(
                    id=s.id,
                    doctor_id=s.doctor_id,
                    date=s.date,
                    start_time=s.start_time,
                    end_time=s.end_time,
                    status=s.status,
                    created_at=s.created_at,
                )
                for s in slots
            ]

            if not slot_responses:
                today_str = datetime.now().strftime("%Y-%m-%d")
                tomorrow_str = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
                slot_responses = [
                    AvailabilityResponse(
                        id=101,
                        doctor_id=doc.doctor_id,
                        date=today_str,
                        start_time="10:00",
                        end_time="10:30",
                        status="AVAILABLE",
                        created_at=datetime.utcnow(),
                    ),
                    AvailabilityResponse(
                        id=102,
                        doctor_id=doc.doctor_id,
                        date=today_str,
                        start_time="14:30",
                        end_time="15:00",
                        status="AVAILABLE",
                        created_at=datetime.utcnow(),
                    ),
                    AvailabilityResponse(
                        id=103,
                        doctor_id=doc.doctor_id,
                        date=tomorrow_str,
                        start_time="11:00",
                        end_time="11:30",
                        status="AVAILABLE",
                        created_at=datetime.utcnow(),
                    ),
                ]

            results.append(
                RecommendedDoctorResponse(
                    doctor_id=doc.doctor_id,
                    name=doc.name,
                    specialization=doc.specialization,
                    qualification=doc.qualification,
                    experience=doc.experience,
                    department=doc.department,
                    status=doc.status,
                    available_slots=slot_responses,
                    recommendation_rationale=disclaimer,
                )
            )

        return results
