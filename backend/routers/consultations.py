"""
Consultation endpoints for HealthCall AI.
Handles session initialization (logged-in vs guest), message exchanges,
state progression, emergency flagging, and summary generation.
"""
from fastapi import APIRouter, HTTPException, status
from models import (
    CreateSessionRequest,
    ConsultationSession,
    MessageRequest,
    MessageResponse,
    ConsultationSummary,
    ChatMessage,
    MessageRole,
    ConsultationStatus,
)
from session_store import create_session, get_session, update_session
from gemini_client import process_consultation_turn
from datetime import datetime

router = APIRouter(prefix="/api/consultations", tags=["Consultations"])


@router.post("", response_model=dict)
async def start_consultation(req: CreateSessionRequest):
    """
    Creates a new consultation session.
    - If patient_id / auth_token provided: loads patient profile, skips personal info questions.
    - If None: starts as guest consultation.
    Returns initial greeting tailored to context.
    """
    session = create_session(patient_id=req.patient_id)

    # Prepare welcoming opening message from AI
    if not session.is_guest and session.patient:
        first_name = session.patient.name.split()[0]
        initial_msg = (
            f"Hi {first_name} 👋 I'm your HealthCall AI assistant.\n"
            f"What health problem or symptoms are you experiencing today?"
        )
    else:
        initial_msg = (
            "Hello! I am your HealthCall AI Assistant.\n"
            "Before we begin your health consultation, may I know your name?"
        )

    ai_greeting = ChatMessage(
        role=MessageRole.ai,
        content=initial_msg,
        timestamp=datetime.utcnow(),
        language="en",
    )
    session.messages.append(ai_greeting)
    update_session(session)

    return {
        "session_id": session.session_id,
        "is_guest": session.is_guest,
        "initial_message": initial_msg,
        "status": session.status.value,
        "intake_data": session.intake_data.model_dump(),
    }


@router.post("/{session_id}/messages", response_model=MessageResponse)
async def send_message(session_id: str, req: MessageRequest):
    session = get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultation session not found",
        )

    # 1. Record patient's incoming message
    patient_msg = ChatMessage(
        role=MessageRole.patient,
        content=req.message,
        timestamp=datetime.utcnow(),
        language=req.language or "en",
    )
    session.messages.append(patient_msg)

    # 2. Process turn via Gemini engine (or fallback)
    turn_result = await process_consultation_turn(
        session=session,
        user_message=req.message,
        language_hint=req.language,
    )

    response_text = turn_result.get("response_text", "Could you tell me more about your symptoms?")
    lang = turn_result.get("language", "en")

    # 3. Record AI's response message
    ai_msg = ChatMessage(
        role=MessageRole.ai,
        content=response_text,
        timestamp=datetime.utcnow(),
        language=lang,
    )
    session.messages.append(ai_msg)

    update_session(session)

    return MessageResponse(
        session_id=session.session_id,
        response_text=response_text,
        language=lang,
        extracted_data=session.intake_data,
        missing_fields=turn_result.get("missing_fields", []),
        should_flag_emergency=session.intake_data.should_flag_emergency,
        intake_complete=session.intake_data.intake_complete,
        status=session.status,
    )


@router.get("/{session_id}", response_model=dict)
async def get_session_details(session_id: str):
    session = get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultation session not found",
        )
    return session.model_dump()


@router.get("/{session_id}/summary", response_model=ConsultationSummary)
async def get_summary(session_id: str):
    session = get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultation session not found",
        )

    intake = session.intake_data
    patient_name = (
        session.patient.name
        if session.patient
        else (intake.name or "Guest Patient")
    )
    age = session.patient.age if session.patient else intake.age
    gender = session.patient.gender if session.patient else intake.gender

    return ConsultationSummary(
        session_id=session.session_id,
        patient_name=patient_name,
        age=age,
        gender=gender,
        chief_complaint=intake.chief_complaint or "Unspecified",
        symptoms=intake.symptoms if intake.symptoms else ["Unspecified"],
        duration=intake.duration or "Not provided",
        severity=intake.severity or "Unknown",
        language=intake.preferred_language,
        emergency=intake.should_flag_emergency,
        completed_at=datetime.utcnow(),
    )


@router.post("/{session_id}/complete")
async def complete_consultation(session_id: str):
    session = get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultation session not found",
        )
    session.status = ConsultationStatus.completed
    session.intake_data.intake_complete = True
    update_session(session)
    return {"message": "Consultation marked as completed", "session_id": session_id}


@router.post("/{session_id}/emergency")
async def trigger_emergency(session_id: str):
    session = get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultation session not found",
        )
    session.status = ConsultationStatus.emergency
    session.intake_data.should_flag_emergency = True
    update_session(session)
    return {"message": "Emergency alert triggered", "session_id": session_id}
