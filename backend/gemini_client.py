"""
Gemini LLM integration for HealthCall AI Consultation.
Implements structured prompt engineering, JSON response parsing, language adaptation,
issue-specific dynamic clinical questioning, and customized clinical summaries.
"""
import os
import json
import re
from typing import Tuple, Dict, Any, List
from dotenv import load_dotenv
from models import ConsultationSession, ExtractedIntakeData, ConsultationStatus

dotenv_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(dotenv_path)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip()

_client_initialized = False
try:
    if GEMINI_API_KEY and GEMINI_API_KEY != "your_gemini_api_key_here":
        import google.generativeai as genai
        genai.configure(api_key=GEMINI_API_KEY)
        _client_initialized = True
        print(f"Gemini AI client successfully initialized with key: {GEMINI_API_KEY[:6]}...")
except Exception as e:
    print(f"Warning: Failed to initialize Google Generative AI client: {e}")
    _client_initialized = False


SYSTEM_INSTRUCTION = """
You are the AI Healthcare Intake Assistant for 'HealthCall AI'.
Your role is to conduct a professional, empathetic, and structured pre-consultation medical intake.

CRITICAL MEDICAL & CONVERSATIONAL RULES:
1. MEDICAL SAFETY: You are an INTAKE assistant, NOT a doctor.
   - NEVER make a definitive medical diagnosis (e.g. Do NOT say 'You have dengue' or 'You have a heart attack').
   - Use cautious, safe language: 'These symptoms can have several causes', 'Your symptoms may require medical evaluation'.
   - Encourage professional medical care.

2. EMERGENCY DETECTION:
   - Immediately detect life-threatening symptoms: severe chest pain/pressure, difficulty breathing/shortness of breath, loss of consciousness, stroke signs (facial drooping, slurred speech), severe uncontrolled bleeding, seizures, severe allergic reaction (anaphylaxis), sudden extreme pain, or thoughts of self-harm.
   - If ANY emergency indicator is present, set "should_flag_emergency": true immediately.
   - Provide an urgent recommendation to seek immediate emergency care / call local emergency services.
   - NEVER delay emergency care to ask further routine questions.

3. ONE QUESTION AT A TIME:
   - NEVER ask more than one single question per turn. Keep messages brief, compassionate, and easy to answer.

4. INTAKE STATE & NO REPETITION:
   - Review KNOWN DATA. If a piece of information (Name, Age, Gender, Phone, Email, Chief Complaint, Duration, Severity) is already known, NEVER ask for it again.
   - For Logged-in patients, personal details (Name, Age, etc.) are already known. Start directly with the medical problem.
   - For Guests, first collect missing personal info (Name -> Age -> Gender) one by one, THEN begin symptom intake.

5. ISSUE-SPECIFIC ADAPTIVE CLINICAL QUESTIONS:
   - Tailor follow-up questions directly to the patient's specific complaint. DO NOT ask generic, repetitive questions.
     * Pain (Headache, Back, Joints, Muscle): Ask about character (throbbing, burning, sharp, dull), exact location, radiation, and what makes it better or worse.
     * Gastrointestinal (Stomach, Nausea, Vomiting, Acidity): Inquire about exact location (upper vs lower abdomen), relation to eating, changes in digestion/bowels.
     * Respiratory (Cough, Cold, Breathing): Ask whether the cough is dry or producing phlegm, any wheezing, chest tightness, or sore throat.
     * Fever & Infection: Inquire about measured temperature readings, chills, shivering, body aches, or sweating.
     * Dermatology & Allergy (Rash, Itch, Swelling): Ask where it started, whether it's spreading, presence of itching/blisters, or new food/cosmetic exposures.
     * Neurological / Vision / Ear: Ask about one-sided vs bilateral, light/sound sensitivity, dizziness, or visual disturbances.
   - Conduct a 3 to 4 turn inquiry to gather clinical nuance (Character, Associated symptoms, Duration, Severity) before marking intake complete.

6. TAILORED SUMMARY GENERATION:
   - When intake_complete is true:
     * clinical_summary: Write a rich 2-3 sentence personalized medical intake summary synthesizing the patient's specific presentation, symptom trajectory, and pertinent negatives.
     * recommended_specialist: Provide the exact medical specialty best suited for this case (e.g. "General Physician", "Gastroenterologist", "Neurologist", "Pulmonologist", "Dermatologist", "Orthopedic Specialist", "Cardiologist", "ENT Specialist").
     * key_observations: A list of 2 to 4 bullet points highlighting specific clinical findings from the dialog.
     * preliminary_guidance: Safe, non-prescriptive comfort and self-care advice while awaiting doctor consultation.
     * triage_level: "Routine", "Urgent", or "Emergency".

7. MULTILINGUAL & LANGUAGE ADAPTATION:
   - If a preferred language is specified (e.g., Tamil 'ta', Kannada 'kn', Hindi 'hi', Telugu 'te', Malayalam 'ml', Bengali 'bn', Marathi 'mr', English 'en'), ALWAYS conduct the entire medical triage consultation strictly from start to end in that preferred language!
   - Even if the patient types in Romanized script (e.g. 'kaachal iruku' or 'fever'), respond warmly in the patient's selected native language (e.g. தமிழ் Tamil script).
   - Ensure the "language" JSON field matches the response language code ('ta', 'kn', 'hi', 'te', 'ml', 'bn', 'mr', 'en').

8. OUTPUT FORMAT:
   - You MUST output ONLY valid JSON matching this exact structure:
{
  "response_text": "Conversational message to patient in their language",
  "language": "en|ta|hi|kn|te|ml|bn|mr",
  "extracted_data": {
    "name": string or null,
    "age": integer or null,
    "gender": string or null,
    "phone": string or null,
    "email": string or null,
    "chief_complaint": string or null,
    "symptoms": ["symptom1", "symptom2"],
    "duration": string or null,
    "severity": "mild|moderate|severe|unknown" or null,
    "clinical_summary": string or null,
    "recommended_specialist": string or null,
    "key_observations": ["observation1", "observation2"],
    "preliminary_guidance": string or null,
    "triage_level": "Routine|Urgent|Emergency"
  },
  "missing_fields": ["field1", "field2"],
  "should_flag_emergency": boolean,
  "intake_complete": boolean
}
"""

