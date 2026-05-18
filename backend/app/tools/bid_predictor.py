"""Tool: predict bid range from historical vendor avg_bid_amount."""

from statistics import median

from app.services.supabase_client import supabase_service


def predict_bid_range(category: str, estimated_value_pkr: float) -> dict:
    """Predict expected bid range (min/max/median) for a procurement category.
    
    Uses historical avg_bid_amount across active vendors in the category.
    Falls back to a +/- 15% band around the estimated value if no vendor history exists.
    
    Args:
        category: Procurement category.
        estimated_value_pkr: The estimated procurement value (used for fallback).
    
    Returns:
        {"min": float, "max": float, "median": float, "based_on_vendor_count": int,
         "method": "historical" | "estimate_fallback"}.
    """
    vendors = supabase_service.list_vendors(category=category)
    
    bids = [
        float(v.get("avg_bid_amount") or 0)
        for v in vendors
        if v.get("avg_bid_amount")
    ]
    bids = [b for b in bids if b > 0]
    
    if not bids:
        return {
            "min": round(estimated_value_pkr * 0.85, 2),
            "max": round(estimated_value_pkr * 1.15, 2),
            "median": round(estimated_value_pkr, 2),
            "based_on_vendor_count": 0,
            "method": "estimate_fallback",
        }
    
    return {
        "min": float(min(bids)),
        "max": float(max(bids)),
        "median": float(median(bids)),
        "based_on_vendor_count": len(bids),
        "method": "historical",
    }
