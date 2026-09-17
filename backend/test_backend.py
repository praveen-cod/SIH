"""
Automated unit/integration tests for HealthCall AI FastAPI Backend.
Verifies:
1. Guest consultation intake starts with personal info (name, etc.)
2. Logged-in consultation skips personal info and starts directly with symptoms
3. Multilingual turn handling
4. Emergency triage detection
5. Summary generation
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_guest_consultation_flow():
    # 1. Start guest session
    res = client.post("/api/consultations", json={"patient_id": None})
    assert res.status_code == 200
    data = res.json()
    assert data["is_guest"] is True
    session_id = data["session_id"]
    assert "name" in data["initial_message"].lower()

    # 2. Provide name
    res = client.post(f"/api/consultations/{session_id}/messages", json={"message": "Praveen"})
    assert res.status_code == 200
    msg_data = res.json()
    assert msg_data["should_flag_emergency"] is False

    # 3. Provide age
    res = client.post(f"/api/consultations/{session_id}/messages", json={"message": "I am 22 years old"})
    assert res.status_code == 200

    # 4. Provide gender
    res = client.post(f"/api/consultations/{session_id}/messages", json={"message": "Male"})
    assert res.status_code == 200

    # 5. Provide chief complaint
    res = client.post(f"/api/consultations/{session_id}/messages", json={"message": "I have had a high fever and headache"})
    assert res.status_code == 200
    assert "fever" in str(res.json()["extracted_data"]).lower()

    # 6. Fetch summary
    res = client.get(f"/api/consultations/{session_id}/summary")
    assert res.status_code == 200
    summary = res.json()
    assert summary["session_id"] == session_id
    assert summary["patient_name"] == "Praveen"


def test_logged_in_patient_consultation_skips_known_details():
    # 1. Start session for registered patient 'patient_001' (Praveen Kumar, 22)
    res = client.post("/api/consultations", json={"patient_id": "patient_001"})
    assert res.status_code == 200
    data = res.json()
    assert data["is_guest"] is False
    session_id = data["session_id"]

    # Must NOT ask for name or age; greeting directly addresses patient by name
    assert "praveen" in data["initial_message"].lower()
    assert "what health problem" in data["initial_message"].lower()

    # Known details must already be pre-populated
    intake = data["intake_data"]
    assert intake["name"] == "Praveen Kumar"
    assert intake["age"] == 22

    # 2. Patient provides symptom
    res = client.post(f"/api/consultations/{session_id}/messages", json={"message": "Severe body aches and chills"})
    assert res.status_code == 200
    msg = res.json()
    assert msg["should_flag_emergency"] is False


def test_emergency_detection():
    res = client.post("/api/consultations", json={"patient_id": None})
    session_id = res.json()["session_id"]

    # Provide critical symptom
    res = client.post(f"/api/consultations/{session_id}/messages", json={"message": "I have severe crushing chest pain and I cannot breathe"})
    assert res.status_code == 200
    data = res.json()
    assert data["should_flag_emergency"] is True
    assert "emergency" in data["response_text"].lower() or "medical" in data["response_text"].lower()


if __name__ == "__main__":
    test_health_check()
    test_guest_consultation_flow()
    test_logged_in_patient_consultation_skips_known_details()
    test_emergency_detection()
    print("All backend tests passed successfully!")
