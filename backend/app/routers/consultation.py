"""
Consultation router for HealthCall AI.
Provides AI-driven medical intake, conversation turn processing, and SQLite persistence.
"""
import uuid
import json
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database.database import get_db
from ..models.patient import Patient
from ..models.consultation import Consultation
from ..models.consultation_message import ConsultationMessage
from ..schemas.consultation import (
    StartConsultationRequest,
    SendMessageRequest,
    ConsultationSummaryResponse,
    ConsultationSummaryUpdateRequest,
    ExtractedIntakeData,
)
from ..services.consultation_service import ConsultationService
from ..dependencies.auth import get_current_user

# Import Gemini engine from existing backend/gemini_client
import sys
import os
from gemini_client import process_consultation_turn
from models import ConsultationSession, ExtractedIntakeData as GeminiIntakeData, ChatMessage, MessageRole, PatientProfile

router = APIRouter(prefix="/api/consultations", tags=["Consultation"])

# In-memory runtime session cache for active Gemini turns
_ACTIVE_SESSIONS = {}


@router.post("", response_model=dict)
def start_consultation(
    req: StartConsultationRequest,
    db: Session = Depends(get_db),
):
    """
    Initializes a new consultation session.
    If patient_id is present (logged in), demographic details are pre-loaded from SQLite
    so the AI never asks for Name, Age, Phone, or Email.
    """
    session_id = f"sess_{uuid.uuid4().hex[:10]}"
    patient_profile = None
    is_guest = True

    if req.patient_id:
        patient = db.query(Patient).filter(Patient.patient_id == req.patient_id).first()
        if patient:
            is_guest = False
            patient_profile = PatientProfile(
                patient_id=patient.patient_id,
                name=patient.name,
                age=patient.age,
                gender=patient.gender,
                phone=patient.phone,
                email=patient.email,
                emergency_contact=patient.emergency_contact,
            )

    # Create record in SQLite consultations table
    consultation = ConsultationService.get_or_create_consultation(
        db=db,
        session_id=session_id,
        patient_id=patient_profile.patient_id if patient_profile else None,
    )

    # Initialize Gemini session
    gemini_session = ConsultationSession(
        session_id=session_id,
        patient_id=patient_profile.patient_id if patient_profile else None,
        is_guest=is_guest,
        patient=patient_profile,
    )

    if not is_guest and patient_profile:
        # Pre-fill demographic data in intake so AI knows it's already recorded
        gemini_session.intake_data.name = patient_profile.name
        gemini_session.intake_data.age = patient_profile.age
        gemini_session.intake_data.gender = patient_profile.gender
        gemini_session.intake_data.phone = patient_profile.phone
        gemini_session.intake_data.email = patient_profile.email

    user_lang = (req.language or "en").lower().split('_')[0].split('-')[0]
    gemini_session.intake_data.preferred_language = user_lang
    _ACTIVE_SESSIONS[session_id] = gemini_session

    p_first = patient_profile.name.split()[0] if (patient_profile and patient_profile.name) else "Patient"

    if user_lang == "ta":
        initial_greeting = (
            f"வணக்கம் {p_first} 👋 நான் உங்கள் HealthCall AI மருத்துவ உதவியாளர்.\nஉங்களுக்கு இன்று என்ன உடல்நல பிரச்சனை அல்லது அறிகுறிகள் உள்ளன?"
            if not is_guest
            else "வணக்கம்! நான் உங்கள் HealthCall AI மருத்துவ உதவியாளர்.\nஆரம்பிக்க உங்கள் பெயரைத் தெரிவிக்க முடியுமா?"
        )
    elif user_lang == "hi":
        initial_greeting = (
            f"नमस्ते {p_first} 👋 मैं आपका HealthCall AI सहायक हूँ।\nआज आपको क्या स्वास्थ्य समस्या या लक्षण महसूस हो रहे हैं?"
            if not is_guest
            else "नमस्ते! मैं आपका HealthCall AI सहायक हूँ।\nशुरू करने से पहले क्या मैं आपका नाम जान सकता हूँ?"
        )
    elif user_lang == "kn":
        initial_greeting = (
            f"ನಮಸ್ಕಾರ {p_first} 👋 ನಾನು ನಿಮ್ಮ HealthCall AI ಸಹಾಯಕ.\nಇಂದು ನಿಮಗೆ ಯಾವ ಆರೋಗ್ಯ ಸಮಸ್ಯೆ ಅಥವಾ ಲಕ್ಷಣಗಳು ಕಾಣಿಸಿಕೊಂಡಿವೆ?"
            if not is_guest
            else "ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ HealthCall AI ಸಹಾಯಕ.\nಪ್ರಾರಂಭಿಸುವ ಮೊದಲು ನಿಮ್ಮ ಹೆಸರನ್ನು ತಿಳಿಸಬಹುದೇ?"
        )
    elif user_lang == "te":
        initial_greeting = (
            f"నమస్కారం {p_first} 👋 నేను మీ HealthCall AI అసిస్టెంట్.\nఈరోజు మీకు ఎలాంటి ఆరోగ్య సమస్య లేదా లక్షణాలు ఉన్నాయి?"
            if not is_guest
            else "నమస్కారం! నేను మీ HealthCall AI అసిస్టెంట్.\nమొదలుపెట్టే ముందు మీ పేరు తెలుసుకోవచ్చా?"
        )
    elif user_lang == "ml":
        initial_greeting = (
            f"നമസ്കാരം {p_first} 👋 ഞാൻ നിങ്ങളുടെ HealthCall AI അസിസ്റ്റന്റ്.\nഇന്ന് നിങ്ങൾക്ക് എന്തെങ്കിലും ആരോഗ്യ പ്രശ്നങ്ങളോ ലക്ഷണങ്ങളോ ഉണ്ടോ?"
            if not is_guest
            else "നമസ്കാരം! ഞാൻ നിങ്ങളുടെ HealthCall AI അസിസ്റ്റന്റ്.\nതുടങ്ങുന്നതിന് മുമ്പ് നിങ്ങളുടെ പേര് അറിയാമോ?"
        )
    elif user_lang == "bn":
        initial_greeting = (
            f"নমস্কার {p_first} 👋 আমি আপনার HealthCall AI সহকারী।\nআজ আপনার কি স্বাস্থ্য সমস্যা দেখা দিচ্ছে?"
            if not is_guest
            else "নমস্কার! আমি আপনার HealthCall AI সহকারী।\nশুরু করার আগে আপনার নাম জানতে পারি?"
        )
    elif user_lang == "mr":
        initial_greeting = (
            f"नमस्कार {p_first} 👋 मी तुमचा HealthCall AI सहाय्यक आहे.\nआज तुम्हाला काय आरोग्याच्या तक्रары जाणवत आहेत?"
            if not is_guest
            else "नमस्कार! मी तुमचा HealthCall AI सहाय्यक आहे.\nसुरुवात करण्यापूर्वी आपले नाव जाणून घेऊ शकतो का?"
        )
    else:
        initial_greeting = (
            f"Hi {p_first} 👋 I'm your HealthCall AI assistant.\nWhat health problem or symptoms are you experiencing today?"
            if not is_guest
            else "Hello! I am your HealthCall AI Assistant.\nBefore we begin your health consultation, may I know your name?"
        )

    # Save initial system greeting to SQLite
    ConsultationService.save_message(
        db=db,
        consultation_id=consultation.consultation_id,
        role="AI",
        message=initial_greeting,
        language=user_lang,
    )

    return {
        "session_id": session_id,
        "consultation_id": consultation.consultation_id,
        "is_guest": is_guest,
        "language": user_lang,
        "initial_message": initial_greeting,
        "status": "active",
        "intake_data": {
            "name": patient_profile.name if patient_profile else None,
            "age": patient_profile.age if patient_profile else None,
            "gender": patient_profile.gender if patient_profile else None,
            "phone": patient_profile.phone if patient_profile else None,
            "email": patient_profile.email if patient_profile else None,
        },
    }