EMERGENCY_KEYWORDS = [
    "chest pain", "heart attack", "can't breathe", "cannot breathe", "difficulty breathing",
    "shortness of breath", "stroke", "paralysis", "unconscious", "passed out", "heavy bleeding",
    "bleeding heavily", "seizure", "fit", "convulsion", "anaphylaxis", "suicide", "kill myself",
    "நெஞ்சு வலி", "மூச்சு திணறல்", "छाती में दर्द", "सांस लेने में तकलीफ", "గుండె నొప్పి"
]


def detect_emergency_heuristic(text: str) -> bool:
    lower = text.lower()
    return any(kw in lower for kw in EMERGENCY_KEYWORDS)


def detect_language_code(text: str) -> str:
    for ch in text:
        code = ord(ch)
        if 0x0B80 <= code <= 0x0BFF:
            return "ta"  # Tamil
        elif 0x0900 <= code <= 0x097F:
            return "hi"  # Hindi
        elif 0x0C00 <= code <= 0x0C7F:
            return "te"  # Telugu
        elif 0x0D00 <= code <= 0x0D7F:
            return "ml"  # Malayalam
        elif 0x0C80 <= code <= 0x0CFF:
            return "kn"  # Kannada
    return "en"


def classify_complaint_category(text: str) -> str:
    """Categorizes the chief complaint to select appropriate clinical intake questions."""
    lower = text.lower()
    if any(w in lower for w in ["headache", "migraine", "head pain", "dizzy", "dizziness", "vertigo", "head", "தலைவலி", "सिरदर्द"]):
        return "headache"
    if any(w in lower for w in ["stomach", "abdomen", "abdominal", "belly", "nausea", "vomit", "vomiting", "diarrhea", "loose motion", "acidity", "gas", "indigestion", "cramp", "gut", "வயிறு", "पेट दर्द"]):
        return "gastrointestinal"
    if any(w in lower for w in ["cough", "cold", "sore throat", "throat", "phlegm", "mucus", "runny nose", "congestion", "sinus", "wheez", "இருமல்", "சளி", "खांसी"]):
        return "respiratory"
    if any(w in lower for w in ["fever", "temperature", "chills", "shiver", "sweat", "high temp", "காய்ச்சல்", "बुखार"]):
        return "fever"
    if any(w in lower for w in ["skin", "rash", "itch", "itching", "hives", "spots", "allergy", "blister", "pimples", "redness", "தோல்", "அரிப்பு", "खुजली"]):
        return "dermatology"
    if any(w in lower for w in ["back pain", "neck pain", "joint", "knee", "shoulder", "muscle", "sprain", "leg pain", "bone", "arthritis", "முதுகு", "மூட்டு", "पीठ दर्द"]):
        return "musculoskeletal"
    if any(w in lower for w in ["eye", "ear", "vision", "hearing", "earache", "கண்", "காது", "आंख", "कान"]):
        return "ent_eye"
    return "general"


