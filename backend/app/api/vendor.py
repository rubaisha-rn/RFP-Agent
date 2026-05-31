"""Vendor portal endpoints for RFP Agent System."""

import bcrypt
import json
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from typing import List, Optional

from app.services.supabase_client import supabase_service

router = APIRouter()

def now():
    return datetime.now(timezone.utc).isoformat()

class VendorSignupRequest(BaseModel):
    company_name: str
    email: EmailStr
    password: str
    ntn_number: str
    categories: List[str]

class VendorAuthResponse(BaseModel):
    vendor_id: str
    company_name: str
    email: str
    category: Optional[str] = None

@router.post("/signup", response_model=VendorAuthResponse)
def signup(req: VendorSignupRequest):
    if len(req.password) < 6:
        raise HTTPException(status_code=400, detail="password must be 6+ chars")
    
    # Look up existing row
    existing = supabase_service.client.table("vendors").select("*").eq("email", req.email).execute()
    
    pw_hash = bcrypt.hashpw(req.password.encode(), bcrypt.gensalt()).decode()
    
    if existing.data:
        if any(v.get("password_hash") is not None for v in existing.data):
            raise HTTPException(status_code=409, detail="Vendor already registered with this email")
        else:
            vendor = existing.data[0]
            # Seeded vendor self-registering
            updated = supabase_service.client.table("vendors").update({
                "password_hash": pw_hash,
                "registered_at": now(),
                "is_self_registered": True
            }).eq("id", vendor["id"]).execute()
            
            updated_vendor = updated.data[0]
            return VendorAuthResponse(
                vendor_id=updated_vendor["id"],
                company_name=updated_vendor["name"],
                email=updated_vendor["email"],
                category=updated_vendor.get("category")
            )
    else:
        # Insert a new vendor
        cat = req.categories[0] if req.categories else "Uncategorized"
        
        row = supabase_service.client.table("vendors").insert({
            "name": req.company_name,
            "email": req.email,
            "category": cat,
            "password_hash": pw_hash,
            "registered_at": now(),
            "is_self_registered": True,
            "conflict_flags": [],
            "past_performance_score": 3.5,
            "blacklisted": False,
            "registration_status": "active",
            "avg_bid_amount": 0,
            "ntn_number": req.ntn_number
        }).execute()
        
        new_vendor = row.data[0]
        return VendorAuthResponse(
            vendor_id=new_vendor["id"],
            company_name=new_vendor["name"],
            email=new_vendor["email"],
            category=new_vendor.get("category")
        )

class VendorLoginRequest(BaseModel):
    email: EmailStr
    password: str

@router.post("/login", response_model=VendorAuthResponse)
def login(req: VendorLoginRequest):
    res = supabase_service.client.table("vendors").select("*").eq("email", req.email).execute()
    if not res.data:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    vendor = res.data[0]
    if not vendor.get("password_hash"):
        raise HTTPException(status_code=401, detail="Vendor not registered. Please sign up first.")
        
    if not bcrypt.checkpw(req.password.encode(), vendor["password_hash"].encode()):
        raise HTTPException(status_code=401, detail="Invalid credentials")
        
    return VendorAuthResponse(
        vendor_id=vendor["id"],
        company_name=vendor["name"],
        email=vendor["email"],
        category=vendor.get("category")
    )


@router.get("/inbox/{vendor_id}")
def get_inbox(vendor_id: str):
    res = supabase_service.client.table("vendors").select("*").eq("id", vendor_id).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Vendor not found")
        
    vendor = res.data[0]
    
    emails_res = supabase_service.client.table("sent_emails").select("*").eq("to_email", vendor["email"]).order("sent_at", desc=True).execute()
    
    invitations = []
    
    for email in emails_res.data:
        job_id = email.get("job_id")
        
        # We don't crash over one missing join lookup
        try:
            # Try to get RFP details
            job_res = supabase_service.client.table("rfp_jobs").select("status, brief").eq("id", job_id).execute()
            # Portal postings
            portal_res = supabase_service.client.table("portal_postings").select("reference_id, title").eq("job_id", job_id).execute()
            # Vendor responses
            resp_res = supabase_service.client.table("vendor_responses").select("bid_amount_pkr").eq("vendor_id", vendor_id).eq("job_id", job_id).execute()
            
            ref_id = portal_res.data[0].get("reference_id") if portal_res.data else None
            rfp_title = portal_res.data[0].get("title") if portal_res.data and portal_res.data[0].get("title") else "Untitled RFP"
            
            has_responded = len(resp_res.data) > 0
            bid_amount_pkr = resp_res.data[0].get("bid_amount_pkr") if has_responded else None
            
            invitations.append({
                "job_id": job_id,
                "reference_id": ref_id,
                "rfp_title": rfp_title,
                "received_at": email.get("sent_at"),
                "submission_deadline": None,
                "estimated_value_pkr": None,
                "has_responded": has_responded,
                "bid_amount_pkr": bid_amount_pkr
            })
        except Exception:
            invitations.append({
                "job_id": job_id,
                "reference_id": None,
                "rfp_title": "Untitled RFP",
                "received_at": email.get("sent_at"),
                "submission_deadline": None,
                "estimated_value_pkr": None,
                "has_responded": False,
                "bid_amount_pkr": None
            })
            
    return {
        "vendor": {"id": vendor["id"], "company_name": vendor["name"], "email": vendor["email"]},
        "invitations": invitations
    }


