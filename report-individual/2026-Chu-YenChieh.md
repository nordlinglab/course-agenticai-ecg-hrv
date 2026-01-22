# Technical Report: Agentic ECG HRV Baseline Evaluation System

**Author:** 2026-Chu-YenChieh
**Group Members:** Chu YenChieh, Lin ChihYi, Lin WenHsin
**License:** CC-BY-4.0

## Abstract

This report details the development of an **Agentic ECG HRV Baseline Evaluation System**, designed to address the "Personalization Gap" in physiological monitoring. Traditional health monitoring systems often rely on universal thresholds that fail to account for individual variances and activity states. Our solution implements a modular agentic architecture where a central **Orchestrator** coordinates specialized tools—including an **Adaptive Analyzer** and a **Quality Validator**—to process signals dynamically. A key innovation is the **Profile Store**, which maintains individualized baselines (stored in `baselines.json`), enabling the system to contextualize signal quality. Validated on a dataset of mixed activities, the system demonstrated the ability to autonomously differentiate valid physiological stress from motion artifacts, significantly reducing the manual burden of data review.

## Introduction

In the field of wearable health monitoring, distinguishing between genuine physiological anomalies and motion artifacts is a persistent challenge.

### The Problem: The Personalization Gap
Most current systems use static, hard-coded thresholds for signal quality and Heart Rate Variability (HRV) metrics. This leads to two critical failures:

> 1.  **False Positives in Active States:** High heart rates during exercise are often misclassified as anomalies.
> 2.  **Individual Incompatibility:** A "normal" baseline for a sedentary individual may trigger alarms for an athlete.

### Objectives
Our group aimed to construct an AI Agent that bridges this gap by:
* **Contextualizing Data:** Recognizing the user's activity state (e.g., Static vs. Biking).
* **Personalizing Evaluation:** Using historical personal data to evaluate new signals.
* **Automating Workflow:** Employing an agentic workflow to handle the end-to-end process.

## System Architecture

The system adopts a modular agentic design to ensure separation of concerns. The data flow and component interaction are visualized below:
```mermaid
graph TD
    %% Nodes
    Orchestrator[<< Agent >>\nOrchestrator]
    ContextLoader[<< Tool >>\nContext Loader]
    AdaptiveAnalyzer[<< Tool >>\nAdaptive Analyzer]
    ProfileStore[<< Database >>\nProfile Store]
    RPeakDetector[R-Peak Detector]
    QualityValidator[<< Tool >>\nQuality Validator]
    ResultGenerator[<< Tool >>\nResult Generator]
    Report[<< Artifact >>\nmd Report]

    %% Connections
    Orchestrator -->|Initiates| ContextLoader
    ContextLoader -->|Raw Data| AdaptiveAnalyzer
    ProfileStore -->|Baselines| AdaptiveAnalyzer
    AdaptiveAnalyzer -->|Signal| RPeakDetector
    RPeakDetector -->|Peaks| AdaptiveAnalyzer
    AdaptiveAnalyzer -->|Features| QualityValidator
    QualityValidator -->|Status| ResultGenerator
    ResultGenerator -->|Generates| 
```

## Implementation

The system implementation was divided among group members. My primary focus was on the Data and Profile Management modules.

* **data-group:** Managed dataset curation and the schema for the **Profile Store**.
* **project-code-group:** Contained the core logic for the Orchestrator and Tools.
* **tests-group:** Housed the validation suite.

## Individual Contribution: Data & Profile Management

My primary contribution (as part of the Data-group) was the design and implementation of the **Profile Store** mechanism. Instead of hard-coding thresholds, I implemented a `baselines.json` structure that the Agent reads at runtime.

**Key Logic:**
When the **Context Loader** reads a file (e.g., `subject_01_bike.csv`), the agent follows this sequence:

1.  **Identify:** Extract Subject ID and Activity from metadata.
2.  **Query:** Fetch the corresponding baseline object from **Profile Store**.
3.  **Inject:** Pass these personalized parameters to the **Adaptive Analyzer**.

This approach enables the **Quality Validator** to apply dynamic, context-aware logic:

# Pseudo-code logic for Quality Validator
if (Current_RMSSD < Personal_Baseline_RMSSD * 0.5) and (Activity == 'Rest'):
    return "Flag as Low Quality / Potential Anomaly"
else:
    return "Pass"

## Results

We evaluated the system using a real-world dataset comprising different subjects and activity intensities. The key findings are categorized by subject and activity below:

* **First Person - Static (Rest):**
    * **Pass Rate:** 100%
    * **Analysis:** The signal consistently matched the personal resting baseline, validating the Profile Store's accuracy for rest states.

* **First Person - Bike (Active):**
    * **Pass Rate:** 89.5%
    * **Analysis:** The system correctly adapted thresholds for high heart rates. Traditional static thresholds would have rejected these valid exercise signals, but our context-aware agent accepted them.

* **First Person - Rotate (Noise/Artifacts):**
    * **Pass Rate:** 0%
    * **Analysis:** This was a critical success. The Quality Validator correctly identified excessive motion artifacts in every window and rejected them, preventing data pollution.

* **Second Person - Static:**
    * **Pass Rate:** 60-100%
    * **Analysis:** The system successfully detected outliers in specific windows where signal quality dropped, demonstrating sensitivity to individual variations.

## Discussion

### Trade-offs: Reasoning vs. Latency
One challenge encountered was the trade-off between the depth of the agent's reasoning and processing speed. Calling the LLM to interpret every validation step provided excellent explainability but increased latency. We optimized this by caching the **Profile Store** data to reduce redundant lookups.

### Limitations
* **Static Profiles:** Currently, `baselines.json` is static. The system does not yet support "Online Learning" to update baselines automatically.
* **Dependency on Formatting:** The **Context Loader** is sensitive to file naming conventions, requiring strict data governance.


## Conclusion

We successfully developed and validated an Agentic ECG HRV Evaluation System. By decoupling the decision logic into a personalized **Profile Store**, we achieved a system that is flexible and rigorous. The architecture allows for scalable health monitoring that respects individual physiological differences, successfully meeting the project's goal of closing the Personalization Gap.

## References
Gemini
Python,  NumPy, Pandas, or SciPy documentation