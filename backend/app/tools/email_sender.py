"""Tool: send invitation emails to vendors via Resend.

The email is composed from the inputs, persisted to Supabase as the audit-trail
source of truth, and (best-effort) actually delivered via the Resend API.
"""

import os
import base64
import logging
from datetime import datetime

# Ensure .env is loaded before reading env vars
from dotenv import load_dotenv
load_dotenv()

from app.services.supabase_client import supabase_service

_DEMO_REDIRECT_EMAIL = os.getenv("DEMO_REDIRECT_ALL_EMAILS_TO")
if _DEMO_REDIRECT_EMAIL:
    logging.info(f"DEMO REDIRECT enabled: all emails will go to {_DEMO_REDIRECT_EMAIL}")

# Resend setup
try:
    import resend
    _RESEND_API_KEY = os.getenv("RESEND_API_KEY")
    if _RESEND_API_KEY:
        resend.api_key = _RESEND_API_KEY
        _RESEND_ENABLED = True
        logging.info("Resend enabled with API key (length=%d)", len(_RESEND_API_KEY))
    else:
        _RESEND_ENABLED = False
        logging.warning("RESEND_API_KEY not found in environment - emails will be simulated")
except ImportError:
    _RESEND_ENABLED = False
    logging.warning("resend module not installed - emails will be simulated")

_RESEND_FROM = os.getenv("RESEND_FROM_EMAIL", "onboarding@resend.dev")
_logger = logging.getLogger(__name__)


