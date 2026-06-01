"""Tool: post the RFP to the (simulated) PPRA e-Pak portal."""

import secrets
from datetime import datetime

from app.services.supabase_client import supabase_service


def post_to_portal(
    job_id: str,
    title: str,
    closing_date_iso: str,
    issuing_organization: str,
) -> dict:
    """Post the RFP to the PPRA portal and return a reference_id + posting_id.

    Reference ID format: PPRA-YYYY-MMDD-XXXXX (last 5 are a hex token).
    """
    today = datetime.utcnow()
    token = secrets.token_hex(3).upper()
    reference_id = f"PPRA-{today.year}-{today.month:02d}{today.day:02d}-{token}"
    posted_url = f"https://rfp-agent-system.netlify.app/#/vendor/rfp/{job_id}"

    row = supabase_service.save_portal_posting(
        job_id=job_id,
        reference_id=reference_id,
        title=title,
        posted_url=posted_url,
        closing_date=closing_date_iso,
    )

    return {
        "posting_id": row["id"],
        "reference_id": reference_id,
        "posted_url": posted_url,
        "portal_name": row.get("portal_name", "PPRA e-Pak"),
        "status": row.get("status", "live"),
    }