@router.post("/{session_id}/messages")
async def send_message(
    session_id: str,
    req: SendMessageRequest,
    db: Session = Depends(get_db),
):
    """
    Processes a conversational turn with Gemini AI and stores conversation and extracted intake in SQLite.
    """
    # 1. Retrieve or re-create session in cache
    session = _ACTIVE_SESSIONS.get(session_id)
    consultation = (
        db.query(Consultation).filter(Consultation.session_id == session_id).first()
    )
    if not consultation:
        consultation = ConsultationService.get_or_create_consultation(db, session_id)

    if not session:
        # Reconstruct session from database if server restarted
        patient = None
        if consultation.patient_id:
            db_patient = db.query(Patient).filter(Patient.patient_id == consultation.patient_id).first()
            if db_patient:
                patient = PatientProfile(
                    patient_id=db_patient.patient_id,
                    name=db_patient.name,
                    age=db_patient.age,
                    gender=db_patient.gender,
                    phone=db_patient.phone,
                    email=db_patient.email,
                )
        session = ConsultationSession(
            session_id=session_id,
            patient_id=consultation.patient_id,
            is_guest=consultation.patient_id is None,
            patient=patient,
        )
        _ACTIVE_SESSIONS[session_id] = session

    # 2. Save user message to SQLite
    ConsultationService.save_message(
        db=db,
        consultation_id=consultation.consultation_id,
        role="USER",
        message=req.message,
        language=req.language or "en",
    )

    # 3. Add to session memory
    session.messages.append(
        ChatMessage(role=MessageRole.patient, content=req.message, language=req.language)
    )

    # 4. Call Gemini engine
    turn_response = await process_consultation_turn(
        session=session,
        user_message=req.message,
        language_hint=req.language,
    )

    # 5. Save AI response message to SQLite
    ai_text = turn_response.get("response_text", "")
    ConsultationService.save_message(
        db=db,
        consultation_id=consultation.consultation_id,
        role="AI",
        message=ai_text,
        language=turn_response.get("language", "en"),
    )

    # 6. Update SQLite consultation record with extracted intake
    extracted = turn_response.get("extracted_data", {})
    intake_data = ExtractedIntakeData(
        chief_complaint=extracted.get("chief_complaint"),
        symptoms=extracted.get("symptoms", []),
        duration=extracted.get("duration"),
        severity=extracted.get("severity"),
        preferred_language=turn_response.get("language", "en"),
        should_flag_emergency=turn_response.get("should_flag_emergency", False),
        intake_complete=turn_response.get("intake_complete", False),
        clinical_summary=extracted.get("clinical_summary"),
        recommended_specialist=extracted.get("recommended_specialist"),
        key_observations=extracted.get("key_observations", []),
        preliminary_guidance=extracted.get("preliminary_guidance"),
        triage_level=extracted.get("triage_level", "Routine"),
    )
    ConsultationService.update_intake_data(db, session_id, intake_data)

    return turn_response


