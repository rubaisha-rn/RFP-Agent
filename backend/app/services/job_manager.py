"""Job manager service for API responses."""

from app.services.supabase_client import supabase_service

def get_job_status(job_id: str) -> dict:
    """Return synthetic job status with computed progress_pct."""
    res = supabase_service.client.table("rfp_jobs").select("*").eq("id", job_id).execute()
    if not res.data:
        raise ValueError("not found")
        
    job = res.data[0]
    traces = supabase_service.list_traces(job_id)
    
    # Compute progress pct
    progress_map = {
        "classifier": 25,
        "auditor": 50,
        "vendor_intel": 75,
        "drafter": 90
    }
    
    pct = 0
    if job.get("status") == "completed":
        pct = 100
    elif job.get("status") == "failed":
        pct = 0
    elif job.get("current_agent"):
        pct = progress_map.get(job["current_agent"], 0)
        
    return {
        "job_id": job["id"],
        "status": job["status"],
        "current_agent": job.get("current_agent"),
        "brief": job.get("brief"),
        "created_at": job.get("created_at"),
        "completed_at": job.get("completed_at"),
        "progress_pct": pct,
        "trace_count": len(traces)
    }

def get_job_full(job_id: str) -> dict:
    """Return full state for the results screen."""
    res = supabase_service.client.table("rfp_jobs").select("*").eq("id", job_id).execute()
    if not res.data:
        raise ValueError("not found")
    
    job = res.data[0]
    traces = supabase_service.list_traces(job_id)
    
    docs_res = supabase_service.client.table("generated_documents").select("*").eq("job_id", job_id).order("created_at").execute()
    emails_res = supabase_service.client.table("sent_emails").select("*").eq("job_id", job_id).order("sent_at").execute()
    events_res = supabase_service.client.table("calendar_events").select("*").eq("job_id", job_id).order("created_at").execute()
    portal_res = supabase_service.client.table("portal_postings").select("*").eq("job_id", job_id).order("posted_at").execute()
    
    document = docs_res.data[-1] if docs_res.data else None
    portal_posting = portal_res.data[0] if portal_res.data else None
    
    responses_res = supabase_service.client.table("vendor_responses") \
        .select("*, vendors(name, email)") \
        .eq("job_id", job_id) \
        .order("submitted_at", desc=True) \
        .execute()
    
    return {
        "job": job,
        "traces": traces,
        "document": document,
        "emails": emails_res.data,
        "calendar_events": events_res.data,
        "portal_posting": portal_posting,
        "vendor_responses": responses_res.data
    }
