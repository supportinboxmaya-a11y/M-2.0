"""Maya 2.0 - Email Tool (SMTP with env_first config)"""
import smtplib
from email.mime.text import MIMEText

from config.settings import env_first


class EmailTool:
    """Send email via SMTP. Configure via SMTP_HOST / SMTP_PORT /
    SMTP_USER / SMTP_PASS / SMTP_FROM in .env."""

    def __init__(self):
        self.smtp_host = env_first("SMTP_HOST")
        self.smtp_port = int(env_first("SMTP_PORT", default="587") or "587")
        self.smtp_user = env_first("SMTP_USER", "SMTP_USERNAME")
        self.smtp_pass = env_first("SMTP_PASS", "SMTP_PASSWORD")
        self.smtp_from = env_first("SMTP_FROM", default=self.smtp_user)

    def configured(self) -> bool:
        return bool(self.smtp_host and self.smtp_user and self.smtp_pass)

    def run(self, action: str = "send", to: str = "", subject: str = "",
            body: str = "", **kwargs) -> str:
        if action == "test":
            if not self.configured():
                return (
                    "Email is not configured. Set SMTP_HOST, SMTP_USER and "
                    "SMTP_PASS as environment variables to enable this tool."
                )
            return f"OK — SMTP configured ({self.smtp_host}:{self.smtp_port}, from: {self.smtp_from})"

        if action != "send":
            return f"Unsupported email action: {action}. Use 'send' or 'test'."

        if not self.configured():
            return (
                "Email is not configured. Set SMTP_HOST, SMTP_USER and "
                "SMTP_PASS as environment variables to enable this tool."
            )

        if not to:
            return "Error: 'to' address required"

        try:
            msg = MIMEText(body or "")
            msg["Subject"] = subject or "(no subject)"
            msg["From"] = self.smtp_from
            msg["To"] = to

            with smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=20) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_pass)
                server.sendmail(self.smtp_from, [to], msg.as_string())

            return f"Email sent to {to}"
        except Exception as e:
            return f"Email send failed: {e}"
