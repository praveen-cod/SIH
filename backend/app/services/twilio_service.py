import os
import re
import logging
from typing import Optional

from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException

logger = logging.getLogger(__name__)

# Default India country code for 10-digit mobile numbers stored without +91
_DEFAULT_COUNTRY_CODE = "+91"


def normalize_phone_e164(raw: Optional[str], default_country: str = _DEFAULT_COUNTRY_CODE) -> str:
    """Normalize patient emergency numbers to E.164 for Twilio (e.g. 9344088926 -> +919344088926)."""
    if not raw:
        return ""
    cleaned = raw.strip()
    digits = re.sub(r"\D", "", cleaned)
    if not digits:
        return ""
    if cleaned.startswith("+"):
        return f"+{digits}"
    if len(digits) == 10:
        cc = default_country if default_country.startswith("+") else f"+{default_country}"
        return f"{cc}{digits}"
    if len(digits) == 12 and digits.startswith("91"):
        return f"+{digits}"
    return f"+{digits}"


class TwilioService:
    def __init__(self):
        self._client: Optional[Client] = None
        self._client_key: Optional[tuple] = None

    def _credentials(self) -> tuple[str, str, str]:
        account_sid = (os.getenv("TWILIO_ACCOUNT_SID") or "").strip()
        auth_token = (os.getenv("TWILIO_AUTH_TOKEN") or "").strip()
        from_number = (os.getenv("TWILIO_FROM_NUMBER") or "").strip()
        return account_sid, auth_token, from_number

    def _get_client(self) -> Optional[Client]:
        account_sid, auth_token, from_number = self._credentials()
        if not account_sid or not auth_token or account_sid in ("mock_sid", "your_account_sid"):
            return None
        key = (account_sid, auth_token)
        if self._client is not None and self._client_key == key:
            return self._client
        try:
            self._client = Client(account_sid, auth_token)
            self._client_key = key
            return self._client
        except Exception as e:
            logger.error("Failed to initialize Twilio client: %s", e)
            self._client = None
            self._client_key = None
            return None

    def call_emergency_contact(self, to_number: str, message: str, voice: str = "Polly.Joanna") -> bool:
        """
        Initiates a voice call using Twilio and plays the provided message using TwiML.
        Supports passing different `voice` attributes (e.g. 'Polly.Aditi' for Indian English/Hindi) 
        to match the user's selected language.
        """
        to_e164 = normalize_phone_e164(to_number)
        if not to_e164:
            logger.warning("No valid emergency contact number provided (raw=%r).", to_number)
            return False

        _, _, from_number = self._credentials()
        if not from_number:
            logger.error("TWILIO_FROM_NUMBER is not configured.")
            return False

        client = self._get_client()
        if not client:
            logger.error(
                "Twilio is not configured (set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER in backend/.env). "
                "Would dial %s for emergency alert.",
                to_e164,
            )
            return False

        # Twilio <Say> works best with concise messages; keep under ~3500 chars
        speech = (message or "").strip()
        if len(speech) > 3500:
            speech = speech[:3497] + "..."

        logger.info("Initiating emergency call to %s...", to_e164)

        try:
            twiml = f'<Response><Say voice="{voice}">{speech}</Say></Response>'
            call = client.calls.create(
                twiml=twiml,
                to=to_e164,
                from_=from_number,
            )
            logger.info("Twilio call initiated. Call SID: %s", call.sid)
            return True
        except TwilioRestException as e:
            logger.error("Twilio API error during emergency call to %s: %s", to_e164, e)
            return False
        except Exception as e:
            logger.error("Unexpected error making Twilio call to %s: %s", to_e164, e)
            return False


twilio_service = TwilioService()
