"""
ECG processing stub service.

- Provides a stable request/response interface for the team.
- Algorithm is placeholder (MVP): returns deterministic fake peaks/features.

Run:
  uvicorn main:app --reload --port 8001
"""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from models import EcgSegment, EcgFeatures

APP_ORIGINS = [
    "http://localhost:3000",  # CRA dev server
]

app = FastAPI(title="ECG Service (stub)", version="0.1.0")

# Enable browser calls from React (CORS)
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


def _placeholder_rpeaks(sample_count: int, sampling_rate_hz: int) -> list[int]:
    """
    Generate fake R-peak indices for testing pipeline.

    Strategy: one peak per second at 0.5s offset.
    """
    step = sampling_rate_hz
    start = int(0.5 * sampling_rate_hz)
    return list(range(start, sample_count, step))


@app.post("/ecg/features", response_model=EcgFeatures)
def ecg_features(segment: EcgSegment) -> EcgFeatures:
    """
    Convert ECG segment to features (stub).

    Teammates can replace this implementation with NeuroKit2 or other pipelines
    as long as the response_model is preserved.
    """
    n = len(segment.samples)
    peaks = _placeholder_rpeaks(n, segment.sampling_rate_hz)

    mean_hr = float(len(peaks)) * 60.0 / (n / float(segment.sampling_rate_hz)) if n > 0 else 0.0

    return EcgFeatures(
        segment_id=segment.segment_id,
        quality={"signal_ok": True, "missing_ratio": 0.0, "notes": ["stub"]},
        rpeaks={"indices": peaks, "method": "stub"},
        hrv_time={"mean_hr_bpm": round(mean_hr, 2), "rmssd_ms": 0.0, "sdnn_ms": 0.0},
    )
