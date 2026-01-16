"""
Data contract models for AI service.

Input: EcgFeatures
Output: AiPrediction
"""
from __future__ import annotations

from typing import Dict, Optional, Literal
from pydantic import BaseModel, Field


class EcgFeatures(BaseModel):
    schema_version: Literal["ecg-feat/v1"] = "ecg-feat/v1"
    segment_id: str
    quality: Dict
    rpeaks: Dict
    hrv_time: Dict


class AiPrediction(BaseModel):
    schema_version: Literal["ai-pred/v1"] = "ai-pred/v1"
    segment_id: str
    model: Dict = Field(default_factory=dict)
    label: str
    probabilities: Dict[str, float]
    explain: Optional[Dict] = None
