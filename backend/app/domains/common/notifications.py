"""
OTP delivery channels: Email (fastapi-mail) and WhatsApp (Twilio).

Each channel is independently configurable. Failures are logged but surfaced to callers.
"""

from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType
from twilio.rest import Client as TwilioClient

from app.core.config import Settings
from app.core.logging import get_logger
from app.domains.common.exceptions import DomainError
from app.domains.common.otp import OTPChannel

logger = get_logger(__name__)


class EmailOTPNotifier:
    """Send OTP via SMTP (Gmail or any transactional provider)."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self._mail: FastMail | None = None

    def _get_mail(self) -> FastMail:
        if self._mail is None:
            conf = ConnectionConfig(
                MAIL_USERNAME=self.settings.email_username,
                MAIL_PASSWORD=self.settings.email_password,
                MAIL_FROM=self.settings.email_from or self.settings.email_username,
                MAIL_PORT=self.settings.email_port,
                MAIL_SERVER=self.settings.email_host,
                MAIL_FROM_NAME=self.settings.email_from_name,
                MAIL_STARTTLS=self.settings.email_use_tls,
                MAIL_SSL_TLS=False,
                USE_CREDENTIALS=True,
                VALIDATE_CERTS=True,
            )
            self._mail = FastMail(conf)
        return self._mail

    async def send_otp(self, email: str, otp: str) -> None:
        if not self.settings.email_username or not self.settings.email_password:
            logger.warning("email_otp_skipped", reason="SMTP credentials not configured")
            if self.settings.is_local:
                logger.info("email_otp_dev_mode", email=email, otp=otp)
                return
            raise DomainError("Email service is not configured")

        message = MessageSchema(
            subject=f"{self.settings.app_name} - Your verification code",
            recipients=[email],
            body=f"Your {self.settings.app_name} verification code is: {otp}\n\n"
            f"This code expires in {self.settings.otp_expire_minutes} minutes.",
            subtype=MessageType.plain,
        )
        await self._get_mail().send_message(message)
        logger.info("email_otp_sent", email=email)


class WhatsAppOTPNotifier:
    """Send OTP via Twilio WhatsApp API."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self._client: TwilioClient | None = None

    def _get_client(self) -> TwilioClient:
        if self._client is None:
            if not self.settings.twilio_account_sid or not self.settings.twilio_auth_token:
                raise DomainError("Twilio is not configured")
            self._client = TwilioClient(
                self.settings.twilio_account_sid,
                self.settings.twilio_auth_token,
            )
        return self._client

    def _format_whatsapp_number(self, phone: str) -> str:
        """Ensure E.164 format with whatsapp: prefix for Twilio."""
        cleaned = phone.strip()
        if not cleaned.startswith("+"):
            cleaned = f"+{cleaned.lstrip('0')}"
        if not cleaned.startswith("whatsapp:"):
            cleaned = f"whatsapp:{cleaned}"
        return cleaned

    async def send_otp(self, phone: str, otp: str) -> None:
        if not self.settings.twilio_account_sid or not self.settings.twilio_auth_token:
            logger.warning("whatsapp_otp_skipped", reason="Twilio credentials not configured")
            if self.settings.is_local:
                logger.info("whatsapp_otp_dev_mode", phone=phone, otp=otp)
                return
            raise DomainError("WhatsApp service is not configured")

        to_number = self._format_whatsapp_number(phone)
        body = (
            f"Your {self.settings.app_name} verification code is: {otp}. "
            f"Expires in {self.settings.otp_expire_minutes} minutes."
        )

        # Twilio SDK is sync; run in thread pool in production for high throughput
        client = self._get_client()
        client.messages.create(
            body=body,
            from_=self.settings.twilio_whatsapp_from,
            to=to_number,
        )
        logger.info("whatsapp_otp_sent", phone=to_number)


class OTPDeliveryService:
    """Facade for delivering OTPs across channels."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.email = EmailOTPNotifier(settings)
        self.whatsapp = WhatsAppOTPNotifier(settings)

    async def deliver(self, channel: OTPChannel, identifier: str, otp: str) -> None:
        if channel == OTPChannel.EMAIL:
            await self.email.send_otp(identifier, otp)
        elif channel == OTPChannel.WHATSAPP:
            await self.whatsapp.send_otp(identifier, otp)
        else:
            raise DomainError(f"Unsupported OTP channel: {channel}")