"""Tool: vendor conflict-of-interest check. Pure-Python, no Supabase call."""


CRITICAL_FLAG_PREFIXES = ("blacklisted", "criminal", "fraud", "sanctioned")
SOFT_FLAG_KEYWORDS = ("pending_litigation", "previous_dispute", "late_delivery", "warning")


def run_conflict_check(vendor_id: str, vendor_name: str, vendor_conflict_flags: list[str]) -> dict:
    """Check a vendor for conflicts of interest.
    
    Critical flags disqualify a vendor entirely. Soft flags are surfaced but the
    vendor may still appear in the shortlist (with a warning).
    
    Args:
        vendor_id: Vendor UUID.
        vendor_name: Vendor display name.
        vendor_conflict_flags: The vendor's conflict_flags array from the database.
    
    Returns:
        {"vendor_id", "vendor_name", "status", "reasons"}
        status is one of: "clear", "soft_flag", "critical".
    """
    flags = vendor_conflict_flags or []
    
    critical_reasons = [
        f for f in flags if any(f.startswith(p) for p in CRITICAL_FLAG_PREFIXES)
    ]
    soft_reasons = [
        f for f in flags if any(k in f for k in SOFT_FLAG_KEYWORDS)
    ]
    
    if critical_reasons:
        status = "critical"
        reasons = critical_reasons
    elif soft_reasons:
        status = "soft_flag"
        reasons = soft_reasons
    else:
        status = "clear"
        reasons = []
    
    return {
        "vendor_id": vendor_id,
        "vendor_name": vendor_name,
        "status": status,
        "reasons": reasons,
    }
