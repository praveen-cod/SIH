# 🏥 HealthCall AI - AI-Powered Healthcare Consultation & Appointment Platform

HealthCall AI is a modern, cross-platform telemedicine and clinical workflow platform designed to connect patients, doctors, and hospital administrators. It incorporates Google Gemini AI for smart voice-enabled triage and medical intake, automated doctor matching, appointment scheduling, and role-based access control.

---

## 📑 Table of Contents
1. [Overview & Key Features](#-overview--key-features)
2. [Full Technology Stack](#-full-technology-stack)
3. [Pubspec Dependencies (`pubspec.yaml`) & Detailed Usage](#-pubspec-dependencies-pubspecyaml--detailed-usage)
4. [Backend Technology & Dependencies (`requirements.txt`)](#-backend-technology--dependencies-requirementstxt)
5. [Architecture & Project Structure](#-architecture--project-structure)
6. [Environment Variables Configuration](#-environment-variables-configuration)
7. [Getting Started & Installation](#-getting-started--installation)
8. [API Endpoints Overview](#-api-endpoints-overview)

---

## 🌟 Overview & Key Features

- **🤖 AI Medical Intake & Voice Triage:** Conversational medical triage powered by Google Gemini AI with Speech-to-Text (STT) and Text-to-Speech (TTS) capabilities.
- **👨‍⚕️ Multi-Role Ecosystem:** Dedicated interfaces and workflows for **Patients**, **Doctors**, and **Administrators**.
- **📅 Dynamic Appointment Scheduling:** Real-time doctor availability checking, slot booking, rescheduling, and status management.
- **🩺 Clinical Notes & Prescription Management:** Doctors can issue diagnoses, write clinical notes, and manage consultation histories.
- **📊 Admin Insights & Analytics:** System-wide metrics, doctor verification, appointment tracking, and audit logs.
- **⚡ Reactive Architecture:** High-performance state management with Riverpod and decoupled REST communication via FastAPI.

---

## 🛠️ Full Technology Stack

### 1. Frontend (Mobile & Web)
- **Framework:** [Flutter](https://flutter.dev/) (Channel Stable, Dart SDK `^3.11.4`)
- **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Routing & Navigation:** [GoRouter](https://pub.dev/packages/go_router) (Declarative routing with deep linking)
- **Design System:** Material 3 with customized theme tokens, typography via [Google Fonts](https://fonts.google.com/), and animations with [flutter_animate](https://pub.dev/packages/flutter_animate).
- **Voice / Speech Engines:** `speech_to_text` (Microphone input recognition) & `flutter_tts` (Voice synthesis playback).
- **Networking:** Standard composable `http` client with centralized interceptors, token injection, and timeout handlers.

### 2. Backend API
- **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Python 3.10+)
- **Server:** [Uvicorn](https://www.uvicorn.org/) (Asynchronous ASGI server)
- **ORM / Database Layer:** [SQLAlchemy](https://www.sqlalchemy.org/) with [SQLite](https://www.sqlite.org/) (`healthcall.db`)
- **Data Validation & Serialization:** [Pydantic v2](https://docs.pydantic.dev/)
- **Authentication & Security:** JWT (JSON Web Tokens), OAuth2 password flows, `passlib` password hashing, and Cross-Origin Resource Sharing (CORS) middleware.

### 3. Artificial Intelligence & NLP
- **LLM Engine:** [Google Gemini API](https://ai.google.dev/) (`google-generativeai`)
- **Intake Pipeline:** Multi-turn conversational symptom analysis, risk assessment, urgency classification, and automated clinical summary generation.

---

## 📦 Pubspec Dependencies (`pubspec.yaml`) & Detailed Usage

Every dependency imported in [pubspec.yaml](file:///p:/CARE/pubspec.yaml) is chosen for high reliability, performance, and clean separation of concerns.

### 🔹 Core & UI Dependencies

| Package | Version | Purpose | Usage in Project |
| :--- | :--- | :--- | :--- |
| **`flutter`** | `sdk: flutter` | Core Flutter framework | Provides widgets, rendering engine, animation subsystems, and Material 3 design widgets. |
| **`cupertino_icons`** | `^1.0.8` | iOS Cupertino icon set | Provides crisp, cross-platform iconography alongside standard Material design icons. |
| **`google_fonts`** | `^6.2.1` | Typography & dynamic font loading | Loads clean, modern typefaces (such as *Plus Jakarta Sans* or *Inter*) without bundling heavy font binaries. |
| **`flutter_animate`** | `^4.5.0` | Declarative UI animations | Powers fluid entrance animations, card slide-ins, status pulses, and transitions across dashboards and cards. |

### 🔹 Architecture & State Management

| Package | Version | Purpose | Usage in Project |
| :--- | :--- | :--- | :--- |
| **`flutter_riverpod`** | `^2.6.1` | Reactive state management & DI | Manages user session state, consultation streams, appointments list, doctor availability, and dependency injection for repositories and API clients. |
| **`go_router`** | `^14.8.1` | Declarative routing & navigation | Handles app navigation, auth guard redirects (unauthenticated -> login), role-based screen routing, and URL deep-linking support for web and mobile. |
| **`equatable`** | `^2.0.7` | Value equality for Dart classes | Eliminates boilerplate code for comparing state and model instances (`AppointmentModel`, `UserModel`, `ConsultationSession`) based on field values rather than memory addresses. |

### 🔹 Networking, Storage & Environment

| Package | Version | Purpose | Usage in Project |
| :--- | :--- | :--- | :--- |
| **`http`** | `^1.6.0` | Composable HTTP REST client | Powers [api_client.dart](file:///p:/CARE/lib/core/network/api_client.dart) to execute GET, POST, PUT, DELETE requests against the FastAPI backend, inject Bearer JWT headers, and parse JSON payloads. |
| **`shared_preferences`** | `^2.3.5` | Persistent local key-value store | Stores authentication access tokens, refresh tokens, active user roles, and onboarding preferences persistently across app restarts. |
| **`flutter_dotenv`** | `^6.0.1` | `.env` file environment loader | Loads sensitive runtime configurations such as `API_BASE_URL`, `GEMINI_API_KEY`, and feature flags from the root `.env` file safely into memory. |
| **`uuid`** | `^4.5.1` | UUID generator | Generates unique IDs for client-side optimistic UI items, temporary consultation sessions, offline message keys, and transaction tracking. |
| **`intl`** | `^0.19.0` | Internationalization & date formatting | Formats appointment timestamps, doctor schedule slots, currency values, and calendar dates into readable localized formats. |

### 🔹 Voice & Speech (AI Telehealth)

| Package | Version | Purpose | Usage in Project |
| :--- | :--- | :--- | :--- |
| **`speech_to_text`** | `^7.4.0` | Real-time speech recognition (STT) | Listens to patient speech via device microphone and converts spoken symptoms and medical queries into text for the AI intake assistant. |
| **`flutter_tts`** | `^4.2.5` | Text-to-Speech synthesis (TTS) | Synthesizes Gemini AI's medical questions and triage advice into natural spoken voice responses for hands-free accessibility. |

### 🔹 Dev Dependencies

| Package | Version | Purpose | Usage in Project |
| :--- | :--- | :--- | :--- |
| **`flutter_test`** | `sdk: flutter` | Unit & widget testing library | Used to write component tests, widget interaction assertions, and repository unit tests. |
| **`flutter_lints`** | `^6.0.0` | Official Dart analysis rules | Enforces strict static analysis rules, clean code practices, and style consistency across the entire codebase. |

---

## 🐍 Backend Technology & Dependencies (`requirements.txt`)

The backend is built with Python and FastAPI, configured in [backend/requirements.txt](file:///p:/CARE/backend/requirements.txt):

| Package | Version | Description & Role |
| :--- | :--- | :--- |
| **`fastapi`** | `0.115.0` | Asynchronous modern web framework for building REST APIs with auto-generated OpenAPI / Swagger docs. |
| **`uvicorn[standard]`** | `0.30.6` | Lightning-fast ASGI web server with auto-reload capabilities for local development and production serving. |
| **`google-generativeai`**| `0.8.3` | Official Google SDK for accessing Gemini LLM models for medical symptom parsing and triage analysis. |
| **`python-dotenv`** | `1.0.1` | Reads key-value pairs from `.env` files and sets them as environment variables. |
| **`pydantic`** | `2.9.2` | Data validation, type enforcement, and request/response schema modeling. |
| **`httpx`** | `0.27.2` | Next-generation async HTTP client for external service interactions and backend testing. |
| **`sqlalchemy`** | - | Relational database ORM managing SQLite models, migrations, relationships, and queries. |

---

## 🏛️ Architecture & Project Structure

```
CARE/
├── android/                    # Native Android configurations & Gradle builds
├── ios/                        # Native iOS configurations & Xcode workspace
├── web/                        # Flutter Web entry point & assets
├── assets/                     # Icons, static images, and branding assets
├── .env                        # Local environment variables & API keys
├── pubspec.yaml                # Flutter project configuration & dependency list
│
├── lib/                        # Flutter Frontend Codebase
│   ├── main.dart               # App entrypoint (initializes Riverpod & theme)
│   ├── core/                   # Application Core Layer
│   │   ├── config/             # Environment configuration (env_config.dart)
│   │   ├── network/            # HTTP API Client & Interceptors (api_client.dart)
│   │   ├── routing/            # GoRouter configurations & Auth guards
│   │   └── theme/              # Color palette, Material 3 ThemeData, typography
│   ├── models/                 # Data Models (User, Appointment, Consultation, Doctor)
│   ├── repositories/           # Data Repositories (Abstraction over network & storage)
│   ├── services/               # Voice Services (TTS & STT), AI Service wrapper
│   ├── shared/                 # Reusable UI widgets (buttons, text fields, cards, loaders)
│   └── features/               # Feature-Driven Modules
│       ├── admin/              # Admin dashboard, doctor verification & metrics
│       ├── auth/               # Login, registration, role selection screens
│       ├── consultation/       # Live AI Voice consultation & chat interface
│       ├── doctor/             # Doctor dashboard, slot manager, patient notes
│       └── patient/            # Patient home, appointment booking, doctor search
│
└── backend/                    # FastAPI Backend Codebase
    ├── main.py                 # Backend entrypoint (uvicorn runner)
    ├── requirements.txt        # Python pip dependencies
    ├── gemini_client.py        # Gemini AI prompt orchestration & triage agent
    ├── healthcall.db           # SQLite database
    ├── app/
    │   ├── database/           # Database engine & base configuration
    │   ├── models/             # SQLAlchemy database entity models
    │   ├── schemas/            # Pydantic request & response schemas
    │   ├── routers/            # API Route handlers (auth, patient, doctor, admin, appointment)
    │   ├── services/           # Business logic & AI workflow handlers
    │   └── seed.py             # Database seeder with sample doctors, patients, and slots
    └── tests/                  # Backend unit and integration tests
```

---

## 🔐 Environment Variables Configuration

Create a `.env` file in the root directory (and `backend/.env` for backend specific configs):

```ini
# Frontend / General (.env)
API_BASE_URL=http://10.0.2.2:8000   # Use http://127.0.0.1:8000 for Web/iOS, 10.0.2.2 for Android Emulator
GEMINI_API_KEY=your_gemini_api_key_here
ENVIRONMENT=development

# Backend (backend/.env)
SECRET_KEY=your_super_secret_jwt_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
GEMINI_API_KEY=your_gemini_api_key_here
```

---

## 🚀 Getting Started & Installation

### 1. Prerequisites
- **Flutter SDK** (`>= 3.11.4`): [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Python** (`>= 3.10`): [Install Python](https://www.python.org/downloads/)
- **Git**

### 2. Backend Setup
```bash
# 1. Navigate to the backend directory
cd backend

# 2. Create and activate a virtual environment
python -m venv venv
# On Windows:
.\venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Start the FastAPI development server
python main.py
# Or run with uvicorn directly:
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
API Documentation will be live at `http://127.0.0.1:8000/docs`.

### 3. Frontend (Flutter App) Setup
```bash
# 1. Navigate to project root
cd ..

# 2. Fetch Flutter packages
flutter pub get

# 3. Verify connected devices
flutter devices

# 4. Run the application
flutter run
```

---

## 📡 API Endpoints Overview

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Register new user (Patient, Doctor, Admin) | Public |
| `POST` | `/api/auth/login` | Authenticate user & receive JWT Bearer token | Public |
| `GET` | `/api/patient/doctors` | Search and filter verified doctors | Authenticated |
| `POST` | `/api/consultation/intake` | Process AI voice triage with Gemini | Patient |
| `POST` | `/api/appointment/book` | Book an appointment slot | Patient |
| `GET` | `/api/doctor/appointments` | View scheduled patient appointments | Doctor |
| `PUT` | `/api/doctor/notes/{id}` | Update clinical notes & diagnosis | Doctor |
| `GET` | `/api/admin/metrics` | System analytics and consultation counts | Admin |

---

## 📄 License
This project is proprietary and intended for healthcare consultation workflows. All rights reserved.
"# SIH" 
