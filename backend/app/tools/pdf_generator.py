"""Tool: generate the RFP PDF using reportlab."""

from datetime import datetime
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, ListFlowable, ListItem, PageBreak
)


# Output dir for generated PDFs (gitignored)
OUTPUT_DIR = Path(__file__).resolve().parents[2] / "output" / "rfp_pdfs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_rfp_pdf(
    job_id: str,
    title: str,
    reference_id: str,
    scope_of_work: str,
    eligibility_criteria: list[str],
    evaluation_criteria: list[str],
    mandatory_clauses: list[str],
    submission_deadline_iso: str,
    opening_date_iso: str,
    contact_name: str,
    contact_email: str,
    contact_organization: str,
) -> dict:
    """Render a PPRA-compliant RFP PDF using reportlab.

    Saves to backend/output/rfp_pdfs/<job_id>.pdf and returns the local path and a
    simulated pdf_url.

    Returns:
        {"file_path": str, "pdf_url": str, "filename": str, "page_count_estimate": int}
    """
    filename = f"RFP_{reference_id}_{job_id[:8]}.pdf"
    file_path = OUTPUT_DIR / filename

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("RFPTitle", parent=styles["Title"], fontSize=18, spaceAfter=12)
    h2_style = ParagraphStyle("RFPH2", parent=styles["Heading2"], fontSize=13, spaceBefore=12, spaceAfter=6)
    body_style = ParagraphStyle("RFPBody", parent=styles["BodyText"], fontSize=10.5, leading=15)

    doc = SimpleDocTemplate(
        str(file_path),
        pagesize=A4,
        title=title,
        leftMargin=2 * cm, rightMargin=2 * cm,
        topMargin=2 * cm, bottomMargin=2 * cm,
    )

    story: list = []

    story.append(Paragraph(title, title_style))
    story.append(Paragraph(f"<b>Reference ID:</b> {reference_id}", body_style))
    story.append(Paragraph(f"<b>Issued:</b> {datetime.utcnow().strftime('%Y-%m-%d')}", body_style))
    story.append(Paragraph(f"<b>Issuing Organization:</b> {contact_organization}", body_style))
    story.append(Spacer(1, 0.5 * cm))

    story.append(Paragraph("1. Scope of Work", h2_style))
    story.append(Paragraph(scope_of_work, body_style))

    story.append(Paragraph("2. Eligibility Criteria", h2_style))
    story.append(ListFlowable(
        [ListItem(Paragraph(c, body_style)) for c in eligibility_criteria],
        bulletType="bullet",
    ))

    story.append(Paragraph("3. Evaluation Criteria", h2_style))
    story.append(ListFlowable(
        [ListItem(Paragraph(c, body_style)) for c in evaluation_criteria],
        bulletType="bullet",
    ))

    story.append(Paragraph("4. Mandatory PPRA Clauses", h2_style))
    story.append(ListFlowable(
        [ListItem(Paragraph(c, body_style)) for c in mandatory_clauses],
        bulletType="bullet",
    ))

    story.append(Paragraph("5. Key Dates", h2_style))
    story.append(Paragraph(f"<b>Submission Deadline:</b> {submission_deadline_iso}", body_style))
    story.append(Paragraph(f"<b>Bid Opening Date:</b> {opening_date_iso}", body_style))

    story.append(Paragraph("6. Contact Information", h2_style))
    story.append(Paragraph(f"<b>Procurement Officer:</b> {contact_name}", body_style))
    story.append(Paragraph(f"<b>Email:</b> {contact_email}", body_style))
    story.append(Paragraph(f"<b>Organization:</b> {contact_organization}", body_style))

    doc.build(story)

    pdf_url = f"file://{file_path.as_posix()}"

    return {
        "file_path": str(file_path),
        "pdf_url": pdf_url,
        "filename": filename,
        "page_count_estimate": max(1, len(story) // 12),
    }


def save_document_record(
    job_id: str,
    file_path: str,
    pdf_url: str,
    content_json: dict,
) -> dict:
    """Persist the generated PDF metadata to generated_documents.
    Returns {"document_id": <uuid>, "saved_at_iso": <ts>}.
    """
    from app.services.supabase_client import supabase_service

    row = supabase_service.save_document(
        job_id=job_id,
        document_type="rfp",
        file_path=file_path,
        pdf_url=pdf_url,
        content_json=content_json,
    )
    return {
        "document_id": row["id"],
        "saved_at_iso": row.get("created_at"),
    }
