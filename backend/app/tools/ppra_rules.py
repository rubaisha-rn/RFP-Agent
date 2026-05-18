"""PPRA Rules lookup tool for Agent 2 — Compliance Auditor.

This module exposes a plain Python function that ADK will auto-introspect
(name, docstring, type hints) and surface to the LLM as a callable tool.
"""

from __future__ import annotations

from app.services.supabase_client import supabase_service


def lookup_ppra_rules(category: str, estimated_value_pkr: float) -> dict:
    """Look up PPRA Rules 2004 applicable to a given category and procurement value.

    Queries the ppra_rules table and returns all rules that match both the
    procurement category AND the estimated contract value threshold.

    Matching criteria:
    - Category match: rule.category == category  OR  rule.category == "all"
      OR  rule.category == "general"
    - Value match: rule.threshold_min <= estimated_value_pkr <= rule.threshold_max

    Args:
        category: Procurement category string (e.g. "IT_services", "goods",
                  "services", "works", "consulting").
        estimated_value_pkr: Estimated contract value in Pakistani Rupees.

    Returns:
        A dict with two keys:
        - "matching_rules": list[dict] — full row dicts for every rule that
          matches both category and value threshold.  Each dict contains at
          minimum: rule_code, category, threshold_min, threshold_max,
          bidding_method, mandatory_clause.
        - "total_rules_in_db": int — total number of rules in the database
          (useful context for the LLM to gauge coverage).
    """
    all_rules: list[dict] = supabase_service.get_ppra_rules()
    total_rules_in_db = len(all_rules)

    matching_rules: list[dict] = []
    for rule in all_rules:
        # --- Category filter ---------------------------------------------------
        rule_category = (rule.get("category") or "").lower()
        input_category = (category or "").lower()
        category_match = rule_category in (input_category, "all", "general")

        # --- Value threshold filter --------------------------------------------
        threshold_min = rule.get("threshold_min")
        threshold_max = rule.get("threshold_max")

        # Treat None as unbounded (0 for min, infinity for max)
        min_ok = (threshold_min is None) or (estimated_value_pkr >= threshold_min)
        max_ok = (threshold_max is None) or (estimated_value_pkr <= threshold_max)

        if category_match and min_ok and max_ok:
            matching_rules.append(rule)

    return {
        "matching_rules": matching_rules,
        "total_rules_in_db": total_rules_in_db,
    }
