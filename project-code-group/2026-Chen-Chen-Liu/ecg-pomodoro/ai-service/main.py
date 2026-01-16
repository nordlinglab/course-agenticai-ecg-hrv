"""
AI prediction stub service.

Run:
  uvicorn main:app --reload --port 8002
"""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from models import EcgFeatures, AiPrediction

APP_ORIGINS = [
    "http://localhost:3000",
]

app = FastAPI(title="AI Service (stub)", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=APP_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict:
    """Health check endpoint."""
    return {"ok": True}


@app.post("/ai/predict", response_model=AiPrediction)
def predict(features: EcgFeatures) -> AiPrediction:
    """
    Return a deterministic prediction (stub).

    Rule: mean_hr_bpm >= 90 => stress else focus.
    """
    mean_hr = float(features.hrv_time.get("mean_hr_bpm", 0.0))
    if mean_hr >= 90.0:
        label = "stress"
        probs = {"focus": 0.2, "stress": 0.8}
    else:
        label = "focus"
        probs = {"focus": 0.8, "stress": 0.2}

    return AiPrediction(
        segment_id=features.segment_id,
        model={"name": "rule_stub", "version": "0.0.1"},
        label=label,
        probabilities=probs,
        explain={"used": ["hrv_time.mean_hr_bpm"]},
    )
