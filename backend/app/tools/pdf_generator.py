"""Tool: generate the RFP PDF using reportlab."""

import re
from datetime import datetime
from functools import partial
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, ListFlowable, ListItem, PageBreak, Table, TableStyle
)


# Output dir for generated PDFs (gitignored)
OUTPUT_DIR = Path(__file__).resolve().parents[2] / "output" / "rfp_pdfs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def _add_header_footer(canvas, doc, reference_id, contact_organization):
    canvas.saveState()
    canvas.setFont('Helvetica', 9)
    # Header
    header_text = f"Reference: {reference_id} | Page {doc.page}"
    canvas.drawString(2 * cm, A4[1] - 1.5 * cm, header_text)
    
    # Footer
    footer_text = f"{contact_organization} | Government of Pakistan | Confidential"
    canvas.drawString(2 * cm, 1.0 * cm, footer_text)
    canvas.restoreState()


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
    title_style = ParagraphStyle(
        "RFPTitle", parent=styles["Title"], fontSize=24, spaceAfter=20, textColor=colors.HexColor("#0F2A4A")
    )
    h1_style = ParagraphStyle(
        "RFPH1", parent=styles["Heading1"], fontSize=16, spaceBefore=18, spaceAfter=10, textColor=colors.HexColor("#0F2A4A")
    )
    h2_style = ParagraphStyle(
        "RFPH2", parent=styles["Heading2"], fontSize=13, spaceBefore=12, spaceAfter=6, textColor=colors.HexColor("#0F2A4A")
    )
    body_style = ParagraphStyle("RFPBody", parent=styles["BodyText"], fontSize=10.5, leading=15)
    center_style = ParagraphStyle("RFPCenter", parent=body_style, alignment=1)

    doc = SimpleDocTemplate(
        str(file_path),
        pagesize=A4,
        title=title,
        leftMargin=2 * cm, rightMargin=2 * cm,
        topMargin=2.5 * cm, bottomMargin=2.5 * cm,
    )

    story = []

    # 1. COVER PAGE
    story.append(Spacer(1, 4 * cm))
    story.append(Paragraph("<b>GOVERNMENT OF PAKISTAN</b>", title_style))
    story.append(Spacer(1, 1 * cm))
    story.append(Paragraph(f"<b>{contact_organization.upper()}</b>", ParagraphStyle("Org", parent=title_style, fontSize=28)))
    story.append(Spacer(1, 2 * cm))
    story.append(Paragraph("REQUEST FOR PROPOSAL", ParagraphStyle("RFP", parent=title_style, fontSize=20, textColor=colors.black)))
    story.append(Spacer(1, 1 * cm))
    story.append(Paragraph(title, title_style))
    story.append(Spacer(1, 2 * cm))
    story.append(Paragraph(f"<b>Reference ID:</b> {reference_id}", center_style))
    story.append(Paragraph(f"<b>Date Issued:</b> {datetime.utcnow().strftime('%Y-%m-%d')}", center_style))
    story.append(Spacer(1, 2 * cm))
    story.append(Paragraph("<i>INVITATION TO BID</i>", ParagraphStyle("Invite", parent=center_style, fontSize=14)))
    story.append(PageBreak())

    # 2. NOTICE & TENDER REFERENCE
    story.append(Paragraph("NOTICE & TENDER REFERENCE", h1_style))
    story.append(Paragraph("This is an official notice for the procurement of services as described below. All eligible bidders are invited to submit their proposals in accordance with the PPRA Rules.", body_style))
    story.append(Spacer(1, 0.5*cm))
    sentences = [s.strip() for s in re.split(r'(?<=[.!?])\s+', scope_of_work) if s.strip()]
    short_desc = sentences[0] if sentences else (scope_of_work[:100] + "...")
    if len(short_desc) > 150:
        short_desc = short_desc[:147] + "..."

    data = [
        ["PPRA Reference ID", reference_id],
        ["Project Title", title],
        ["Project Description", Paragraph(short_desc, body_style)],
        ["Bid Security", "2% of the estimated bid value"],
        ["Bid Validity", "90 days from submission deadline"],
    ]
    t = Table(data, colWidths=[5*cm, 10*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t)
    story.append(PageBreak())

    # 2.5 GLOSSARY
    story.append(Paragraph("GLOSSARY OF TERMS", h1_style))
    glossary = [
        ["Term", "Definition"],
        ["RFP", "Request for Proposal"],
        ["PPRA", "Public Procurement Regulatory Authority"],
        ["QCBS", "Quality and Cost Based Selection"],
        ["NTN", "National Tax Number"],
        ["PRA", "Punjab Revenue Authority"],
        ["GoP", "Government of Pakistan"],
        ["SLA", "Service Level Agreement"],
        ["UAT", "User Acceptance Testing"],
    ]
    t_glos = Table(glossary, colWidths=[4*cm, 11*cm])
    t_glos.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F2A4A")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('PADDING', (0,0), (-1,-1), 6),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.lightgrey])
    ]))
    story.append(t_glos)
    story.append(PageBreak())

    # 3. SECTION 1: INTRODUCTION & BACKGROUND
    story.append(Paragraph("SECTION 1: INTRODUCTION & BACKGROUND", h1_style))
    story.append(Paragraph("<b>1.1 Procurement Need Justification</b>", h2_style))
    story.append(Paragraph(f"The {contact_organization} requires {title} to fulfill its strategic objectives. This procurement addresses the critical need for modernization and efficiency.", body_style))
    story.append(Paragraph("<b>1.2 Strategic Context</b>", h2_style))
    story.append(Paragraph("The strategic context of this procurement is aligned with the national digital transformation goals. By implementing these solutions, the government aims to enhance service delivery and ensure robust infrastructure. This aligns with broader governance and technology modernization frameworks adopted at the federal and provincial levels.", body_style))
    story.append(Paragraph("<b>1.3 Expected Outcomes</b>", h2_style))
    story.append(Paragraph("1. Enhanced operational efficiency.<br/>2. Seamless integration with existing infrastructure.<br/>3. Robust security and compliance.<br/>4. High availability and performance.", body_style))
    story.append(PageBreak())

    # 4. SECTION 2: SCOPE OF WORK (2 pages)
    story.append(Paragraph("SECTION 2: SCOPE OF WORK", h1_style))
    story.append(Paragraph("<b>2.1 Detailed Scope</b>", h2_style))
    story.append(Paragraph(scope_of_work, body_style))
    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("The successful bidder will be responsible for the end-to-end delivery of the project, including planning, design, implementation, and support. The scope encompasses all necessary hardware, software, and services required to achieve the project goals. The bidder must ensure strict adherence to industry best practices and standards.", body_style))
    
    story.append(Paragraph("<b>2.2 Functional Requirements</b>", h2_style))
    
    key_requirements = []
    try:
        from app.services.supabase_client import supabase_service
        traces = supabase_service.list_traces(job_id)
        for t in traces:
            if t.get("agent_name") == "classifier" and t.get("output_data"):
                key_requirements = t["output_data"].get("key_requirements", [])
                break
    except Exception:
        pass

    if not key_requirements:
        key_requirements = ["citizen portal", "cloud hosting", "Urdu/English support", "NADRA integration"]

    for i, req in enumerate(key_requirements, 1):
        req_clean = req.strip()
        if not req_clean:
            continue
        
        lower_req = req_clean.lower()
        if lower_req.startswith("the system"):
            sentence = req_clean
        elif req_clean.split()[0] in {"Provide", "Ensure", "Support", "Integrate", "Allow", "Generate", "Include", "Maintain"}:
            sentence = f"The system shall {lower_req}"
        elif lower_req == "citizen portal":
            sentence = "The system shall provide a citizen-facing portal"
        elif lower_req == "cloud hosting":
            sentence = "The system shall be cloud-hosted with high availability"
        elif lower_req == "urdu/english support":
            sentence = "The system shall support both Urdu and English interfaces"
        elif lower_req == "nadra integration":
            sentence = "The system shall integrate with the NADRA API for identity verification"
        else:
            verb = "incorporate"
            if "portal" in lower_req: verb = "provide"
            elif "host" in lower_req: verb = "be"
            elif "support" in lower_req: verb = "support"
            elif "integrat" in lower_req: verb = "integrate with"
            sentence = f"The system shall {verb} {lower_req}"
            
        if not sentence.endswith("."):
            sentence += "."
            
        story.append(Paragraph(f"FR-{i}: {sentence}", body_style))

    if len(key_requirements) < 3:
        supplements = [
            "The system shall comply with PPRA data residency requirements.",
            "The system shall provide audit logging of all transactions."
        ]
        start_idx = len(key_requirements) + 1
        for i, supp in enumerate(supplements, start_idx):
            story.append(Paragraph(f"FR-{i}: {supp}", body_style))
    
    story.append(PageBreak())
    
    story.append(Paragraph("<b>2.3 Non-Functional Requirements</b>", h2_style))
    story.append(Paragraph("<b>Security:</b> The solution must comply with national cybersecurity frameworks. Data must be encrypted at rest and in transit.", body_style))
    story.append(Paragraph("<b>Performance:</b> The system must handle high concurrent user loads with sub-second response times.", body_style))
    story.append(Paragraph("<b>Scalability:</b> Architecture must be horizontally scalable to accommodate future growth.", body_style))
    story.append(Paragraph("Furthermore, the system should incorporate automated backup and disaster recovery mechanisms to ensure zero data loss and minimal downtime in the event of failure.", body_style))
    
    story.append(Paragraph("<b>2.4 Integration Requirements</b>", h2_style))
    story.append(Paragraph("The proposed solution must seamlessly integrate with existing legacy systems and third-party APIs via RESTful services or SOAP where applicable. It must also support secure API gateways and handle authentication protocols (OAuth2, SAML).", body_style))
    
    story.append(Paragraph("<b>2.5 Deliverables Timeline</b>", h2_style))
    deliverables = [
        ["Phase", "Milestone", "Timeline"],
        ["Phase 1", "Inception & Requirements Sign-off", "Week 2"],
        ["Phase 2", "Architecture & Design Approval", "Week 4"],
        ["Phase 3", "Implementation & Integration", "Week 8"],
        ["Phase 4", "UAT & Production Go-Live", "Week 12"],
    ]
    t_del = Table(deliverables, colWidths=[3*cm, 9*cm, 3*cm])
    t_del.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F2A4A")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.lightgrey])
    ]))
    story.append(t_del)
    story.append(PageBreak())

    # 5. SECTION 3: ELIGIBILITY REQUIREMENTS
    story.append(Paragraph("SECTION 3: ELIGIBILITY REQUIREMENTS", h1_style))
    story.append(Paragraph("Bidders must meet the following mandatory eligibility requirements to be considered for evaluation:", body_style))
    story.append(Spacer(1, 0.3*cm))
    all_eligibility = [
        "Valid FBR NTN Registration",
        "Valid PRA (Punjab Revenue Authority) Registration",
        "PSEB Registration (for IT services)",
        "Minimum 3 similar projects successfully completed in the last 5 years",
        "Minimum annual turnover equal to 2x the estimated project value",
        "Declaration of No Conflict of Interest",
    ] + eligibility_criteria
    story.append(ListFlowable([ListItem(Paragraph(c, body_style)) for c in all_eligibility], bulletType="bullet"))
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Failure to provide documentary evidence for any of the above requirements will result in immediate disqualification of the bid. The procuring agency reserves the right to verify the authenticity of the provided documents from the issuing authorities.", body_style))
    story.append(PageBreak())

    # 6. SECTION 4: EVALUATION METHODOLOGY
    story.append(Paragraph("SECTION 4: EVALUATION METHODOLOGY", h1_style))
    story.append(Paragraph("The evaluation will be conducted based on the Quality and Cost Based Selection (QCBS) method.", body_style))
    story.append(Paragraph("<b>4.1 Technical Evaluation (60 Marks)</b>", h2_style))
    tech_data = [
        ["Criteria", "Max Marks"],
        ["Past Experience", "15"],
        ["Methodology & Approach", "15"],
        ["Team Composition", "15"],
        ["Compliance & Certifications", "15"],
        ["Total Technical", "60"]
    ]
    t2 = Table(tech_data, colWidths=[10*cm, 4*cm])
    t2.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F2A4A")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('GRID', (0,0), (-1,-1), 1, colors.black),
    ]))
    story.append(t2)
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("<b>Detailed Breakdown of Technical Scoring:</b>", h2_style))
    story.append(Paragraph("<b>Past Experience (15 Marks):</b> Bidders will be awarded 3 marks for each similar project completed in the public sector over the last 5 years. Maximum 15 marks.", body_style))
    story.append(Paragraph("<b>Methodology & Approach (15 Marks):</b> The technical proposal will be evaluated on the clarity, completeness, and feasibility of the proposed approach. A highly detailed work plan scores 15.", body_style))
    story.append(Paragraph("<b>Team Composition (15 Marks):</b> Key personnel must include a Project Manager (PMP certified), Lead Architect, and QA Specialist. 5 marks per key role meeting requirements.", body_style))
    story.append(Paragraph("<b>Compliance & Certifications (15 Marks):</b> ISO 9001 and ISO 27001 certifications grant 7.5 marks each. Lack of these will result in zero marks for this section.", body_style))
    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("<i>Minimum technical qualifying score is 70% (42/60).</i>", body_style))
    
    story.append(PageBreak())
    story.append(Paragraph("<b>4.2 Financial Evaluation (30 Marks)</b>", h2_style))
    story.append(Paragraph("The lowest evaluated financial proposal will be awarded the maximum financial score. Other proposals will be scored inversely proportional to the lowest bid.", body_style))
    story.append(Paragraph("<b>4.3 PPRA Compliance (10 Marks)</b>", h2_style))
    story.append(Paragraph("Bidders will be evaluated on strict adherence to PPRA rules, submission of required affidavits, and compliance with all statutory requirements.", body_style))
    story.append(Spacer(1, 0.5*cm))
    if evaluation_criteria:
        story.append(Paragraph("<b>Additional Criteria:</b>", h2_style))
        story.append(ListFlowable([ListItem(Paragraph(c, body_style)) for c in evaluation_criteria], bulletType="bullet"))
    story.append(PageBreak())

    # 7. SECTION 5: MANDATORY PPRA CLAUSES
    story.append(Paragraph("SECTION 5: MANDATORY PPRA CLAUSES", h1_style))
    story.append(Paragraph("The following mandatory clauses as per the Public Procurement Regulatory Authority (PPRA) Rules apply to this tender:", body_style))
    story.append(Spacer(1, 0.3*cm))
    if not mandatory_clauses:
        story.append(Paragraph("No specific mandatory clauses provided.", body_style))
    else:
        for clause in mandatory_clauses:
            story.append(Paragraph(f"<b>Clause:</b> {clause}", body_style))
            story.append(Spacer(1, 0.2*cm))
    
    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Further to the aforementioned clauses, the procuring agency emphasizes that all bidding processes will be conducted in a manner that promotes competition and value for money. Integrity pacts, if required by law for the given threshold, must be signed and submitted along with the technical proposal.", body_style))
    story.append(PageBreak())

    # 8. SECTION 6: SUBMISSION REQUIREMENTS
    story.append(Paragraph("SECTION 6: SUBMISSION REQUIREMENTS", h1_style))
    story.append(Paragraph("Bidders must adhere to the following instructions for bid submission:", body_style))
    story.append(ListFlowable([
        ListItem(Paragraph("Bids must be submitted in 1 Original and 2 Copies, sealed in separate envelopes marked 'Technical' and 'Financial'.", body_style)),
        ListItem(Paragraph(f"Physical submission address: {contact_organization}", body_style)),
        ListItem(Paragraph("Online submission (if applicable) must be done via the official PPRA/e-procurement portal.", body_style)),
        ListItem(Paragraph("A Bid Security of 2% must be enclosed with the financial proposal.", body_style)),
        ListItem(Paragraph("Proposals shall remain valid for a period of 90 days from the submission deadline.", body_style)),
    ], bulletType="bullet"))
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Late bids will be rejected and returned unopened. The procuring agency will not be responsible for any delays caused by courier services or technical glitches in the online portal. Ensure all documents are properly signed and stamped by an authorized signatory.", body_style))
    story.append(PageBreak())

    # 9. SECTION 7: SCHEDULE OF EVENTS
    story.append(Paragraph("SECTION 7: SCHEDULE OF EVENTS", h1_style))
    events_data = [
        ["Event", "Date / Time"],
        ["Publication of RFP", datetime.utcnow().strftime('%Y-%m-%d')],
        ["Pre-Bid Meeting", "TBD"],
        ["Last Date for Queries", "7 days before submission"],
        ["Submission Deadline", submission_deadline_iso],
        ["Bid Opening", opening_date_iso],
        ["Evaluation Period", "14 days after opening"],
        ["Contract Award", "TBD"]
    ]
    t3 = Table(events_data, colWidths=[8*cm, 7*cm])
    t3.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F2A4A")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.lightgrey])
    ]))
    story.append(t3)
    story.append(PageBreak())

    # 10. SECTION 8: CONTACT & ANNEXURES
    story.append(Paragraph("SECTION 8: CONTACT INFORMATION", h1_style))
    story.append(Paragraph("<b>8.1 Contact Details</b>", h2_style))
    story.append(Paragraph(f"<b>Procurement Officer:</b> {contact_name}", body_style))
    story.append(Paragraph(f"<b>Email:</b> {contact_email}", body_style))
    story.append(Paragraph(f"<b>Organization:</b> {contact_organization}", body_style))
    story.append(Paragraph("<b>Helpline:</b> +92-XXX-XXXXXXX", body_style))
    
    # ANNEXURE A
    story.append(PageBreak())
    story.append(Paragraph("ANNEXURE A: Bid Submission Form", h1_style))
    story.append(Paragraph("Please fill out this form and attach it as the first page of your proposal.", body_style))
    story.append(Spacer(1, 0.5*cm))
    form_data = [
        ["Company Name", "________________________________________________"],
        ["Address", "________________________________________________"],
        ["NTN Number", "________________________________________________"],
        ["Contact Person", "________________________________________________"],
        ["Email", "________________________________________________"],
        ["Phone", "________________________________________________"],
        ["Total Bid Amount (PKR)", "________________________________________________"],
        ["Bid Validity", "________________________________________________"],
        ["Authorized Signature", "________________________________________________"],
        ["Date", "________________________________________________"],
        ["Company Seal", "[ Affix Seal Here ]"]
    ]
    t_a = Table(form_data, colWidths=[5*cm, 10*cm])
    t_a.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('PADDING', (0,0), (-1,-1), 8),
        ('BACKGROUND', (0,0), (0,-1), colors.lightgrey),
    ]))
    story.append(t_a)
    
    # ANNEXURE B
    story.append(PageBreak())
    story.append(Paragraph("ANNEXURE B: Financial Proposal Format", h1_style))
    story.append(Paragraph("The financial proposal must be structured as follows. Prices must include all applicable taxes.", body_style))
    story.append(Spacer(1, 0.5*cm))
    fin_data = [
        ["Item Description", "Unit", "Qty", "Unit Price", "Total Price"],
        ["Core Platform Development", "Lump Sum", "1", "", ""],
        ["Multilingual Support", "Lump Sum", "1", "", ""],
        ["3rd Party Integrations", "Modules", "3", "", ""],
        ["Cloud Hosting & Infrastructure", "Months", "12", "", ""],
        ["Support and Maintenance", "Months", "12", "", ""],
        ["", "", "", "Grand Total:", ""]
    ]
    t_b = Table(fin_data, colWidths=[6.5*cm, 2*cm, 1.5*cm, 2.5*cm, 2.5*cm])
    t_b.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0F2A4A")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_b)
    
    # ANNEXURE C
    story.append(PageBreak())
    story.append(Paragraph("ANNEXURE C: Vendor Declaration", h1_style))
    story.append(Spacer(1, 0.5*cm))
    decl_text = (
        "I, ________________________________, on behalf of ________________________________, "
        "hereby declare that:<br/><br/>"
        "(1) Our company has not been blacklisted by any government agency.<br/>"
        "(2) All information provided in this bid is true and correct.<br/>"
        "(3) We agree to abide by the PPRA Rules 2004 and all terms in this RFP.<br/>"
        "(4) We have no conflict of interest with the procuring agency.<br/>"
        "(5) We accept the Integrity Pact if applicable.<br/><br/><br/><br/>"
        "Signed: ____________________ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Date: ____________________"
    )
    story.append(Paragraph(decl_text, body_style))

    header_footer = partial(_add_header_footer, reference_id=reference_id, contact_organization=contact_organization)
    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)

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
