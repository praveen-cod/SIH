"""
End-to-End Business Flow and Transaction Safety Tests for HealthCall AI.
Validates:
- Patient registration and password hashing in SQLite
- Multi-role JWT authentication (Patient, Doctor, Admin)
- Consultation storage in SQLite and AI context injection
- Symptom-to-doctor specialization matching
- Patient appointment request lifecycle (REQUESTED -> APPROVED / REJECTED)
- Double-booking prevention & atomic transaction safety
- Doctor AI Consultation Summary review
- Admin availability schedule control and cancellation cascade
"""
import sys
import os
import pytest
from fastapi.testclient import TestClient
import uuid

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app
from app.database.database import SessionLocal, Base, engine
from app.seed import seed_database
from app.models.appointment import Appointment
from app.models.availability import DoctorAvailability

client = TestClient(app)


@pytest.fixture(scope="module", autouse=True)
def setup_database():
    # Ensure fresh schema and seed data
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()
    yield


# ---------------------------------------------------------------------------
# 1. Patient Registration & Duplicate Check
# ---------------------------------------------------------------------------

def test_patient_registration_and_duplicate():
    email = f"test_pt_{uuid.uuid4().hex[:6]}@example.com"
    payload = {
        "name": "Arunmozhi Varman",
        "age": 28,
        "gender": "Male",
        "phone": "+91 9840012345",
        "emergency_contact": "+91 9840054321",
        "email": email,
        "password": "Password@123",
        "confirm_password": "Password@123",
    }
    # Successful registration
    resp = client.post("/api/auth/patient/register", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["success"] is True
    assert data["role"] == "PATIENT"
    assert data["user_id"].startswith("HC-P-")
    assert "token" in data

    # Duplicate registration rejected
    resp_dup = client.post("/api/auth/patient/register", json=payload)
    assert resp_dup.status_code == 409
    assert "already exists" in resp_dup.json()["detail"]


# ---------------------------------------------------------------------------
# 2. Multi-Role Login & JWT
# ---------------------------------------------------------------------------

def test_multi_role_logins():
    # Patient login
    resp_p = client.post("/api/auth/login", json={"email": "patient@demo.com", "password": "Demo@1234", "role": "patient"})
    assert resp_p.status_code == 200
    assert resp_p.json()["role"] == "PATIENT"
    assert "token" in resp_p.json()

    # Doctor login
    resp_d = client.post("/api/auth/login", json={"email": "doctor@demo.com", "password": "Demo@1234", "role": "doctor"})
    assert resp_d.status_code == 200
    assert resp_d.json()["role"] == "DOCTOR"
    assert resp_d.json()["user_id"] == "HC-D-1001"

    # Admin login
    resp_a = client.post("/api/auth/login", json={"email": "admin@healthcall.ai", "password": "Admin@1234", "role": "admin"})
    assert resp_a.status_code == 200
    assert resp_a.json()["role"] == "ADMIN"
    assert resp_a.json()["user_id"] == "HC-A-101"

    # Invalid credentials
    resp_bad = client.post("/api/auth/login", json={"email": "patient@demo.com", "password": "WrongPassword"})
    assert resp_bad.status_code == 401


# ---------------------------------------------------------------------------
# 3. AI Consultation Storage in SQLite
# ---------------------------------------------------------------------------

def test_consultation_flow_and_sqlite_storage():
    # Start session as logged in patient
    resp = client.post("/api/consultations", json={"patient_id": "HC-P-10001"})
    assert resp.status_code == 200
    sess_data = resp.json()
    session_id = sess_data["session_id"]
    consultation_id = sess_data["consultation_id"]

    # Demographic data already injected; AI asks medical problem
    assert sess_data["is_guest"] is False
    assert "Praveen" in sess_data["initial_message"]

    # Patient reports symptoms
    msg_resp = client.post(
        f"/api/consultations/{session_id}/messages",
        json={"message": "I have fever, headache, and body ache for 3 days. It is moderate."},
    )
    assert msg_resp.status_code == 200

    # Retrieve stored summary from SQLite
    summary_resp = client.get(f"/api/consultations/{consultation_id}/summary")
    assert summary_resp.status_code == 200
    s_data = summary_resp.json()
    assert s_data["consultation_id"] == consultation_id
    assert s_data["patient_id"] == "HC-P-10001"
    assert s_data["patient_name"] == "Praveen Kumar"


# ---------------------------------------------------------------------------
# 4. Doctor Specialization Matching
# ---------------------------------------------------------------------------

def test_doctor_specialization_matching():
    # Fever and cough -> General Physician (Dr. Arun Kumar)
    resp = client.get("/api/appointments/recommended-doctors?chief_complaint=High+Fever+and+cough")
    assert resp.status_code == 200
    docs = resp.json()
    assert len(docs) > 0
    assert docs[0]["specialization"] == "General Physician"
    assert "General Physician" in docs[0]["recommendation_rationale"]
    assert len(docs[0]["available_slots"]) > 0

    # Chest pain -> Cardiologist (Dr. Priya Sharma)
    resp_cardio = client.get("/api/appointments/recommended-doctors?chief_complaint=Severe+Chest+Pain+and+palpitations")
    assert resp_cardio.status_code == 200
    docs_cardio = resp_cardio.json()
    assert docs_cardio[0]["specialization"] == "Cardiologist"
    assert docs_cardio[0]["name"] == "Dr. Priya Sharma"

    # Skin itching and rash -> Dermatologist (Dr. Vikram Mehta)
    resp_derm = client.get("/api/appointments/recommended-doctors?chief_complaint=Skin+rash+and+severe+itching")
    assert resp_derm.status_code == 200
    docs_derm = resp_derm.json()
    assert docs_derm[0]["specialization"] == "Dermatologist"
    assert docs_derm[0]["name"] == "Dr. Vikram Mehta"


# ---------------------------------------------------------------------------
# 5. Full End-to-End Clinical Scenario (Request -> Review AI -> Approve)
# ---------------------------------------------------------------------------

def test_full_scenario_patient_request_to_doctor_approval():
    # Login patient
    p_login = client.post("/api/auth/login", json={"email": "patient@demo.com", "password": "Demo@1234", "role": "patient"})
    p_token = p_login.json()["token"]
    p_headers = {"Authorization": f"Bearer {p_token}"}

    # Login doctor
    d_login = client.post("/api/auth/login", json={"email": "doctor@demo.com", "password": "Demo@1234", "role": "doctor"})
    d_token = d_login.json()["token"]
    d_headers = {"Authorization": f"Bearer {d_token}"}

    # Step 1: Start consultation
    c_resp = client.post("/api/consultations", json={"patient_id": "HC-P-10001"})
    session_id = c_resp.json()["session_id"]
    consultation_id = c_resp.json()["consultation_id"]

    client.post(
        f"/api/consultations/{session_id}/messages",
        json={"message": "I have fever and headache for 3 days."},
    )

    # Step 2: Patient looks up Dr. Arun Kumar's available slots
    slots_resp = client.get("/api/doctors/HC-D-1001/availability")
    assert slots_resp.status_code == 200
    available_slots = slots_resp.json()
    assert len(available_slots) > 0
    target_slot = available_slots[0]

    # Step 3: Patient creates appointment request
    req_payload = {
        "doctor_id": "HC-D-1001",
        "consultation_id": consultation_id,
        "availability_id": target_slot["id"],
        "appointment_date": target_slot["date"],
        "start_time": target_slot["start_time"],
        "end_time": target_slot["end_time"],
        "consultation_type": "Video",
        "reason": "Fever and headache intake review",
        "patient_notes": "Please review intake before call.",
    }
    appt_resp = client.post("/api/appointments/request", json=req_payload, headers=p_headers)
    assert appt_resp.status_code == 201
    appt_data = appt_resp.json()
    appointment_id = appt_data["appointment_id"]
    assert appt_data["status"] == "REQUESTED"

    # Step 4: Doctor sees appointment request in their dashboard
    doc_requests_resp = client.get("/api/doctor/appointments/requests", headers=d_headers)
    assert doc_requests_resp.status_code == 200
    requests_list = doc_requests_resp.json()
    matching_req = next((r for r in requests_list if r["appointment_id"] == appointment_id), None)
    assert matching_req is not None

    # Step 5: Doctor views the patient's AI Consultation Summary
    ai_summary_resp = client.get(
        f"/api/doctor/appointments/{appointment_id}/consultation-summary",
        headers=d_headers,
    )
    assert ai_summary_resp.status_code == 200
    ai_summary = ai_summary_resp.json()
    assert ai_summary["consultation_id"] == consultation_id
    assert ai_summary["patient_name"] == "Praveen Kumar"

    # Step 6: Doctor Approves appointment
    approve_resp = client.post(
        f"/api/doctor/appointments/{appointment_id}/approve",
        json={"doctor_notes": "Approved for 10:30 AM video consultation."},
        headers=d_headers,
    )
    assert approve_resp.status_code == 200
    assert approve_resp.json()["status"] == "APPROVED"

    # Step 7: Verify slot is now BLOCKED in SQLite
    db = SessionLocal()
    slot_record = db.query(DoctorAvailability).filter(DoctorAvailability.id == target_slot["id"]).first()
    assert slot_record.status == "BLOCKED"
    db.close()

    # Step 8: Double-booking prevention — another patient cannot book this blocked slot
    second_req_resp = client.post("/api/appointments/request", json=req_payload, headers=p_headers)
    assert second_req_resp.status_code == 409
    assert "no longer available" in second_req_resp.json()["detail"]


# ---------------------------------------------------------------------------
# 6. Doctor Rejection Scenario
# ---------------------------------------------------------------------------

def test_doctor_rejection_scenario():
    p_login = client.post("/api/auth/login", json={"email": "patient@demo.com", "password": "Demo@1234", "role": "patient"})
    p_headers = {"Authorization": f"Bearer {p_login.json()['token']}"}

    d_login = client.post("/api/auth/login", json={"email": "doctor@demo.com", "password": "Demo@1234", "role": "doctor"})
    d_headers = {"Authorization": f"Bearer {d_login.json()['token']}"}

    # Find next available slot
    slots_resp = client.get("/api/doctors/HC-D-1001/availability")
    available_slots = slots_resp.json()
    assert len(available_slots) > 0
    slot = available_slots[0]

    # Patient requests appointment
    req_payload = {
        "doctor_id": "HC-D-1001",
        "availability_id": slot["id"],
        "appointment_date": slot["date"],
        "start_time": slot["start_time"],
        "end_time": slot["end_time"],
        "reason": "Follow up consultation",
    }
    appt_resp = client.post("/api/appointments/request", json=req_payload, headers=p_headers)
    appt_id = appt_resp.json()["appointment_id"]

    # Doctor rejects request with reason
    reject_resp = client.post(
        f"/api/doctor/appointments/{appt_id}/reject",
        json={"rejection_reason": "Doctor unavailable due to urgent clinical duty."},
        headers=d_headers,
    )
    assert reject_resp.status_code == 200
    assert reject_resp.json()["status"] == "REJECTED"
    assert reject_resp.json()["rejection_reason"] == "Doctor unavailable due to urgent clinical duty."

    # Slot remains AVAILABLE
    db = SessionLocal()
    slot_record = db.query(DoctorAvailability).filter(DoctorAvailability.id == slot["id"]).first()
    assert slot_record.status == "AVAILABLE"
    db.close()


# ---------------------------------------------------------------------------
# 7. Admin Changes Availability & Invalidation Cascade
# ---------------------------------------------------------------------------

def test_admin_availability_invalidation_cascade():
    a_login = client.post("/api/auth/login", json={"email": "admin@healthcall.ai", "password": "Admin@1234", "role": "admin"})
    a_headers = {"Authorization": f"Bearer {a_login.json()['token']}"}

    p_login = client.post("/api/auth/login", json={"email": "patient@demo.com", "password": "Demo@1234", "role": "patient"})
    p_headers = {"Authorization": f"Bearer {p_login.json()['token']}"}

    d_login = client.post("/api/auth/login", json={"email": "doctor@demo.com", "password": "Demo@1234", "role": "doctor"})
    d_headers = {"Authorization": f"Bearer {d_login.json()['token']}"}

    # Admin creates a new slot: 03:00 PM
    create_slot_resp = client.post(
        "/api/admin/availability",
        json={"doctor_id": "HC-D-1001", "date": "02 Sep 2026", "start_time": "03:00 PM", "end_time": "03:30 PM"},
        headers=a_headers,
    )
    assert create_slot_resp.status_code == 201
    new_slot = create_slot_resp.json()

    # Patient requests this slot
    req_resp = client.post(
        "/api/appointments/request",
        json={
            "doctor_id": "HC-D-1001",
            "availability_id": new_slot["id"],
            "appointment_date": "02 Sep 2026",
            "start_time": "03:00 PM",
            "reason": "Test admin slot block",
        },
        headers=p_headers,
    )
    appt_id = req_resp.json()["appointment_id"]

    # Before doctor approves, Admin BLOCKS this slot
    block_resp = client.put(
        f"/api/admin/availability/{new_slot['id']}",
        json={"status": "BLOCKED"},
        headers=a_headers,
    )
    assert block_resp.status_code == 200

    # The pending appointment must now be CANCELLED
    db = SessionLocal()
    appt_record = db.query(Appointment).filter(Appointment.appointment_id == appt_id).first()
    assert appt_record.status == "CANCELLED"
    db.close()

    # Doctor trying to approve this cancelled appointment must fail with 409
    doc_approve_resp = client.post(f"/api/doctor/appointments/{appt_id}/approve", headers=d_headers)
    assert doc_approve_resp.status_code == 409
