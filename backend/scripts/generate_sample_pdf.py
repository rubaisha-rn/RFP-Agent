import sys
from pathlib import Path

# Add backend dir to python path
sys.path.append(str(Path(__file__).resolve().parent))

from app.tools.pdf_generator import generate_rfp_pdf

def test_v3():
    job_id = "test-12345"
    title = "Punjab Citizen Services Portal"
    reference_id = "PPRA-2026-XYZ"
    scope_of_work = "We need a digital citizen services portal for the Punjab government. Cloud-hosted, must support Urdu and English, integrate with NADRA API for identity verification. Budget around 2.5 million PKR. Required within 90 days."
    eligibility_criteria = ["Must be valid company", "At least 5 years experience"]
    evaluation_criteria = ["Price 30%", "Tech 70%"]
    mandatory_clauses = ["Integrity pact required", "No blacklisting"]
    submission_deadline_iso = "2026-06-30T12:00:00Z"
    opening_date_iso = "2026-06-30T14:00:00Z"
    contact_name = "Jane Doe"
    contact_email = "jane@punjab.gov.pk"
    contact_organization = "Government of Punjab"

    # Call the actual function
    res = generate_rfp_pdf(
        job_id=job_id,
        title=title,
        reference_id=reference_id,
        scope_of_work=scope_of_work,
        eligibility_criteria=eligibility_criteria,
        evaluation_criteria=evaluation_criteria,
        mandatory_clauses=mandatory_clauses,
        submission_deadline_iso=submission_deadline_iso,
        opening_date_iso=opening_date_iso,
        contact_name=contact_name,
        contact_email=contact_email,
        contact_organization=contact_organization,
    )
    
    # Rename output
    import os
    import shutil
    
    generated_file = res["file_path"]
    target_file = Path(generated_file).parent / "sample_full_v3.pdf"
    
    shutil.copy(generated_file, target_file)
    print(f"Generated successfully: {target_file}")

if __name__ == "__main__":
    test_v3()
