"""Maya 2.0 - Outbound Webhook Tool

Sends messages to Slack, Discord, or any generic webhook URL.
Supports multiple webhook URLs via .env variables:

  WEBHOOK_SLACK_URL   — Slack incoming webhook URL
  WEBHOOK_DISCORD_URL — Discord incoming webhook URL
  WEBHOOK_GENERIC_URL — fallback generic webhook URL
"""
import json as _json

import requests

from config.settings import env_first


class WebhookTool:
    """Send messages to Slack / Discord / generic webhooks."""

    def __init__(self):
        self.slack_url = env_first("WEBHOOK_SLACK_URL")
        self.discord_url = env_first("WEBHOOK_DISCORD_URL")
        self.generic_url = env_first("WEBHOOK_GENERIC_URL")

    def configured(self, channel: str = "") -> bool:
        if channel == "slack":
            return bool(self.slack_url)
        if channel == "discord":
            return bool(self.discord_url)
        if channel == "generic":
            return bool(self.generic_url)
        return bool(self.slack_url or self.discord_url or self.generic_url)

    def run(self, action: str = "send", message: str = "",
            channel: str = "slack", title: str = "",
            json: dict = None, **kwargs) -> str:
        """Send a webhook message.
        Args:
            action: 'send' or 'test'
            message: the text body (in Slack this is the fallback text)
            channel: 'slack', 'discord', or 'generic'
            title: optional bold heading (Slack) or embed title (Discord)
            json: optional raw payload dict (overrides message/title)
        """
        if action == "test":
            ok = self.configured(channel) if channel else self.configured()
            parts = []
            for ch in ("slack", "discord", "generic"):
                url = getattr(self, f"{ch}_url")
                parts.append(f"{ch}: {'OK' if url else 'not set'}")
            if ok:
                return "Webhook configured — " + ", ".join(parts)
            return (
                "No webhook URLs configured. Set WEBHOOK_SLACK_URL, "
                "WEBHOOK_DISCORD_URL, or WEBHOOK_GENERIC_URL in .env. "
                + ", ".join(parts)
            )

        if action != "send":
            return f"Unsupported action: {action}. Use 'send' or 'test'."

        channel = (channel or "slack").lower().strip()
        if channel not in ("slack", "discord", "generic"):
            return f"Unsupported channel: {channel}. Choose slack, discord, or generic."

        url = getattr(self, f"{channel}_url", None)
        if not url:
            return (
                f"{channel} webhook not configured. "
                f"Set WEBHOOK_{channel.upper()}_URL in .env."
            )

        if not message and not json:
            return "Error: message or json payload required"

        try:
            if json:
                payload = json
            elif channel == "slack":
                payload = {"text": message}
                if title:
                    payload["blocks"] = [
                        {"type": "section", "text": {"type": "mrkdwn",
                                                      "text": f"*{title}*\n{message}"}},
                    ]
            elif channel == "discord":
                payload = {"content": message}
                if title:
                    payload["embeds"] = [{"title": title, "description": message}]
            else:
                payload = {"text": message, "title": title} if title else {"text": message}

            resp = requests.post(url, json=payload, timeout=15)
            if resp.status_code < 300:
                return f"Message sent to {channel} ({resp.status_code})"
            return f"Webhook returned {resp.status_code}: {resp.text[:300]}"
        except requests.RequestException as e:
            return f"Webhook send failed: {e}"
        except Exception as e:
            return f"Unexpected error: {e}"
