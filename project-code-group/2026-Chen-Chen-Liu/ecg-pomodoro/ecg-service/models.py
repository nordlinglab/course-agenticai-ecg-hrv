"""
Data contract models for ECG processing service.

These Pydantic models define the input/output JSON formats so teammates can
implement algorithms without changing the interface.
"""
from __future__ import annotations

from typing import List, Dict, Optional, Literal
from pydantic import BaseModel, Field


class Channel(BaseModel):
    """Channel metadata for a single signal channel."""

    name: str = Field(..., examples=["ECG"])
    unit: str = Field(..., examples=["adc"])
    lead: Optional[str] = Field(default=None, examples=["CH1"])


class EcgSegment(BaseModel):
    """Input payload: a short ECG segment in a unified format."""

    schema_version: Literal["ecg-seg/v1"] = "ecg-seg/v1"
    segment_id: str = Field(..., examples=["demo_1700000000000"])
    sampling_rate_hz: int = Field(..., ge=1, examples=[700])
    start_time_unix_ms: int = Field(..., examples=[1700000000000])
    channels: List[Channel]
    samples: List[List[float]] = Field(
        ...,
        description="2D array with shape [N, C]. Each row is one sample time.",
        examples=[[[30950], [31141], [31279]]],
    )


class EcgFeatures(BaseModel):
    """Output payload: extracted features from ECG segment."""

    schema_version: Literal["ecg-feat/v1"] = "ecg-feat/v1"
    segment_id: str
    quality: Dict
    rpeaks: Dict
    hrv_time: Dict
