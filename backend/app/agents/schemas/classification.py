"""Pydantic v2 output schema for Agent 1 — Requirements Classifier.

NOTE: Pydantic's gt= / min_length= constraints emit JSON Schema keywords
(exclusiveMinimum, minItems) that the Gemini API schema validator does not
accept.  We use @field_validator instead to enforce those constraints at
the Python level without polluting the JSON Schema sent to the model.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator


class ClassificationOutput(BaseModel):
    """Structured output produced by the Requirements Classifier agent.

    Every field maps to a PPRA-aligned procurement attribute that downstream
    agents (Auditor, Vendor Intel, Drafter) rely on.
    """

    category: Literal["goods", "services", "works", "IT_services", "consulting"] = Field(
        ...,
        description="Procurement category aligned with PPRA classifications.",
    )
    estimated_value_pkr: float = Field(
        ...,
        description="Estimated contract value in Pakistani Rupees (must be > 0).",
    )
    urgency: Literal["low", "medium", "high"] = Field(
        ...,
        description="Urgency level of the procurement request.",
    )
    bidding_method: Literal[
        "petty_purchase",
        "request_for_quotation",
        "single_stage_one_envelope",
        "single_stage_two_envelope",
        "two_stage_bidding",
        "two_stage_two_envelope",
    ] = Field(
        ...,
        description="Recommended PPRA bidding method based on estimated value and category.",
    )
    required_certifications: list[str] = Field(
        default=[],
        description="List of certifications the vendor should hold (e.g. ISO 27001).",
    )
    delivery_timeline_days: int = Field(
        ...,
        description="Expected delivery timeline in calendar days (must be > 0).",
    )
    key_requirements: list[str] = Field(
        ...,
        description="Core requirements extracted from the brief (at least one required).",
    )
    reasoning_notes: str = Field(
        ...,
        description="Chain-of-thought summary explaining the classification decisions.",
    )

    # ------------------------------------------------------------------
    # Validators (enforced in Python; do NOT add gt=/min_length= which
    # emit JSON Schema keywords the Gemini API rejects)
    # ------------------------------------------------------------------

    @field_validator("estimated_value_pkr")
    @classmethod
    def value_must_be_positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("estimated_value_pkr must be > 0")
        return v

    @field_validator("delivery_timeline_days")
    @classmethod
    def timeline_must_be_positive(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("delivery_timeline_days must be > 0")
        return v

    @field_validator("key_requirements")
    @classmethod
    def at_least_one_requirement(cls, v: list[str]) -> list[str]:
        if not v:
            raise ValueError("key_requirements must contain at least one item")
        return v
