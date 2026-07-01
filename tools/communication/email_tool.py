"""Maya 2.0 - Email Tool (Optional SMTP)"""
import os
import smtplib
from email.mime.text import MIMEText


class EmailTool:
    def __init__(self):
        self.smtp_host = os.environ.get("SMTP_HOST", "")
        self.smtp_port = int(os.environ.get("SMTP_PORT", "587"))
        self.smtp_user = os.environ.get("SMTP_USER", "")
        self.smtp_pass = os.environ.get("SMTP_PASS", "")

    def run(self, action: str = "send", to: str = "", subject: str = "",
            body: str = "", **kwargs) -> str:
        if action != "send":
            return f"Unsupported email action: {action}"

        if not (self.smtp_host and self.smtp_user and self.smtp_pass):
            return (
                "Email is not configured. Set SMTP_HOST, SMTP_USER and "
                "SMTP_PASS as environment variables to enable this tool."
            )

        if not to:
            return "Error: 'to' address required"

        try:
            msg = MIMEText(body or "")
            msg["Subject"] = subject or "(no subject)"
            msg["From"] = self.smtp_user
            msg["To"] = to

            with smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=20) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_pass)
                server.sendmail(self.smtp_user, [to], msg.as_string())

            return f"Email sent to {to}"
        except Exception as e:
            return f"Email send failed: {e}"
