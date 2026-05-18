"""Pydantic v2 output schema for Agent 2 — Compliance Auditor.

NOTE: Pydantic's gt= / min_length= / min_items= constraints emit JSON Schema
keywords (exclusiveMinimum, minItems, maxItems, etc.) that the Gemini API
schema validator rejects.  We use @field_validator instead to enforce those
constraints at the Python level without polluting the JSON Schema sent to
the model.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator


class ComplianceOutput(BaseModel):
    """Structured compliance scorecard produced by the Compliance Auditor agent.

    This is the authoritative PPRA ruling: it corrects any mis-classifications
    from the Classifier and sets the procurement method that downstream agents
    (Vendor Intel, Drafter) must use.
    """

    applicable_rule_codes: list[str] = Field(
        ...,
        description=(
            "List of PPRA rule codes that apply to this procurement "
            "(e.g. ['PPRA-R36a', 'PPRA-R20A']).  Must contain at least one entry."
        ),
    )
    confirmed_bidding_method: Literal[
        "petty_purchase",
        "request_for_quotation",
        "single_stage_one_envelope",
        "single_stage_two_envelope",
        "two_stage_bidding",
        "two_stage_two_envelope",
    ] = Field(
        ...,
        description=(
            "PPRA-authoritative bidding method derived from the rules lookup. "
            "This overrides the Classifier's suggested method when they differ."
        ),
    )
    mandatory_clauses: list[str] = Field(
        ...,
        description=(
            "Full text of mandatory clauses required by the applicable rules. "
            "Must contain at least one entry."
        ),
    )
    compliance_score: float = Field(
        ...,
        description="Compliance score from 0 (fully non-compliant) to 100 (fully compliant).",
    )
    advertisement_requirements: dict[str, bool] = Field(
        ...,
        description=(
            "Advertisement channels required by PPRA for this procurement. "
            "Expected keys: ppra_website, english_newspaper, urdu_newspaper."
        ),
    )
    bid_validity_days: int = Field(
        ...,
        description="Minimum bid validity period in calendar days as required by PPRA (must be > 0).",
    )
    integrity_pact_required: bool = Field(
        ...,
        description="Whether an integrity pact is mandatory (typically true for procurements above PKR 10 million).",
    )
    issues_flagged: list[str] = Field(
        default=[],
        description="List of compliance issues or warnings identified during audit.",
    )
    reasoning_notes: str = Field(
        ...,
        description="Chain-of-thought explanation of how the compliance determination was reached.",
    )

    # ------------------------------------------------------------------
    # Validators — enforced in Python; do NOT add gt=/min_length= which
    # emit JSON Schema keywords the Gemini API rejects.
    # ------------------------------------------------------------------

    @field_validator("advertisement_requirements", mode="before")
    @classmethod
    def normalise_ad_requirements(cls, v: object) -> dict:
        """Coerce string values to bool and ensure required keys are present.

        The LLM may return string values like "true" / "yes" / "Print media"
        instead of actual booleans.  We map these defensively so validation
        does not crash on a string-typed value.
        """
        if not isinstance(v, dict):
            # If the model returned a plain string (old prompt format), default all
            return {"ppra_website": True, "english_newspaper": True, "urdu_newspaper": False}

        _TRUTHY = {"true", "yes", "1", "required", "mandatory", "print media and ppra website"}

        result: dict[str, bool] = {}
        for key, val in v.items():
            if isinstance(val, bool):
                result[key] = val
            elif isinstance(val, (int, float)):
                result[key] = bool(val)
            elif isinstance(val, str):
                result[key] = val.strip().lower() in _TRUTHY
            else:
                result[key] = bool(val)

        # Ensure the three canonical keys exist (default False if absent)
        for canonical in ("ppra_website", "english_newspaper", "urdu_newspaper"):
            result.setdefault(canonical, False)

        return result

    @field_validator("applicable_rule_codes")
    @classmethod
    def at_least_one_rule(cls, v: list[str]) -> list[str]:
        if not v:
            raise ValueError("applicable_rule_codes must contain at least one rule code")
        return v

    @field_validator("mandatory_clauses")
    @classmethod
    def at_least_one_clause(cls, v: list[str]) -> list[str]:
        if not v:
            raise ValueError("mandatory_clauses must contain at least one clause")
        return v

    @field_validator("compliance_score")
    @classmethod
    def score_in_range(cls, v: float) -> float:
        if not (0 <= v <= 100):
            raise ValueError("compliance_score must be between 0 and 100 inclusive")
        return v

    @field_validator("bid_validity_days")
    @classmethod
    def validity_must_be_positive(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("bid_validity_days must be > 0")
        return v
