# Technical Report: ECG-Pomodoro

**Author:** Liu Yung-Hsin
**Group Members:** Chen Guo-Zhu, Chen Kun-Yu, Liu Yung-Hsin
**License:** CC-BY-4.0

## Abstract

This report details the design and implementation of ECG-Pomodoro, an AI-powered web application aimed at mitigating developer burnout by integrating physiological monitoring into the Pomodoro workflow. The system architecture comprises a React frontend that serves as the user interface and orchestrator, a Python FastAPI service for real-time ECG signal processing and feature extraction, and a second FastAPI service that leverages a Large Language Model (Google's Gemini) to generate personalized wellness advice. The ECG service uses the NeuroKit2 library to analyze simulated ECG data, extracting key Heart Rate Variability (HRV) metrics such as SDNN and RMSSD. These structured physiological features are then passed to the AI service, which provides actionable recommendations to the user during their rest periods. The project successfully demonstrates a proof-of-concept for converting raw biosensor data into timely, context-aware, and AI-driven interventions to support developer well-being.

## Introduction

Software development is a cognitively demanding field where engineers often experience "Tunnel Vision," a state of intense focus that leads them to ignore signs of stress and fatigue. As outlined in the project's case brief, this chronic disregard for physiological well-being can result in decreased code quality and long-term burnout. While wearable technology can track metrics like heart rate, it often fails to provide context-aware interpretations or actionable guidance within a developer's workflow.

The ECG-Pomodoro project addresses this gap by creating an intelligent system that not only manages work and rest intervals but also incorporates physiological feedback. The primary objectives are to:
1.  **Monitor Physiological State:** Analyze ECG signals captured during a work session to quantify stress and fatigue levels.
2.  **Extract Actionable Insights:** Convert complex ECG waveforms into understandable HRV metrics.
3.  **Provide AI-Driven Guidance:** Use the extracted metrics to generate personalized, actionable advice to help users effectively recover during rest periods.
4.  **Integrate Seamlessly:** Embed this functionality within the familiar structure of a Pomodoro timer to minimize workflow disruption.

## System Architecture

The system is designed as a microservices architecture, separating the user interface, signal processing, and AI reasoning into three distinct components. This modular design enhances scalability and maintainability.

```
┌──────────────────┐      ┌────────────────────────┐      ┌─────────────────────┐
│                  │ (1)  │                        │ (3)  │                     │
│  React Frontend  │ ───▶ │   ECG Service (API)    │ ───▶ │   AI Service (API)  │
│ (UI & Orchestrator)│      │  (FastAPI, NeuroKit2)  │      │(FastAPI, Gemini LLM)│
│                  │◀──── │                        │ ◀────│                     │
└──────────────────┘ (2)  └────────────────────────┘ (4)  └─────────────────────┘
```

**Workflow:**
1.  The **React Frontend** simulates the collection of ECG data in segments throughout a Pomodoro work session.
2.  At the end of the work session, the frontend sends the collected segments to the **ECG Service** via a `POST` request to `/ecg/pomodoro/end`.
3.  The ECG Service processes the raw data, extracts HRV features, and returns a `PomodoroWorkSummary` JSON object.
4.  The frontend receives the summary and immediately sends it to the **AI Service** via a `POST` request to `/ai/pomodoro/advice`.
5.  The AI Service uses the physiological summary to generate personalized advice and returns an `AiAdvice` JSON object, which the frontend then displays to the user.

### Component Descriptions

| Component | Type | Description |
|-----------|------|-------------|
| **React Frontend** | UI/Orchestrator | A web-based Pomodoro timer that manages `WORK`, `REST`, and `PAUSE` states. It simulates ECG data collection and orchestrates API calls to the backend services. |
| **ECG Service** | Tool/API | A FastAPI service that serves as a signal processing pipeline. It accepts raw ECG segments, uses the `NeuroKit2` library to perform cleaning, R-peak detection, and computes time-domain HRV features (e.g., RMSSD, SDNN). |
| **AI Service** | Tool/API | A FastAPI service that acts as the decision-making layer. It receives the structured HRV features and uses a hybrid strategy—a Gemini LLM for nuanced advice generation, with a rule-based system as a fallback—to produce actionable recommendations. |

## Implementation

The project leverages modern web and data science technologies to create a cohesive system.

### Frontend (React)

The user interface is a single-page application built with React.
-   **State Management:** A `useReducer` hook manages the Pomodoro state machine, transitioning between `HOME`, `CONFIG`, `WORK`, `PAUSE`, and `REST` states.
-   **Data Simulation:** For this MVP, real ECG hardware is replaced by a `makeDemoEcgSegment` function. During a `WORK` session, this function is called periodically to generate realistic-looking ECG signal segments with different characteristics for "stress" or "relax" modes.
-   **Orchestration:** Upon transitioning from `WORK` to `REST`, `useEffect` hooks trigger the two-step API call process: first to the ECG service to get a summary, and then to the AI service with that summary to get advice. Error handling is included to display messages if API calls fail.

### ECG Service (Python, FastAPI, NeuroKit2)

This service is responsible for the heavy lifting of biosignal analysis.
-   **API Endpoint:** The core endpoint is `POST /ecg/pomodoro/end`. It accepts a `PomodoroWorkRequest` containing a list of `EcgSegment` objects.
-   **Signal Processing:** The service uses the powerful `neurokit2` library to process each segment. The `_process_segment` function performs the following key steps:
    1.  **Cleaning:** Applies `nk.ecg_clean` to filter the raw signal.
    2.  **Peak Detection:** Uses `nk.ecg_peaks` to find the locations of R-peaks, which are essential for HRV analysis.
    3.  **HRV Calculation:** Calculates RR-intervals (the time between R-peaks) and derives key time-domain HRV metrics, including `mean_hr_bpm`, `rmssd_ms`, and `sdnn_ms`.
-   **Data Aggregation:** It aggregates the features from all segments into a single `PomodoroWorkSummary`, providing a holistic view of the user's physiological state over the entire work period.

### AI Service (Python, FastAPI, Gemini)

This service translates quantitative physiological data into qualitative, human-readable advice.
-   **API Endpoint:** The `POST /ai/pomodoro/advice` endpoint receives the `PomodoroWorkSummary`.
-   **Hybrid Logic:** The service implements a robust hybrid approach:
    1.  **LLM-Powered Advice:** If a `GEMINI_API_KEY` is configured and the signal quality is sufficient (`signal_ok: true`), it constructs a detailed prompt for the `gemini-2.5-flash-lite` model. The prompt instructs the AI to act as a "pomodoro rest suggestion assistant" and generate a JSON object with a title and bullet points for actionable advice, based on the provided metrics.
    2.  **Rule-Based Fallback:** If the LLM is unavailable or the signal quality is poor, the service falls back to a simple, rule-based system. For instance, if the mean heart rate exceeds 90 bpm, it suggests "降壓休息" (Stress-reduction rest). This ensures the application remains functional and provides basic guidance even without AI.
-   **Safe JSON Parsing:** The service includes helper functions to safely parse the LLM's text output, ensuring it conforms to the expected JSON structure before sending it back to the client.

## Results

The primary result of the system is its ability to complete the full data-to-advice pipeline. At the end of a work session, the user is presented with a set of recommendations tailored to their physiological state during that session.

**Example Output (LLM-Generated):**

Given a `PomodoroWorkSummary` indicating high heart rate and low HRV (`mean_hr_bpm: 92`, `sdnn_ms: 28`), the AI service might produce the following `AiAdvice`:

```json
{
  "segment_id": "pomodoro_1678886400000",
  "title": "建議：降壓休息",
  "bullets": [
    "做 4-6 呼吸 1 分鐘，讓心率回落。",
    "起身走動 1–2 分鐘，離開螢幕。",
    "下一輪工作前，先喝杯水並伸展肩頸。"
  ],
  "safety_note": "此建議僅供專題展示，不可用於醫療判斷。",
  "used_metrics": {
    "mean_hr_bpm": 92,
    "sdnn_ms": 28,
    "rmssd_ms": 18,
    "used_llm": true
  }
}
```

This output demonstrates the system's success in translating quantitative metrics into concrete, actionable steps for the user, fulfilling the project's core objective.

## Discussion

### Challenges and Solutions
-   **Real-time Data:** A key challenge was the absence of a live ECG sensor. This was addressed by creating a robust simulation on the frontend that generates realistic data, allowing for end-to-end testing of the backend pipeline.
-   **Domain Knowledge:** ECG analysis is a specialized field. We leveraged the `neurokit2` library, which encapsulates established algorithms for filtering and feature extraction, saving significant development time and ensuring a degree of scientific validity.
-   **LLM Reliability:** LLMs can be non-deterministic and may not always return perfectly formatted JSON. The AI service mitigates this by wrapping the LLM call in a `try-except` block and including a secondary regex-based parser to extract a valid JSON object from the raw text response. The rule-based fallback provides a final layer of resilience.

### Limitations
-   **Simulated Data:** The most significant limitation is the use of simulated ECG data. The system has not been tested with real-world signals, which would introduce challenges like motion artifacts and sensor noise.
-   **Simplified Model:** The physiological model is a proof-of-concept. The rule-based fallback relies only on mean heart rate, and the LLM prompt, while detailed, is based on general knowledge. A production system would require a more sophisticated model trained on labeled data.
-   **Incomplete Vision:** The current implementation only focuses on providing advice during rest periods. It does not yet include the proactive interventions or IDE/Git integration envisioned in the original case brief.

### Lessons Learned
-   **Microservices for Clarity:** The separation of concerns into three services was highly effective. It allowed the frontend to focus on UI/UX, the ECG service on complex signal processing, and the AI service on reasoning and language generation.
-   **The Power of Libraries:** Specialized libraries like `neurokit2` are invaluable for tackling domain-specific problems, allowing developers to build on top of existing scientific work.
-   **Hybrid AI-Rule-Based Systems:** Combining LLMs with deterministic, rule-based systems creates more robust and reliable applications. The fallback mechanism ensures a baseline level of functionality, which is critical for user-facing products.

## Conclusion

The ECG-Pomodoro project successfully demonstrates the feasibility of an AI-powered wellness tool integrated into a developer's workflow. By creating a seamless pipeline from (simulated) physiological signals to personalized, actionable advice, the system serves as a strong proof-of-concept for the "Agentic AI Code Development Guardian." It effectively translates abstract biometric data into tangible guidance, empowering users to take proactive steps toward managing stress and preventing burnout.

### Future Work
-   **Hardware Integration:** The next logical step is to replace the data simulation with a real-time data stream from a Bluetooth-enabled ECG sensor (e.g., a Polar H10).
-   **Personalized Baselines:** Implement functionality to establish and track a user's baseline HRV metrics over time, allowing for more accurate and personalized stress detection.
-   **Expanded Agentic Actions:** Build out the other features from the case brief, such as proactive alerts, guided breathing exercises, and AI-assisted code commit generation.
-   **Model Refinement:** Collect labeled data to train a dedicated machine learning model for more accurate stress classification, reducing reliance on simple rules or generic LLM knowledge.

## References

1.  Makowski, D., Pham, T., Lau, Z. J., Brammer, J. C., & Lespinasse, F. (2021). NeuroKit2: A Python toolbox for neurophysiological signal processing. *Behavior Research Methods*, 53(4), 1689-1696.
2.  FastAPI Documentation. (https://fastapi.tiangolo.com/)
3.  Google AI. Gemini API Documentation. (https://ai.google.dev/docs/gemini_api_overview)
4.  React Documentation. (https://react.dev/)