@router.get("/rfp/{job_id}")
def get_rfp_details(job_id: str):
    doc_res = supabase_service.client.table("generated_documents").select("*").eq("job_id", job_id).order("created_at", desc=True).execute()
    if not doc_res.data:
        raise HTTPException(status_code=404, detail="RFP not found")
        
    doc = doc_res.data[0]
    content_json = doc.get("content_json") or {}
    
    if isinstance(content_json, str):
        try:
            content_json = json.loads(content_json)
        except json.JSONDecodeError:
            content_json = {}
            
    portal_res = supabase_service.client.table("portal_postings").select("reference_id, posted_url").eq("job_id", job_id).execute()
    reference_id = portal_res.data[0].get("reference_id") if portal_res.data else None
    
    contact_info = content_json.get("contact_info", {})
    issuing_org = contact_info.get("organization") if isinstance(contact_info, dict) else None
    
    return {
        "job_id": job_id,
        "reference_id": reference_id,
        "title": content_json.get("title"),
        "scope_of_work": content_json.get("scope_of_work"),
        "eligibility_criteria": content_json.get("eligibility_criteria", []),
        "evaluation_criteria": content_json.get("evaluation_criteria", []),
        "mandatory_clauses": content_json.get("mandatory_clauses", []),
        "submission_deadline_iso": content_json.get("submission_deadline_iso"),
        "opening_date_iso": content_json.get("opening_date_iso"),
        "contact_info": contact_info,
        "pdf_download_url": f"/documents/{doc['id']}/download",
        "issuing_organization": issuing_org
    }


class VendorRespondRequest(BaseModel):
    vendor_id: str
    job_id: str
    bid_amount_pkr: float
    technical_summary: str


@router.post("/respond")
def respond_rfp(req: VendorRespondRequest):
    # Validate vendor
    vendor_res = supabase_service.client.table("vendors").select("id").eq("id", req.vendor_id).execute()
    if not vendor_res.data:
        raise HTTPException(status_code=404, detail="Vendor not found")
        
    # Validate job
    job_res = supabase_service.client.table("rfp_jobs").select("id").eq("id", req.job_id).execute()
    if not job_res.data:
        raise HTTPException(status_code=404, detail="Job not found")
        
    if req.bid_amount_pkr <= 0:
        raise HTTPException(status_code=400, detail="Bid amount must be positive")
        
    if len(req.technical_summary) < 50:
        raise HTTPException(status_code=400, detail="Technical summary must be at least 50 characters")
        
    # Check if already submitted
    existing = supabase_service.client.table("vendor_responses").select("id").eq("vendor_id", req.vendor_id).eq("job_id", req.job_id).execute()
    if existing.data:
        raise HTTPException(status_code=409, detail="You have already submitted a response to this RFP")
        
    sub_time = now()
    try:
        row = supabase_service.client.table("vendor_responses").insert({
            "vendor_id": req.vendor_id,
            "job_id": req.job_id,
            "bid_amount_pkr": req.bid_amount_pkr,
            "technical_summary": req.technical_summary,
            "status": "submitted",
            "submitted_at": sub_time
        }).execute()
        
        response_data = row.data[0]
        
        return {
            "response_id": response_data["id"],
            "vendor_id": response_data["vendor_id"],
            "job_id": response_data["job_id"],
            "bid_amount_pkr": response_data["bid_amount_pkr"],
            "status": response_data["status"],
            "submitted_at": response_data["submitted_at"]
        }
    except Exception as e:
        if "unique" in str(e).lower():
            raise HTTPException(status_code=409, detail="You have already submitted a response to this RFP")
        raise HTTPException(status_code=500, detail=str(e))