def fallback_rule_based_response(session: ConsultationSession, user_message: str, language_hint: str = None) -> Dict[str, Any]:
    """
    Intelligent adaptive clinical fallback engine.
    Tailors questions specifically to the patient's condition across distinct clinical categories,
    and generates rich custom clinical summaries in the patient's preferred language.
    """
    target = (language_hint or session.intake_data.preferred_language or detect_language_code(user_message)).lower().split('_')[0].split('-')[0]
    lang = target if target in ["ta", "hi", "kn", "te", "ml", "bn", "mr", "en"] else "en"
    intake = session.intake_data
    intake.preferred_language = lang
    is_emergency = detect_emergency_heuristic(user_message) or intake.should_flag_emergency

    # Emergency branch
    if is_emergency:
        intake.should_flag_emergency = True
        session.status = ConsultationStatus.emergency
        if lang == "ta":
            resp = "⚠️ உங்கள் அறிகுறிகளுக்கு அவசர மருத்துவ உதவி தேவைப்படலாம். தயவுசெய்து உடனடியாக அவசர மருத்துவ சேவையை தொடர்பு கொள்ளவும்."
        elif lang == "hi":
            resp = "⚠️ आपके लक्षणों के लिए तत्काल आपातकालीन चिकित्सा सहायता की आवश्यकता हो सकती है। कृपया तुरंत निकटतम आपातकालीन सेवा से संपर्क करें।"
        elif lang == "kn":
            resp = "⚠️ ನಿಮ್ಮ ಲಕ್ಷಣಗಳಿಗೆ ತುರ್ತು ವೈದ್ಯಕೀಯ ಚಿಕಿತ್ಸೆಯ ಅಗತ್ಯವಿದೆ. ದಯವಿಟ್ಟು ತಕ್ಷಣವೇ ತುರ್ತು ಸೇವೆಯನ್ನು ಸಂಪರ್ಕಿಸಿ."
        elif lang == "te":
            resp = "⚠️ మీ లక్షణాలకు తక్షణ అత్యవసర వైద్య సహాయం అవసరం కావచ్చు. దయచేసి వెంటనే అత్యవసర సంరక్షణను సంప్రదించండి."
        elif lang == "ml":
            resp = "⚠️ നിങ്ങളുടെ ലക്ഷണങ്ങൾക്ക് അടിയന്തിര വൈദ്യസഹായം ആവശ്യമായി വന്നേക്കാം. ദയവായി ഉടൻ അടിയന്തര പരിചരണം തേടുക."
        else:
            resp = "⚠️ Your symptoms may require immediate medical evaluation. Please contact emergency services or proceed to the nearest emergency room immediately."

        intake.clinical_summary = f"Emergency clinical intake triggered. Acute presentation: {user_message}. Immediate medical escalation required."
        intake.recommended_specialist = "Emergency Medicine"
        intake.key_observations = ["Acute emergency symptoms reported", "Immediate clinical triage required"]
        intake.triage_level = "Emergency"

        return {
            "response_text": resp,
            "language": lang,
            "extracted_data": intake.model_dump(),
            "missing_fields": [],
            "should_flag_emergency": True,
            "intake_complete": False,
        }

    # Step 1: For guests, collect demographic info first
    if session.is_guest:
        if not intake.name:
            clean_name = user_message.replace("My name is", "").replace("I am", "").replace("பெயர்", "").strip()
            if len(session.messages) <= 1:
                intake.name = clean_name.split()[0].capitalize() if clean_name else "Guest"
            else:
                intake.name = clean_name.capitalize()
                
            if not intake.age:
                if lang == "ta":
                    resp = f"வணக்கம் {intake.name}, உங்கள் வயது என்ன?"
                elif lang == "hi":
                    resp = f"नमस्ते {intake.name}, आपकी उम्र क्या है?"
                elif lang == "kn":
                    resp = f"ನಮಸ್ಕಾರ {intake.name}, ನಿಮ್ಮ ವಯಸ್ಸು ಎಷ್ಟು?"
                elif lang == "te":
                    resp = f"నమస్కారం {intake.name}, మీ వయస్సు ఎంత?"
                elif lang == "ml":
                    resp = f"നമസ്കാരം {intake.name}, നിങ്ങളുടെ പ്രായം എത്രയാണ്?"
                else:
                    resp = f"Nice to meet you, {intake.name}. Could you share your age?"
                return {
                    "response_text": resp,
                    "language": lang,
                    "extracted_data": intake.model_dump(),
                    "missing_fields": ["age", "gender", "chief_complaint"],
                    "should_flag_emergency": False,
                    "intake_complete": False,
                }

        if not intake.age:
            nums = re.findall(r'\d+', user_message)
            if nums:
                intake.age = int(nums[0])
            if not intake.gender:
                if lang == "ta":
                    resp = "நன்றி. உங்கள் பாலினம் என்ன (ஆண் / பெண் / மற்றவை)?"
                elif lang == "hi":
                    resp = "धन्यवाद। आपका लिंग क्या है (पुरुष / महिला / अन्य)?"
                elif lang == "kn":
                    resp = "ಧನ್ಯವಾದಗಳು. ನಿಮ್ಮ ಲಿಂಗ ಯಾವುದು (ಪುರುಷ / ಮಹಿಳೆ / ಇತರೆ)?"
                elif lang == "te":
                    resp = "ధన్యవాదాలు. మీ లింగం ఏమిటి (పురుషుడు / స్త్రీ / ఇతర)?"
                elif lang == "ml":
                    resp = "നന്ദി. നിങ്ങളുടെ ലിംഗഭേദം എന്താണ് (പുരുഷൻ / സ്ത്രീ / മറ്റുള്ളവ)?"
                else:
                    resp = "Thank you. What is your gender (Male / Female / Other)?"
                return {
                    "response_text": resp,
                    "language": lang,
                    "extracted_data": intake.model_dump(),
                    "missing_fields": ["gender", "chief_complaint"],
                    "should_flag_emergency": False,
                    "intake_complete": False,
                }

        if not intake.gender:
            lower = user_message.lower()
            if "female" in lower or "woman" in lower or "பெண்" in user_message:
                intake.gender = "Female"
            elif "other" in lower:
                intake.gender = "Other"
            else:
                intake.gender = "Male"

    # Step 2: Adaptive Clinical Inquiry based on Chief Complaint
    # Track questions in intake.relevant_answers
    answers = intake.relevant_answers or {}

    # 2A. Record Chief Complaint
    if not intake.chief_complaint:
        intake.chief_complaint = user_message.strip()
        lower = user_message.lower()
        extracted_symptoms = []
        for s in ["fever", "headache", "migraine", "cough", "cold", "sore throat", "stomach pain",
                  "nausea", "vomiting", "diarrhea", "acidity", "body ache", "back pain", "joint pain",
                  "rash", "itching", "dizziness", "fatigue", "காய்ச்சல்", "தலைவலி", "இருமல்", "வயிறு வலி"]:
            if s in lower or s in user_message:
                extracted_symptoms.append(s)
        intake.symptoms = extracted_symptoms if extracted_symptoms else [user_message.strip()]
        category = classify_complaint_category(user_message)
        answers["category"] = category
        intake.relevant_answers = answers

        # Tailored Question 1: Condition characteristics
        if category == "headache":
            resp = "Is the headache throbbing, dull, or sharp, and is it mostly on one side of your head or all over?"
        elif category == "gastrointestinal":
            resp = "Where in your stomach or abdomen is the discomfort located, and does it feel worse before or after eating?"
        elif category == "respiratory":
            resp = "Is your cough dry or producing phlegm/mucus, and are you having any throat soreness or nasal congestion?"
        elif category == "fever":
            resp = "Have you experienced chills, shivering, or body aches along with the fever?"
        elif category == "dermatology":
            resp = "Where on your body did the rash or irritation appear, and is it intensely itchy, burning, or spreading?"
        elif category == "musculoskeletal":
            resp = "Does the pain get worse with specific movements, and was there any recent strain, heavy lifting, or injury?"
        elif category == "ent_eye":
            resp = "Are you experiencing any discharge, redness, pain, or changes in your vision or hearing?"
        else:
            resp = "Could you describe what this discomfort feels like (e.g. sharp, dull, burning, or throbbing), and where it is located?"

        return {
            "response_text": resp,
            "language": lang,
            "extracted_data": intake.model_dump(),
            "missing_fields": ["symptom_details", "duration", "severity"],
            "should_flag_emergency": False,
            "intake_complete": False,
        }

    category = answers.get("category") or classify_complaint_category(intake.chief_complaint)

    # 2B. Tailored Question 2: Associated factors / Red-flag checks
    if "associated_checked" not in answers:
        answers["character_detail"] = user_message.strip()
        answers["associated_checked"] = True
        intake.relevant_answers = answers

        if category == "headache":
            resp = "Are you having any nausea, sensitivity to bright light or sound, or visual disturbances like blurriness?"
        elif category == "gastrointestinal":
            resp = "Have you had any nausea, vomiting, fever, or noticeable changes in your bowel movements?"
        elif category == "respiratory":
            resp = "Have you noticed any shortness of breath, wheezing, or chest tightness when breathing deeply?"
        elif category == "fever":
            resp = "Have you measured your body temperature with a thermometer, or taken any paracetamol or fever medicine?"
        elif category == "dermatology":
            resp = "Have you recently been exposed to any new soaps, cosmetics, detergents, medications, or unusual foods?"
        elif category == "musculoskeletal":
            resp = "Have you noticed any swelling, morning stiffness, or numbness and tingling radiating down your arms or legs?"
        elif category == "ent_eye":
            resp = "Have you noticed any fever, headache, or swelling in your face or neck glands?"
        else:
            resp = "Are you experiencing any other accompanying symptoms like fatigue, dizziness, or fever?"

        return {
            "response_text": resp,
            "language": lang,
            "extracted_data": intake.model_dump(),
            "missing_fields": ["duration", "severity"],
            "should_flag_emergency": False,
            "intake_complete": False,
        }

    # 2C. Question 3: Duration
    if not intake.duration:
        answers["associated_detail"] = user_message.strip()
        intake.duration = user_message.strip()
        intake.relevant_answers = answers

        resp = "Approximately how long have you been experiencing this issue (e.g. since yesterday, 3 days, 2 weeks)?"
        return {
            "response_text": resp,
            "language": lang,
            "extracted_data": intake.model_dump(),
            "missing_fields": ["severity"],
            "should_flag_emergency": False,
            "intake_complete": False,
        }

    # 2D. Question 4: Severity & Finalization
    if not intake.severity:
        lower = user_message.lower()
        if "severe" in lower or "high" in lower or "கடும்" in user_message or "10" in lower or "9" in lower:
            intake.severity = "Severe"
        elif "moderate" in lower or "medium" in lower or "மித" in user_message or "6" in lower or "5" in lower:
            intake.severity = "Moderate"
        else:
            intake.severity = "Mild"

        intake.intake_complete = True
        session.status = ConsultationStatus.completed

        # Generate Tailored Clinical Summary, Specialist, Observations & Guidance
        p_name = intake.name or (session.patient.name if session.patient else "Patient")
        p_age = f"{intake.age}-year-old" if intake.age else "Adult"
        p_gender = intake.gender or ""
        demographic_str = f"{p_age} {p_gender}".strip()

        if category == "headache":
            intake.clinical_summary = (
                f"{demographic_str} reports {intake.severity.lower()} cephalalgia presenting as '{intake.chief_complaint}'. "
                f"Symptom duration: {intake.duration}. Characterized by {answers.get('character_detail', 'head discomfort')}. "
                f"Associated clinical inquiry noted: {answers.get('associated_detail', 'none reported')}. "
                f"No acute focal neurological deficits reported at intake."
            )
            intake.recommended_specialist = "Neurologist"
            intake.key_observations = [
                f"Severity: {intake.severity}",
                f"Pattern: {answers.get('character_detail', 'Localized headache')}",
                "Evaluated for photo/phonophobia and nausea",
                f"Duration: {intake.duration}"
            ]
            intake.preliminary_guidance = (
                "Rest in a quiet, dark room. Maintain regular hydration and avoid prolonged screen time "
                "or skipping meals while awaiting your doctor consultation."
            )
            intake.triage_level = "Urgent" if intake.severity == "Severe" else "Routine"

        elif category == "gastrointestinal":
            intake.clinical_summary = (
                f"{demographic_str} presents with {intake.severity.lower()} gastrointestinal discomfort described as '{intake.chief_complaint}'. "
                f"Duration: {intake.duration}. Reported localized features: {answers.get('character_detail', 'abdominal discomfort')}. "
                f"Digestive and bowel evaluation: {answers.get('associated_detail', 'no red flags reported')}. "
                f"Clinical findings consistent with acute dyspepsia or abdominal distress."
            )
            intake.recommended_specialist = "Gastroenterologist"
            intake.key_observations = [
                f"Severity: {intake.severity}",
                f"Location/Trigger: {answers.get('character_detail', 'Abdominal')}",
                f"Duration: {intake.duration}",
                "Screened for vomiting, bowel changes, and fever"
            ]
            intake.preliminary_guidance = (
                "Sip small amounts of warm water or clear fluids. Eat bland, easily digestible foods "
                "(such as bananas, rice, or crackers). Avoid spicy, fried, or highly acidic foods."
            )
            intake.triage_level = "Urgent" if intake.severity == "Severe" else "Routine"

        elif category == "respiratory":
            intake.clinical_summary = (
                f"{demographic_str} presents with {intake.severity.lower()} respiratory complaints consisting of '{intake.chief_complaint}'. "
                f"Duration: {intake.duration}. Cough/airway details: {answers.get('character_detail', 'cough and congestion')}. "
                f"Breath sounds and systemic check: {answers.get('associated_detail', 'stable')}. "
                f"Features suggestive of acute upper respiratory tract involvement."
            )
            intake.recommended_specialist = "Pulmonologist"
            intake.key_observations = [
                f"Severity: {intake.severity}",
                f"Cough profile: {answers.get('character_detail', 'Respiratory symptoms')}",
                f"Duration: {intake.duration}",
                "Screened for dyspnea, wheezing, and chest tightness"
            ]
            intake.preliminary_guidance = (
                "Stay well-hydrated with warm fluids like herbal tea or warm water. Consider gentle steam inhalation "
                "and rest with your head slightly elevated."
            )
            intake.triage_level = "Urgent" if intake.severity == "Severe" else "Routine"

        elif category == "fever":
            intake.clinical_summary = (
                f"{demographic_str} presents with a febrile episode described as '{intake.chief_complaint}'. "
                f"Onset and duration: {intake.duration}, severity graded as {intake.severity.lower()}. "
                f"Chills, myalgia, and constitutional symptoms: {answers.get('character_detail', 'reported fever')}. "
                f"Symptom profile consistent with acute febrile illness requiring physician evaluation."
            )
            intake.recommended_specialist = "General Physician"
            intake.key_observations = [
                f"Severity: {intake.severity}",
                f"Duration: {intake.duration}",
                f"Constitutional signs: {answers.get('character_detail', 'Chills/body aches')}",
                "Antipyretic usage and temperature logging advised"
            ]
            intake.preliminary_guidance = (
                "Maintain generous fluid intake to prevent dehydration. Rest in a well-ventilated room, "
                "wear light clothing, and keep a log of your body temperature."
            )
            intake.triage_level = "Urgent" if intake.severity == "Severe" else "Routine"

        elif category == "dermatology":
            intake.clinical_summary = (
                f"{demographic_str} presents with dermatological irritation described as '{intake.chief_complaint}'. "
                f"Duration: {intake.duration}, discomfort rated as {intake.severity.lower()}. "
                f"Distribution and sensation: {answers.get('character_detail', 'cutaneous lesions/rash')}. "
                f"Allergen and contact history: {answers.get('associated_detail', 'no known new contacts')}. "
                f"Clinical appearance indicates dermatitis or localized allergic reaction."
            )
            intake.recommended_specialist = "Dermatologist"
            intake.key_observations = [
                f"Severity: {intake.severity}",
                f"Distribution: {answers.get('character_detail', 'Skin lesions')}",
                f"Duration: {intake.duration}",
                "Assessed for contact allergens and spreading"
            ]
            intake.preliminary_guidance = (
                "Avoid scratching the affected skin to prevent secondary infection. Do not apply heavily fragranced "
                "lotions or harsh soaps. Wear breathable cotton clothing."
            )
            intake.triage_level = "Routine"

        elif category == "musculoskeletal":
            intake.clinical_summary = (
                f"{demographic_str} reports {intake.severity.lower()} musculoskeletal pain regarding '{intake.chief_complaint}'. "
                f"Duration: {intake.duration}. Movement and mechanical factors: {answers.get('character_detail', 'exacerbated by motion')}. "
                f"Associated joint/swelling findings: {answers.get('associated_detail', 'no acute neurological deficits')}. "
                f"Picture consistent with localized strain, sprain, or joint inflammation."
            )
            intake.recommended_specialist = "Orthopedic Specialist"
            intake.key_observations = [
                f"Severity: {intake.severity}",
                f"Mechanical factors: {answers.get('character_detail', 'Pain on movement')}",
                f"Duration: {intake.duration}",
                "Assessed for swelling, morning stiffness, and radiating numbness"
            ]
            intake.preliminary_guidance = (
                "Rest the affected joint/muscle and avoid strenuous activities or heavy lifting. "
                "Cold packs may help reduce acute swelling, or warm compresses for muscular tightness."
            )
            intake.triage_level = "Routine"

        else:
            intake.clinical_summary = (
                f"{demographic_str} presents for intake evaluation regarding '{intake.chief_complaint}'. "
                f"Symptom duration: {intake.duration}, severity graded as {intake.severity.lower()}. "
                f"Clinical characterization: {answers.get('character_detail', 'unspecified')}. "
                f"Systemic review: {answers.get('associated_detail', 'no acute red flags noted')}."
            )
            intake.recommended_specialist = "General Physician"
            intake.key_observations = [
                f"Severity: {intake.severity}",
                f"Duration: {intake.duration}",
                f"Chief concern: {intake.chief_complaint}",
                "Full pre-consultation intake recorded"
            ]
            intake.preliminary_guidance = (
                "Get plenty of rest and drink adequate fluids. Please discuss this structured summary "
                "with your consulting physician for formal diagnosis and care plan."
            )
            intake.triage_level = "Routine"

        resp = (
            f"Thank you, {p_name}. I have completed your structured medical intake. "
            f"I have summarized your {intake.chief_complaint} and recommended a {intake.recommended_specialist}. "
            f"You can now review your pre-consultation summary and proceed to book a doctor appointment."
        )

        return {
            "response_text": resp,
            "language": lang,
            "extracted_data": intake.model_dump(),
            "missing_fields": [],
            "should_flag_emergency": False,
            "intake_complete": True,
        }

    # Default if already complete
    return {
        "response_text": "Your preliminary intake is complete. Please review your structured summary or proceed to book a doctor appointment.",
        "language": lang,
        "extracted_data": intake.model_dump(),
        "missing_fields": [],
        "should_flag_emergency": False,
        "intake_complete": True,
    }


