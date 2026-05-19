"""Pydantic schema for Agent 4 — Drafter & Executor output."""

from pydantic import BaseModel, field_validator


class RFPBody(BaseModel):
    title: str
    scope_of_work: str
    eligibility_criteria: list[str]
    evaluation_criteria: list[str]
    mandatory_clauses: list[str]
    submission_deadline_iso: str        # ISO 8601 datetime
    opening_date_iso: str               # ISO 8601 datetime
    contact_info: dict                  # {name, email, phone, organization}


class EmailDispatchRecord(BaseModel):
    vendor_name: str
    email_id: str                       # UUID returned from sent_emails insert


class CalendarEventRecord(BaseModel):
    title: str
    event_id: str                       # UUID returned from calendar_events insert


class PortalPostingRecord(BaseModel):
    reference_id: str
    posting_id: str                     # UUID returned from portal_postings insert
    posted_url: str


class ExecutedActions(BaseModel):
    document_id: str                    # UUID of generated_documents row
    pdf_path: str                       # local filesystem path
    emails_sent: list[EmailDispatchRecord]
    calendar_events_created: list[CalendarEventRecord]
    portal_posting: PortalPostingRecord


class FinalRFPOutput(BaseModel):
    final_rfp: RFPBody
    executed_actions: ExecutedActions
    reasoning_notes: str

    @field_validator("reasoning_notes")
    @classmethod
    def _nonempty_notes(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("reasoning_notes must be non-empty")
        return v
