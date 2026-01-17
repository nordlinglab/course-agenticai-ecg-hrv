"""
AI prediction stub service.

Run:
  uvicorn main:app --reload --port 8002
"""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import google.generativeai as genai
import os
from dotenv import load_dotenv
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

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    MODEL = genai.GenerativeModel("gemini-2.0-flash")

@app.get("/health")
def health() -> dict:
    """Health check endpoint."""
    return {"ok": True}


@app.post("/ai/predict", response_model=AiPrediction)
def predict(features: EcgFeatures) -> AiPrediction:
    """
    Use Gemini to provide health suggestions based on ECG data.
    """
    # Extract relevant ECG metrics
    hrv_time = features.hrv_time or {}
    mean_hr = float(hrv_time.get("mean_hr_bpm", 0.0))
    rpeaks = features.rpeaks or {}
    quality = features.quality or {}
    
    # Build prompt for Gemini
    prompt = f"""
    Analyze the following ECG data and provide health suggestions:
    
    - Mean Heart Rate: {mean_hr} BPM
    - Rpeaks Data: {json.dumps(rpeaks, indent=2)}
    - Quality Score: {json.dumps(quality, indent=2)}
    
    Based on this data, provide:
    1. A classification: either "stress" or "focus" (stress if HR >= 90, focus otherwise)
    2. 2-3 practical health suggestions for the user
    3. Any concerning patterns to note
    
    Format your response as JSON with keys: classification, suggestions (list), concerns (list)
    """
    try:
        # Call Gemini API
        response = MODEL.generate_content(prompt)
        gemini_response = response.text
        
        # Parse the response (expecting JSON format)
        try:
            result = json.loads(gemini_response)
            label = result.get("classification", "focus")
            suggestions = result.get("suggestions", [])
            concerns = result.get("concerns", [])
        except json.JSONDecodeError:
            # Fallback if response isn't valid JSON
            label = "stress" if mean_hr >= 90.0 else "focus"
            suggestions = [gemini_response[:200]]
            concerns = []
        
        # Set probabilities based on classification
        probs = {"focus": 0.2, "stress": 0.8} if label == "stress" else {"focus": 0.8, "stress": 0.2}
        
        return AiPrediction(
            segment_id=features.segment_id,
            model={"name": "gemini-pro", "version": "1.0.0"},
            label=label,
            probabilities=probs,
            explain={
                "suggestions": suggestions,
                "concerns": concerns,
                "mean_hr_bpm": mean_hr,
            },
        )
    except Exception as e:
        # Fallback to simple rule-based if API fails
        if mean_hr >= 90.0:
            label = "stress"
            probs = {"focus": 0.2, "stress": 0.8}
        else:
            label = "focus"
            probs = {"focus": 0.8, "stress": 0.2}
        
        return AiPrediction(
            segment_id=features.segment_id,
            model={"name": "rule_fallback", "version": "0.0.1"},
            label=label,
            probabilities=probs,
            explain={"error": str(e), "used": ["hrv_time.mean_hr_bpm"]},
        )