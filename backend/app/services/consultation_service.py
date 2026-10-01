"""
Consultation Storage Service for HealthCall AI.
Persists AI consultations, structured medical intake, and dialog messages in SQLite.
"""
import uuid
import json
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from ..models.consultation import Consultation
from ..models.consultation_message import ConsultationMessage
from ..models.patient import Patient
from ..schemas.consultation import ExtractedIntakeData, ConsultationSummaryResponse
from .twilio_service import twilio_service, normalize_phone_e164
import logging

logger = logging.getLogger(__name__)
class ConsultationService:

    @staticmethod
    def get_or_create_consultation(
        db: Session,
        session_id: str,
        patient_id: Optional[str] = None,
    ) -> Consultation:
        """Finds or initializes a consultation record associated with patient_id."""
        consultation = (
            db.query(Consultation)
            .filter(Consultation.session_id == session_id)
            .first()
        )
        if not consultation:
            consultation_id = f"HC-C-{uuid.uuid4().hex[:6].upper()}"
            consultation = Consultation(
                consultation_id=consultation_id,
                session_id=session_id,
                patient_id=patient_id,
                preferred_language="en",
                intake_complete=False,
            )
            db.add(consultation)
            db.commit()
            db.refresh(consultation)
        elif patient_id and not consultation.patient_id:
            # Associate guest consultation with newly authenticated patient
            consultation.patient_id = patient_id
            db.commit()
            db.refresh(consultation)

        return consultation

    @staticmethod
    def save_message(
        db: Session,
        consultation_id: str,
        role: str,
        message: str,
        language: str = "en",
    ) -> ConsultationMessage:
        """Appends a turn to the consultation history."""
        msg = ConsultationMessage(
            consultation_id=consultation_id,
            role=role.upper(),
            message=message,
            language=language,
        )
        db.add(msg)
        db.commit()
        db.refresh(msg)
        return msg

    @staticmethod
    def update_intake_data(
        db: Session,
        session_id: str,
        intake_data: ExtractedIntakeData,
    ) -> Consultation:
        """Updates the structured medical intake and emergency flags in SQLite."""
        consultation = (
            db.query(Consultation)
            .filter(Consultation.session_id == session_id)
            .first()
        )
        if not consultation:
            consultation = ConsultationService.get_or_create_consultation(db, session_id)

        if intake_data.chief_complaint:
            consultation.chief_complaint = intake_data.chief_complaint
        if intake_data.symptoms:
            consultation.symptoms = json.dumps(intake_data.symptoms)
        if intake_data.duration:
            consultation.duration = intake_data.duration
        if intake_data.severity:
            consultation.severity = intake_data.severity
        if intake_data.preferred_language:
            consultation.preferred_language = intake_data.preferred_language
            
        is_new_emergency = intake_data.should_flag_emergency and not consultation.emergency_flag
        
        if intake_data.should_flag_emergency:
            consultation.emergency_flag = True
            # Store emergency reason from chief complaint
            if intake_data.chief_complaint and not consultation.emergency_reason:
                consultation.emergency_reason = intake_data.chief_complaint

            if is_new_emergency and consultation.patient_id:
                patient = db.query(Patient).filter(Patient.patient_id == consultation.patient_id).first()
                if not patient:
                    logger.warning(
                        "Emergency escalation: patient_id %s not found for session %s",
                        consultation.patient_id,
                        session_id,
                    )
                elif not patient.emergency_contact:
                    logger.warning(
                        "Emergency escalation: no emergency_contact for patient %s (%s)",
                        patient.patient_id,
                        patient.name,
                    )
                else:
                    to_number = normalize_phone_e164(patient.emergency_contact)
                    patient_name = patient.name
                    location_info = (
                        f"Location coordinates are {consultation.latitude}, {consultation.longitude}."
                        if consultation.latitude
                        else "Location is unknown."
                    )
                    time_info = consultation.created_at.strftime("%I:%M %p on %B %d, %Y")
                    reason = consultation.emergency_reason or intake_data.chief_complaint or "severe distress"
                    symptoms_str = ", ".join(intake_data.symptoms) if intake_data.symptoms else "not specified"
                    clinical_summary = intake_data.clinical_summary or "Not available."

                    msg = (
                        f"URGENT EMERGENCY ALERT from HealthCall AI. "
                        f"The patient, {patient_name}, age {patient.age}, gender {patient.gender}, is currently experiencing a critical medical emergency. "
                        f"The primary reason for this escalation is: {reason}. "
                        f"This emergency occurred and was reported to our AI at exactly {time_info}. "
                        f"The patient's current location is {location_info}. "
                        f"During their conversation with the AI, the following was gathered: {clinical_summary}. "
                        f"Specific symptoms reported by the patient include: {symptoms_str}. "
                        f"Please treat this with the utmost urgency, contact emergency services if necessary, and attempt to reach the patient immediately."
                    )
                    logger.info(
                        "Emergency Twilio call for session %s, patient %s, to %s",
                        session_id,
                        patient.patient_id,
                        to_number,
                    )
                    ok = twilio_service.call_emergency_contact(to_number, msg)
                    if not ok:
                        logger.error(
                            "Emergency Twilio call failed for session %s (patient %s, number %s)",
                            session_id,
                            patient.patient_id,
                            to_number,
                        )


        if intake_data.intake_complete:
            consultation.intake_complete = True

        # Store enriched clinical summary data in summary column
        if intake_data.clinical_summary or intake_data.recommended_specialist or intake_data.key_observations:
            summary_payload = {
                "clinical_summary": intake_data.clinical_summary,
                "recommended_specialist": intake_data.recommended_specialist,
                "key_observations": intake_data.key_observations or [],
                "preliminary_guidance": intake_data.preliminary_guidance,
                "triage_level": intake_data.triage_level or "Routine",
            }
            consultation.summary = json.dumps(summary_payload)

        db.commit()
        db.refresh(consultation)
        return consultation

    @staticmethod
    def get_summary(
        db: Session,
        consultation_id: str,
    ) -> Optional[ConsultationSummaryResponse]:
        """Retrieves structured consultation summary."""
        consultation = (
            db.query(Consultation)
            .filter(
                (Consultation.consultation_id == consultation_id)
                | (Consultation.session_id == consultation_id)
            )
            .first()
        )
        if not consultation:
            return None

        # Resolve patient details if available
        patient_name = "Guest Patient"
        patient_age = None
        patient_gender = None
        if consultation.patient_id:
            patient = db.query(Patient).filter(Patient.patient_id == consultation.patient_id).first()
            if patient:
                patient_name = patient.name
                patient_age = patient.age
                patient_gender = patient.gender

        symptoms_list = []
        if consultation.symptoms:
            try:
                symptoms_list = json.loads(consultation.symptoms)
            except Exception:
                symptoms_list = [consultation.symptoms]

        clinical_summary = None
        recommended_specialist = None
        key_observations = []
        preliminary_guidance = None
        triage_level = "Routine"

        if consultation.summary:
            try:
                parsed = json.loads(consultation.summary)
                if isinstance(parsed, dict):
                    clinical_summary = parsed.get("clinical_summary")
                    recommended_specialist = parsed.get("recommended_specialist")
                    key_observations = parsed.get("key_observations", [])
                    preliminary_guidance = parsed.get("preliminary_guidance")
                    triage_level = parsed.get("triage_level", "Routine")
                else:
                    clinical_summary = str(consultation.summary)
            except Exception:
                clinical_summary = str(consultation.summary)

        return ConsultationSummaryResponse(
            consultation_id=consultation.consultation_id,
            patient_id=consultation.patient_id,
            session_id=consultation.session_id,
            patient_name=patient_name,
            age=patient_age,
            gender=patient_gender,
            chief_complaint=consultation.chief_complaint,
            symptoms=symptoms_list,
            duration=consultation.duration,
            severity=consultation.severity,
            preferred_language=consultation.preferred_language,
            emergency_flag=consultation.emergency_flag,
            emergency_reason=consultation.emergency_reason,
            emergency_image_url=consultation.emergency_image_url,
            latitude=consultation.latitude,
            longitude=consultation.longitude,
            intake_complete=consultation.intake_complete,
            clinical_summary=clinical_summary,
            recommended_specialist=recommended_specialist,
            key_observations=key_observations,
            preliminary_guidance=preliminary_guidance,
            triage_level=triage_level,
            created_at=consultation.created_at,
        )

    @staticmethod
    def update_summary(
        db: Session,
        identifier: str,
        chief_complaint: Optional[str] = None,
        symptoms: Optional[List[str]] = None,
        duration: Optional[str] = None,
        severity: Optional[str] = None,
        clinical_summary: Optional[str] = None,
        recommended_specialist: Optional[str] = None,
    ) -> Optional[ConsultationSummaryResponse]:
        """Updates summary and intake details edited by patient."""
        consultation = (
            db.query(Consultation)
            .filter(
                (Consultation.consultation_id == identifier)
                | (Consultation.session_id == identifier)
            )
            .first()
        )
        if not consultation:
            return None

        if chief_complaint is not None:
            consultation.chief_complaint = chief_complaint.strip()
        if symptoms is not None:
            consultation.symptoms = json.dumps(symptoms)
        if duration is not None:
            consultation.duration = duration.strip()
        if severity is not None:
            consultation.severity = severity.strip()

        # Update JSON clinical summary payload if provided
        summary_payload = {}
        if consultation.summary:
            try:
                parsed = json.loads(consultation.summary)
                if isinstance(parsed, dict):
                    summary_payload = parsed
            except Exception:
                pass

        if clinical_summary is not None:
            summary_payload["clinical_summary"] = clinical_summary
        if recommended_specialist is not None:
            summary_payload["recommended_specialist"] = recommended_specialist

        consultation.summary = json.dumps(summary_payload)
        consultation.intake_complete = True
        db.commit()
        db.refresh(consultation)

        return ConsultationService.get_summary(db, consultation.consultation_id)

    @staticmethod
    def update_location(
        db: Session,
        identifier: str,
        latitude: str,
        longitude: str
    ) -> Optional[ConsultationSummaryResponse]:
        """Updates location for a consultation."""
        consultation = (
            db.query(Consultation)
            .filter(
                (Consultation.consultation_id == identifier)
                | (Consultation.session_id == identifier)
            )
            .first()
        )
        if not consultation:
            return None

        consultation.latitude = latitude
        consultation.longitude = longitude
        
        db.commit()
        db.refresh(consultation)

        return ConsultationService.get_summary(db, consultation.consultation_id)
