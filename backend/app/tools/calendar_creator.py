"""Tool: create (simulated) calendar events for RFP deadlines."""

from datetime import datetime, timedelta

from app.services.supabase_client import supabase_service


def create_calendar_event(
    job_id: str,
    title: str,
    description: str,
    event_date_iso: str,
    attendee_emails: list[str],
) -> dict:
    """Create a calendar event row in calendar_events and return its id + ISO date."""
    row = supabase_service.save_calendar_event(
        job_id=job_id,
        title=title,
        description=description,
        event_date=event_date_iso,
        attendees=attendee_emails,
    )
    return {
        "event_id": row["id"],
        "title": title,
        "event_date_iso": event_date_iso,
        "attendee_count": len(attendee_emails),
    }


def compute_default_deadlines(
    delivery_timeline_days: int, base_dt: datetime | None = None
) -> dict:
    """Helper used by the agent — provides sensible default deadlines.
    Submission deadline = max(21, delivery_timeline_days / 4) days from base_dt.
    Pre-bid meeting    = submission_deadline - 14 days.
    Opening date       = submission_deadline + 1 day.
    """
    base = base_dt or datetime.utcnow()
    sub_offset = max(21, delivery_timeline_days // 4)
    submission = base + timedelta(days=sub_offset)
    pre_bid = submission - timedelta(days=14)
    if pre_bid < base + timedelta(days=3):
        pre_bid = base + timedelta(days=3)
    opening = submission + timedelta(days=1)
    return {
        "pre_bid_meeting_iso": pre_bid.isoformat(timespec="minutes"),
        "submission_deadline_iso": submission.isoformat(timespec="minutes"),
        "opening_date_iso": opening.isoformat(timespec="minutes"),
    }
