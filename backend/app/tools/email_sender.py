"""Tool: send (simulated) invitation emails to vendors."""

from app.services.supabase_client import supabase_service


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
    """Send (simulate) an invitation email to a single vendor and persist to sent_emails.

    The email is composed from the inputs. It is not actually delivered via SMTP —
    instead the record is written to Supabase as the canonical source of truth.
    """
    subject = f"Invitation to Bid: {rfp_title} (Ref: {reference_id})"
    body = (
        f"Dear {vendor_name} Team,\n\n"
        f"You are invited to participate in the procurement process for: {rfp_title}.\n\n"
        f"Reference ID: {reference_id}\n"
        f"Issuing Organization: {issuing_organization}\n"
        f"Submission Deadline: {submission_deadline_iso}\n"
        f"Tender Portal: {portal_url}\n\n"
        f"Based on historical bidding patterns, the expected bid range positions your "
        f"organization's typical pricing (approximately PKR {predicted_bid_pkr:,.0f}) "
        f"competitively for this opportunity.\n\n"
        f"Please refer to the attached RFP document for full eligibility criteria, "
        f"evaluation methodology, and mandatory PPRA clauses.\n\n"
        f"For further correspondence, please contact the procurement officer named in the RFP document.\n\n"
        f"Sincerely,\n"
        f"{issuing_organization} Procurement\n"
        f"(no-reply)"
    )

    row = supabase_service.save_sent_email(
        job_id=job_id,
        to_email=vendor_email,
        to_name=vendor_name,
        subject=subject,
        body=body,
    )

    return {
        "email_id": row["id"],
        "to_email": vendor_email,
        "to_name": vendor_name,
        "subject": subject,
        "status": row.get("status", "sent"),
    }
