"""Tool: vendor database query. Exposed to Agent 3 (Vendor Intelligence)."""

from app.services.supabase_client import supabase_service

# Related-category fallback so we never return an empty vendor list
RELATED_CATEGORIES = {
    "IT_services": ["IT_services", "services"],
    "services": ["services", "IT_services", "consulting"],
    "consulting": ["consulting", "services"],
    "goods": ["goods"],
    "works": ["works"],
}


def query_vendors(category: str) -> dict:
    """Query active (non-blacklisted) vendors for a given procurement category.
    
    Falls back to related categories if no vendors match the exact category.
    
    Args:
        category: Procurement category (goods, services, works, IT_services, consulting).
    
    Returns:
        {"vendors": list[dict], "count": int, "category_searched": str}.
        Each vendor dict contains: id, name, email, category, past_performance_score,
        avg_bid_amount, conflict_flags, registration_status.
    """
    vendors = supabase_service.list_vendors(category=category)
    
    # Fallback to related categories if empty
    used_fallback = False
    if not vendors:
        for fallback_cat in RELATED_CATEGORIES.get(category, []):
            if fallback_cat == category:
                continue
            vendors = supabase_service.list_vendors(category=fallback_cat)
            if vendors:
                used_fallback = True
                category = fallback_cat
                break
    
    # Strip out fields the agent doesn't need to reason about
    cleaned = [
        {
            "id": v["id"],
            "name": v["name"],
            "email": v["email"],
            "category": v["category"],
            "past_performance_score": v.get("past_performance_score", 0),
            "avg_bid_amount": v.get("avg_bid_amount", 0),
            "conflict_flags": v.get("conflict_flags", []),
            "registration_status": v.get("registration_status", "active"),
        }
        for v in vendors
    ]
    
    return {
        "vendors": cleaned,
        "count": len(cleaned),
        "category_searched": category,
        "used_related_category_fallback": used_fallback,
    }
