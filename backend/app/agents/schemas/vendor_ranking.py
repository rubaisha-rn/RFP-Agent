"""Pydantic schema for Agent 3 — Vendor Intelligence output."""

from typing import Literal
from pydantic import BaseModel, field_validator


class VendorRanked(BaseModel):
    vendor_id: str
    name: str
    email: str
    score: float  # 0..5 weighted score
    predicted_bid_pkr: float
    conflict_status: Literal["clear", "soft_flag", "critical"]


class BidRange(BaseModel):
    min: float
    max: float
    median: float


class VendorRankingOutput(BaseModel):
    shortlist: list[VendorRanked]
    predicted_bid_range_pkr: BidRange
    conflicts_flagged: list[dict]  # [{"vendor_name": str, "flag": str}]
    total_vendors_evaluated: int
    reasoning_notes: str

    @field_validator("shortlist")
    @classmethod
    def _shortlist_size(cls, v: list[VendorRanked]) -> list[VendorRanked]:
        if len(v) < 1:
            raise ValueError("shortlist must contain at least one vendor")
        if len(v) > 5:
            # Truncate gracefully rather than fail outright
            return v[:5]
        return v

    @field_validator("total_vendors_evaluated")
    @classmethod
    def _evaluated_non_negative(cls, v: int) -> int:
        if v < 0:
            raise ValueError("total_vendors_evaluated must be >= 0")
        return v
