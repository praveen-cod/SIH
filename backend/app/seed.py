"""
Database Seeding Script for HealthCall AI.
Seeds initial Admin, Active Doctors across specializations, Availability Slots, and Staff.
"""
from sqlalchemy.orm import Session
from .database.database import engine, Base, SessionLocal
from .models.admin import Admin
from .models.doctor import Doctor
from .models.staff import Staff
from .models.patient import Patient
from .models.availability import DoctorAvailability
from .services.auth_service import get_password_hash


def seed_database(db: Session):
    """Populates the SQLite database with initial development and clinical data."""
    # Ensure all tables exist
    Base.metadata.create_all(bind=engine)

    # 1. Seed Admin
    existing_admin = db.query(Admin).filter(Admin.email == "admin@healthcall.ai").first()
    if not existing_admin:
        admin = Admin(
            admin_id="HC-A-101",
            name="Platform Administrator",
            email="admin@healthcall.ai",
            password_hash=get_password_hash("Admin@1234"),
            status="ACTIVE",
        )
        db.add(admin)

    # Seed Admin with demo email for fallback convenience
    demo_admin = db.query(Admin).filter(Admin.email == "admin@demo.com").first()
    if not demo_admin:
        admin2 = Admin(
            admin_id="HC-A-102",
            name="System Admin",
            email="admin@demo.com",
            password_hash=get_password_hash("Demo@1234"),
            status="ACTIVE",
        )
        db.add(admin2)

    # 2. Seed Default Patient
    existing_patient = db.query(Patient).filter(Patient.email == "patient@demo.com").first()
    if not existing_patient:
        patient = Patient(
            patient_id="HC-P-10001",
            name="Praveen Kumar",
            age=22,
            gender="Male",
            phone="+91 9876543210",
            emergency_contact="+91 9123456789",
            email="patient@demo.com",
            password_hash=get_password_hash("Demo@1234"),
            is_active=True,
        )
        db.add(patient)

    # 3. Seed Doctors
    doctors_data = [
        {
            "id": "HC-D-1001",
            "name": "Dr. Arun Kumar",
            "email": "doctor@demo.com",
            "phone": "+91 9876500001",
            "password": "Demo@1234",
            "specialization": "General Physician",
            "qualification": "MBBS, MD (Internal Medicine)",
            "experience": 10,
            "license": "MCI-482910",
            "dept": "General Medicine",
        },
        {
            "id": "HC-D-1002",
            "name": "Dr. Priya Sharma",
            "email": "priya@healthcall.ai",
            "phone": "+91 9876500002",
            "password": "Demo@1234",
            "specialization": "Cardiologist",
            "qualification": "MBBS, DM (Cardiology)",
            "experience": 8,
            "license": "MCI-591024",
            "dept": "Cardiology",
        },
        {
            "id": "HC-D-1003",
            "name": "Dr. Vikram Mehta",
            "email": "vikram@healthcall.ai",
            "phone": "+91 9876500003",
            "password": "Demo@1234",
            "specialization": "Dermatologist",
            "qualification": "MBBS, MD (Dermatology)",
            "experience": 12,
            "license": "MCI-382914",
            "dept": "Dermatology",
        },
        {
            "id": "HC-D-1004",
            "name": "Dr. Ananya Roy",
            "email": "ananya@healthcall.ai",
            "phone": "+91 9876500004",
            "password": "Demo@1234",
            "specialization": "Pediatrician",
            "qualification": "MBBS, MD (Pediatrics)",
            "experience": 7,
            "license": "MCI-718290",
            "dept": "Pediatrics",
        },
        {
            "id": "HC-D-1005",
            "name": "Dr. Rajesh Patel",
            "email": "rajesh@healthcall.ai",
            "phone": "+91 9876500005",
            "password": "Demo@1234",
            "specialization": "Orthopedic",
            "qualification": "MBBS, MS (Orthopedics)",
            "experience": 15,
            "license": "MCI-192837",
            "dept": "Orthopedics",
        },
        {
            "id": "HC-D-1006",
            "name": "Dr. Sneha Verma",
            "email": "sneha@healthcall.ai",
            "phone": "+91 9876500006",
            "password": "Demo@1234",
            "specialization": "ENT",
            "qualification": "MBBS, MS (ENT)",
            "experience": 6,
            "license": "MCI-629104",
            "dept": "Otorhinolaryngology",
        },
    ]

    for d in doctors_data:
        existing_doc = db.query(Doctor).filter(Doctor.email == d["email"]).first()
        if not existing_doc:
            doc = Doctor(
                doctor_id=d["id"],
                name=d["name"],
                email=d["email"],
                phone=d["phone"],
                password_hash=get_password_hash(d["password"]),
                specialization=d["specialization"],
                qualification=d["qualification"],
                experience=d["experience"],
                license_number=d["license"],
                department=d["dept"],
                status="ACTIVE",
            )
            db.add(doc)

    # 4. Seed Staff
    staff_data = [
        {"id": "HC-S-101", "name": "Sister Mary John", "email": "mary@healthcall.ai", "phone": "+91 9876510001", "role": "Head Nurse", "dept": "OPD"},
        {"id": "HC-S-102", "name": "Kavita Nair", "email": "kavita@healthcall.ai", "phone": "+91 9876510002", "role": "Triage Officer", "dept": "Emergency"},
        {"id": "HC-S-103", "name": "Rahul Deshmukh", "email": "rahul@healthcall.ai", "phone": "+91 9876510003", "role": "Receptionist", "dept": "Front Desk"},
    ]
    for s in staff_data:
        if not db.query(Staff).filter(Staff.email == s["email"]).first():
            staff = Staff(
                staff_id=s["id"],
                name=s["name"],
                email=s["email"],
                phone=s["phone"],
                role=s["role"],
                department=s["dept"],
                status="ACTIVE",
            )
            db.add(staff)

    db.commit()

    # 5. Seed Doctor Availability Slots
    # Dr. Arun Kumar slots for 30 Aug 2026 and upcoming dates
    arun_slots = [
        ("30 Aug 2026", "09:00 AM", "09:30 AM"),
        ("30 Aug 2026", "09:30 AM", "10:00 AM"),
        ("30 Aug 2026", "10:00 AM", "10:30 AM"),
        ("30 Aug 2026", "10:30 AM", "11:00 AM"),
        ("30 Aug 2026", "11:00 AM", "11:30 AM"),
        ("31 Aug 2026", "10:00 AM", "10:30 AM"),
        ("31 Aug 2026", "10:30 AM", "11:00 AM"),
        ("01 Sep 2026", "02:00 PM", "02:30 PM"),
    ]
    for date_str, start, end in arun_slots:
        existing_slot = (
            db.query(DoctorAvailability)
            .filter(
                DoctorAvailability.doctor_id == "HC-D-1001",
                DoctorAvailability.date == date_str,
                DoctorAvailability.start_time == start,
            )
            .first()
        )
        if not existing_slot:
            db.add(
                DoctorAvailability(
                    doctor_id="HC-D-1001",
                    date=date_str,
                    start_time=start,
                    end_time=end,
                    status="AVAILABLE",
                    created_by="HC-A-101",
                )
            )

    # Dr. Priya Sharma slots (Cardiologist)
    priya_slots = [
        ("30 Aug 2026", "11:30 AM", "12:00 PM"),
        ("30 Aug 2026", "02:00 PM", "02:30 PM"),
        ("31 Aug 2026", "09:30 AM", "10:00 AM"),
    ]
    for date_str, start, end in priya_slots:
        if not db.query(DoctorAvailability).filter(DoctorAvailability.doctor_id == "HC-D-1002", DoctorAvailability.date == date_str, DoctorAvailability.start_time == start).first():
            db.add(DoctorAvailability(doctor_id="HC-D-1002", date=date_str, start_time=start, end_time=end, status="AVAILABLE", created_by="HC-A-101"))

    # Dr. Vikram Mehta slots (Dermatologist)
    vikram_slots = [
        ("30 Aug 2026", "10:00 AM", "10:30 AM"),
        ("30 Aug 2026", "04:00 PM", "04:30 PM"),
    ]
    for date_str, start, end in vikram_slots:
        if not db.query(DoctorAvailability).filter(DoctorAvailability.doctor_id == "HC-D-1003", DoctorAvailability.date == date_str, DoctorAvailability.start_time == start).first():
            db.add(DoctorAvailability(doctor_id="HC-D-1003", date=date_str, start_time=start, end_time=end, status="AVAILABLE", created_by="HC-A-101"))

    db.commit()
    print("HealthCall AI SQLite database seeded successfully!")


if __name__ == "__main__":
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()