@router.get("/{consultation_id}/summary", response_model=ConsultationSummaryResponse)
def get_consultation_summary(
    consultation_id: str,
    db: Session = Depends(get_db),
):
    """
    Retrieves the structured consultation summary stored in SQLite.
    """
    summary = ConsultationService.get_summary(db, consultation_id)
    if not summary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Consultation {consultation_id} not found.",
        )
    return summary


@router.put("/{consultation_id}/summary", response_model=ConsultationSummaryResponse)
def update_consultation_summary(
    consultation_id: str,
    req: ConsultationSummaryUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    Updates the structured consultation summary with patient edits.
    """
    updated = ConsultationService.update_summary(
        db=db,
        identifier=consultation_id,
        chief_complaint=req.chief_complaint,
        symptoms=req.symptoms,
        duration=req.duration,
        severity=req.severity,
        clinical_summary=req.clinical_summary,
        recommended_specialist=req.recommended_specialist,
    )
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Consultation {consultation_id} not found.",
        )
    return updated


@router.get("", response_model=List[ConsultationSummaryResponse])
def get_my_consultations(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lists past consultation summaries for the authenticated patient.
    """
    user_id = current_user["user_id"]
    consultations = (
        db.query(Consultation)
        .filter(Consultation.patient_id == user_id)
        .order_by(Consultation.created_at.desc())
        .all()
    )

    results = []
    for c in consultations:
        summary = ConsultationService.get_summary(db, c.consultation_id)
        if summary:
            results.append(summary)
    return results
