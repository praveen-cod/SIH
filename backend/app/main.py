"""
HealthCall AI - FastAPI Backend Server
Integrated with local SQLite database via SQLAlchemy, JWT Authentication,
Gemini AI Medical Intake, Doctor Specialization Matching, and Transactional Booking.
"""
import sys
import os
from contextlib import asynccontextmanager

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database.database import engine, Base, SessionLocal
from app.seed import seed_database
from app.routers import auth, patient, consultation, appointment, doctor, admin


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize SQLite tables and seed data
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()
    yield


app = FastAPI(
    title="HealthCall AI - Healthcare Platform API",
    description="Real SQLite + FastAPI backend for HealthCall AI (Patient, Doctor, Admin clinical workflows).",
    version="2.0.0",
    lifespan=lifespan,
)

# Enable CORS for Flutter Web, Mobile emulators, and local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(patient.router)
app.include_router(consultation.router)
app.include_router(appointment.router)
app.include_router(doctor.router)
app.include_router(admin.router)


@app.get("/")
async def root():
    return {
        "status": "online",
        "service": "HealthCall AI Core API",
        "database": "SQLite (healthcall.db)",
        "version": "2.0.0",
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy", "database": "connected"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