def _load_pdf_attachment(job_id: str, reference_id: str) -> tuple[dict | None, str | None]:
    try:
        response = supabase_service.client.table("generated_documents") \
            .select("file_path, id") \
            .eq("job_id", job_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()
            
        if not response.data:
            _logger.warning(f"No generated_documents found for job_id={job_id}")
            return None, None
            
        doc = response.data[0]
        file_path = doc["file_path"]
        document_id = str(doc["id"])
        
        if not os.path.exists(file_path):
            _logger.warning(f"PDF file not found on disk at {file_path}")
            return None, document_id
            
        with open(file_path, "rb") as f:
            pdf_bytes = f.read()
            
        return {
            "filename": f"RFP_{reference_id}.pdf",
            "content": base64.b64encode(pdf_bytes).decode("utf-8")
        }, document_id
    except Exception as e:
        _logger.warning(f"Error loading PDF attachment for job_id={job_id}: {e}")
        return None, None


def send_invitation_email(
    job_id: str,
    vendor_name: str,
    vendor_email: str,
    rfp_title: str,
    reference_id: str,
    predicted_bid_pkr: float,
    submission_deadline_iso: str,
    portal_url: str,
    issuing_organization: str,
) -> dict:
    """Send an invitation email to a single vendor and persist to sent_emails."""
    
    try:
        dt = datetime.fromisoformat(submission_deadline_iso.replace("Z", "+00:00"))
        parsed_deadline = dt.strftime("%d %B %Y at %I:%M %p PKT")
    except Exception:
        parsed_deadline = submission_deadline_iso

    vendor_portal_url = f"https://rfp-agent-system.netlify.app/#/vendor/login?return_to=/vendor/rfp/{job_id}"
    attachment, _ = _load_pdf_attachment(job_id, reference_id)

    subject = f"RFP Invitation: {rfp_title} (Ref: {reference_id})"
    body_text = (
        f"Dear {vendor_name} Team,\n\n"
        f"You are invited to participate in the procurement process for: {rfp_title}.\n\n"
        f"Reference ID: {reference_id}\n"
        f"Issuing Organization: {issuing_organization}\n"
        f"Submission Deadline: {parsed_deadline}\n"
        f"RFP Portal: {vendor_portal_url}\n\n"
        f"Based on historical bidding patterns, the expected bid range positions your "
        f"organization's typical pricing (approximately PKR {predicted_bid_pkr:,.0f}) "
        f"competitively for this opportunity.\n\n"
        f"Please refer to the attached RFP document for complete eligibility criteria, "
        f"evaluation methodology (60% technical / 30% financial / 10% PPRA compliance), and mandatory clauses.\n\n"
        f"For further correspondence, please contact the procurement officer named in the RFP document.\n\n"
        f"Sincerely,\n"
        f"{issuing_organization} Procurement\n"
        f"(no-reply)"
    )

    body_html = f"""
    <table align="center" width="600" style="margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; border-collapse: collapse; width: 100%; max-width: 600px;">
        <tr>
            <td style="background-color: #0F2A4A; color: white; text-align: center; padding: 24px;">
                <h1 style="margin: 0; font-size: 24px; font-weight: bold; color: white;">RFP Agent System</h1>
                <p style="margin: 8px 0 0 0; font-size: 14px; color: #E2E8F0;">Government of Pakistan Procurement Platform</p>
            </td>
        </tr>
        <tr>
            <td style="background-color: white; padding: 24px;">
                <p style="margin: 0 0 16px 0; font-size: 16px; color: #334155;">Dear {vendor_name} Team,</p>
                <p style="margin: 0 0 16px 0; font-size: 16px; color: #334155;">Government of Punjab invites you to submit a proposal for:</p>
                <h2 style="margin: 0 0 16px 0; font-size: 20px; font-weight: bold; color: #0F2A4A;">{rfp_title}</h2>

                <table width="100%" style="background-color: #F8FAFC; padding: 16px; border-radius: 8px; border-left: 4px solid #0F2A4A; margin-bottom: 32px; border-collapse: collapse;">
                    <tr><td style="padding: 4px 0; color: #64748B; width: 40%;">Reference ID:</td><td style="padding: 4px 0; color: #0F2A4A; font-weight: 600;">{reference_id}</td></tr>
                    <tr><td style="padding: 4px 0; color: #64748B;">Issuing Organization:</td><td style="padding: 4px 0; color: #0F2A4A; font-weight: 600;">{issuing_organization}</td></tr>
                    <tr><td style="padding: 4px 0; color: #64748B;">Estimated Project Value:</td><td style="padding: 4px 0; color: #0F2A4A; font-weight: 600;">PKR {predicted_bid_pkr:,.0f}</td></tr>
                    <tr><td style="padding: 4px 0; color: #64748B;">Submission Deadline:</td><td style="padding: 4px 0; color: #0F2A4A; font-weight: 600;">{parsed_deadline}</td></tr>
                    <tr><td style="padding: 4px 0; color: #64748B;">Your Predicted Bid:</td><td style="padding: 4px 0; color: #0F2A4A; font-weight: 600;">PKR {predicted_bid_pkr:,.0f}</td></tr>
                </table>

                <table width="100%" style="margin: 32px 0; text-align: center; border-collapse: collapse;">
                    <tr>
                        <td align="center">
                            <a href="{vendor_portal_url}" style="background-color: #16A34A; color: white; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: bold; display: inline-block;">Submit Your Bid Response</a>
                        </td>
                    </tr>
                </table>

                <p style="margin: 0 0 16px 0; font-size: 15px; color: #334155; line-height: 1.5;">
                    Please refer to the attached RFP document for complete eligibility criteria, evaluation methodology (60% technical / 30% financial / 10% PPRA compliance), and mandatory clauses.
                </p>
            </td>
        </tr>
        <tr>
            <td style="border-top: 1px solid #E2E8F0; padding: 16px 24px; text-align: center;">
                <p style="margin: 0 0 4px 0; font-size: 13px; color: #94A3B8;">This is an automated invitation from the RFP Agent System.</p>
                <p style="margin: 0 0 4px 0; font-size: 13px; color: #94A3B8;">{issuing_organization} | Government of Pakistan</p>
                <p style="margin: 0; font-size: 13px; color: #94A3B8;">Reference: {reference_id}</p>
            </td>
        </tr>
    </table>
    """

    # 1. Persist to Supabase first — audit trail source of truth
    row = supabase_service.save_sent_email(
        job_id=job_id,
        to_email=vendor_email,
        to_name=vendor_name,
        subject=subject,
        body=body_text,
    )

    # 2. Attempt real delivery via Resend (best effort)
    delivery_status = "simulated"
    delivery_id = None
    delivery_error = None

    _logger.info(f"send_invitation_email called for {vendor_email}, _RESEND_ENABLED={_RESEND_ENABLED}")

    if _RESEND_ENABLED:
        try:
            if _DEMO_REDIRECT_EMAIL:
                actual_recipient = _DEMO_REDIRECT_EMAIL
                subject = f"[DEMO -> {vendor_email}] {subject}"
            else:
                actual_recipient = vendor_email

            payload = {
                "from": _RESEND_FROM,
                "to": [actual_recipient],
                "subject": subject,
                "html": body_html,
                "text": body_text,
            }
            if attachment:
                payload["attachments"] = [attachment]
            
            if _DEMO_REDIRECT_EMAIL:
                print(f"[DEMO REDIRECT] Original: {vendor_email} -> Sent to: {actual_recipient}")
            print(f"[RESEND DEBUG] job_id={job_id}, has_attachment={attachment is not None}")
            
            send_response = resend.Emails.send(payload)
            delivery_id = send_response.get("id") if isinstance(send_response, dict) else None
            delivery_status = "delivered"
            _logger.info(f"Resend delivered email to {vendor_email} (id={delivery_id})")
            print(f"[RESEND] Sent to {vendor_email}, id={delivery_id}")
        except Exception as exc:
            delivery_status = "delivery_failed"
            delivery_error = str(exc)
            _logger.warning(f"Resend delivery failed for {vendor_email}: {exc!r}")
            print(f"[RESEND ERROR] Failed for {vendor_email}: {exc!r}")
    else:
        print(f"[RESEND SKIPPED] _RESEND_ENABLED=False for {vendor_email}")

    return {
        "email_id": row["id"],
        "to_email": vendor_email,
        "to_name": vendor_name,
        "subject": subject,
        "status": row.get("status", "sent"),
        "delivery_status": delivery_status,
        "delivery_id": delivery_id,
        "delivery_error": delivery_error,
    }