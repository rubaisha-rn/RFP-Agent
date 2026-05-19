"""Contacts route: list active vendors for the contact-select screen in the mobile app."""

from fastapi import APIRouter, Query
from app.services.supabase_client import supabase_service

router = APIRouter()


@router.get("")
def list_contacts(category: str | None = Query(default=None)) -> dict:
    vendors = supabase_service.list_vendors(category=category)
    return {
        "count": len(vendors),
        "vendors": [
            {
                "id": v["id"],
                "name": v["name"],
                "email": v["email"],
                "category": v["category"],
                "past_performance_score": v.get("past_performance_score", 0),
            }
            for v in vendors
        ],
    }