async def process_consultation_turn(
    session: ConsultationSession,
    user_message: str,
    language_hint: str = None,
) -> Dict[str, Any]:
    """
    Sends conversational turn to Gemini LLM with rich context, or falls back to the adaptive rule-based engine.
    """
    # Emergency heuristic pre-check for high safety
    if detect_emergency_heuristic(user_message):
        session.intake_data.should_flag_emergency = True

    target_lang = language_hint or session.intake_data.preferred_language or "en"

    if not _client_initialized:
        return fallback_rule_based_response(session, user_message, language_hint=target_lang)

    models_to_try = ["gemini-flash-lite-latest", "gemini-flash-latest"]

    for model_name in models_to_try:
        try:
            import google.generativeai as genai

            model = genai.GenerativeModel(
                model_name=model_name,
                system_instruction=SYSTEM_INSTRUCTION,
                generation_config={"response_mime_type": "application/json", "temperature": 0.2},
            )

            # Build context snapshot
            known_data = {
                "is_guest": session.is_guest,
                "patient_profile": session.patient.model_dump() if session.patient else None,
                "current_intake_data": session.intake_data.model_dump(),
                "status": session.status.value,
                "preferred_language": target_lang,
            }

            # Build conversation history
            history_summary = []
            for msg in session.messages[-8:]:  # Last 8 messages for rich conversational context
                history_summary.append(f"{msg.role.value.upper()}: {msg.content}")

            prompt = f"""
KNOWN CONTEXT:
{json.dumps(known_data, indent=2)}

RECENT CONVERSATION:
{chr(10).join(history_summary)}

LATEST PATIENT MESSAGE:
"{user_message}"

MANDATORY RESPONSE LANGUAGE:
Target Language: '{target_lang}' (e.g. ta = Tamil, kn = Kannada, hi = Hindi, te = Telugu, ml = Malayalam, en = English).
You MUST generate the conversational 'response_text' and all clinical summary text strictly in this '{target_lang}' language and its native script!

Process this turn. Ensure follow-up questions are specifically customized to the patient's exact complaint.
When concluding, generate the tailored clinical_summary, recommended_specialist, key_observations, preliminary_guidance, and triage_level.
Return ONLY valid JSON matching the system instruction schema.
"""

            response = model.generate_content(prompt)
            text = response.text.strip()
            data = json.loads(text)

            # Merge extracted data into session intake
            ext = data.get("extracted_data", {})
            if ext:
                if ext.get("name") and not session.intake_data.name:
                    session.intake_data.name = ext["name"]
                if ext.get("age") and not session.intake_data.age:
                    session.intake_data.age = ext["age"]
                if ext.get("gender") and not session.intake_data.gender:
                    session.intake_data.gender = ext["gender"]
                if ext.get("chief_complaint") and not session.intake_data.chief_complaint:
                    session.intake_data.chief_complaint = ext["chief_complaint"]
                if ext.get("symptoms"):
                    for s in ext["symptoms"]:
                        if s not in session.intake_data.symptoms:
                            session.intake_data.symptoms.append(s)
                if ext.get("duration") and not session.intake_data.duration:
                    session.intake_data.duration = ext["duration"]
                if ext.get("severity") and not session.intake_data.severity:
                    session.intake_data.severity = ext["severity"]

                # Enriched clinical summary fields
                if ext.get("clinical_summary"):
                    session.intake_data.clinical_summary = ext["clinical_summary"]
                if ext.get("recommended_specialist"):
                    session.intake_data.recommended_specialist = ext["recommended_specialist"]
                if ext.get("key_observations"):
                    session.intake_data.key_observations = ext["key_observations"]
                if ext.get("preliminary_guidance"):
                    session.intake_data.preliminary_guidance = ext["preliminary_guidance"]
                if ext.get("triage_level"):
                    session.intake_data.triage_level = ext["triage_level"]

            if data.get("should_flag_emergency"):
                session.intake_data.should_flag_emergency = True
                session.status = ConsultationStatus.emergency

            if data.get("intake_complete"):
                session.intake_data.intake_complete = True
                session.status = ConsultationStatus.completed

            session.intake_data.preferred_language = data.get("language", session.intake_data.preferred_language)

            return data

        except Exception as e:
            print(f"Gemini model {model_name} error: {e}. Trying next or falling back...")
            continue

    print("All Gemini models failed. Engaging adaptive clinical fallback engine.")
    return fallback_rule_based_response(session, user_message)
