"""Onboarding (signup + login) for the procurement officer."""

import bcrypt
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr

from app.services.supabase_client import supabase_service

router = APIRouter()


class SignupRequest(BaseModel):
    company_email: EmailStr
    password: str
    company_name: str


class AuthResponse(BaseModel):
    organization_id: str
    company_name: str
    company_email: str
    is_onboarded: bool


@router.post("/signup", response_model=AuthResponse)
def signup(req: SignupRequest):
    if len(req.password) < 6:
        raise HTTPException(status_code=400, detail="password must be 6+ chars")
    existing = supabase_service.client.table("organizations").select("id").eq("company_email", req.company_email).execute()
    if existing.data:
        raise HTTPException(status_code=409, detail="company already registered")
    pw_hash = bcrypt.hashpw(req.password.encode(), bcrypt.gensalt()).decode()
    row = supabase_service.client.table("organizations").insert({
        "company_email": req.company_email,
        "company_name": req.company_name,
        "password_hash": pw_hash,
        "is_onboarded": False,
    }).execute()
    org = row.data[0]
    return AuthResponse(organization_id=org["id"], company_name=org["company_name"], company_email=org["company_email"], is_onboarded=org["is_onboarded"],)


class LoginRequest(BaseModel):
    company_email: EmailStr
    password: str


@router.post("/login", response_model=AuthResponse)
def login(req: LoginRequest):
    res = supabase_service.client.table("organizations").select("*").eq("company_email", req.company_email).execute()
    if not res.data:
        raise HTTPException(status_code=401, detail="invalid credentials")
    org = res.data[0]
    if not bcrypt.checkpw(req.password.encode(), org["password_hash"].encode()):
        raise HTTPException(status_code=401, detail="invalid credentials")
    return AuthResponse(organization_id=org["id"], company_name=org["company_name"], company_email=org["company_email"], is_onboarded=org.get("is_onboarded", True),)

@router.post("/complete-onboarding")
def complete_onboarding(body: dict):
    organization_id = body.get("organization_id")
    if not organization_id:
        raise HTTPException(status_code=400, detail="organization_id required")
    supabase_service.client.table("organizations").update(
        {"is_onboarded": True}
    ).eq("id", organization_id).execute()
    return {"success": True}
