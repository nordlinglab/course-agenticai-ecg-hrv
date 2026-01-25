# Individual Technical Report  
## Multi-dimensional Automated ECG Feature Extraction and Analysis System

**Author:** Cheng-Yu Fan  
**Group:** 2026-Fan-Lee-Liu  
**License:** CC-BY-4.0  

---

## Abstract

Electrocardiogram (ECG) analysis plays a critical role in cardiovascular diagnosis and long-term health monitoring. However, traditional ECG analysis workflows rely heavily on manual inspection and semi-automated tools, resulting in high labor cost and inconsistent outcomes. This project presents an agent-based AI system for automated ECG signal processing and multi-dimensional feature extraction, including time-domain, frequency-domain, and morphological metrics. By decomposing the ECG analysis pipeline into specialized agents, the system enables efficient, reproducible, and scalable heart rate variability (HRV) assessment and stress-level evaluation. Experimental results and test suites demonstrate that the proposed agentic approach significantly reduces analysis time while maintaining reliable physiological interpretation.

---

## 1. Introduction

ECG signal interpretation is widely used in clinical diagnosis, telemedicine services, and wearable health monitoring devices. Physicians commonly rely on features such as beats per minute (BPM), heart rate variability (HRV), LF/HF ratios, and S-T segment deviations to evaluate cardiac rhythm, autonomic nervous system balance, and potential ischemic conditions.

In practice, ECG signals are often corrupted by baseline drift, motion artifacts, and muscle noise, which leads to false peak detection and inaccurate interval measurement. As a result, technicians must manually correct annotations, spending approximately 20 minutes per ECG report. This repetitive workflow limits scalability and introduces diagnostic inconsistency. The goal of this project is to design an AI agent system that automates ECG feature extraction while preserving clinical interpretability and decision support.

---

## 2. System Architecture

The proposed system adopts an **agentic AI architecture**, where the overall ECG analysis task is decomposed into modular and cooperative agents. Each agent is responsible for a well-defined function, allowing parallel processing and clear separation of concerns.

The system architecture consists of the following agents:

1. **Ingestion Agent**  
   Loads ECG data from CSV files and performs basic validation and signal quality assessment.

2. **Pre-processing Agent**  
   Applies normalization and baseline correction to reduce noise and DC offset effects.

3. **R-Peak Detection Agent**  
   Implements the Pan-Tompkins algorithm, including filtering, differentiation, squaring, and moving-window integration, to robustly detect R-peaks.

4. **Feature Extraction Agents (Parallel)**  
   - *Time-domain Agent*: Computes BPM, SDNN, and RMSSD.  
   - *Frequency-domain Agent*: Estimates spectral features such as LF/HF ratio.  
   - *Morphological Agent*: Analyzes S-T segment deviation and amplitude features.

5. **Decision Agent**  
   Classifies physiological state (e.g., normal, fatigue, high stress) based on extracted features.

6. **Action / Reporting Agent**  
   Generates standardized textual recommendations and visualized outputs.

This modular design improves maintainability and supports both batch processing and real-time extension.

---

## 3. Implementation

The system is implemented in Python using a rule-based agent workflow. ECG data is processed at a fixed sampling rate, and R-peak detection is performed using a simplified yet robust implementation of the Pan-Tompkins algorithm.

RR intervals are computed from detected R-peaks and filtered to retain physiologically plausible values (300 ms to 2000 ms). Time-domain HRV metrics are derived directly from the filtered RR intervals. A lightweight decision logic maps BPM and RMSSD values to stress-level categories, enabling automated recommendation generation without requiring manual intervention.

The agent system is designed to execute the full pipeline in a single run, from raw ECG input to final decision output, minimizing human interaction and error.

---

## 4. Dataset Description

The evaluation dataset consists of 16 ECG/PPG recordings stored in CSV format. Each recording is approximately 5 seconds in duration with a sampling rate of 50 Hz. The dataset is used for batch analysis and system validation.

Extracted metrics include BPM, SDNN, RMSSD, LF/HF ratio, and S-T level measurements. All data is processed locally and conforms to standard time-series formatting, ensuring reproducibility and compatibility with the agent pipeline.

---

## 5. Results

A comprehensive test suite was developed to validate system functionality, including unit tests, integration tests, and end-to-end tests.

- **Total tests:** 20  
- **Passed:** 18  
- **Failed:** 2  
- **Overall pass rate:** 90%  

Average test execution time was approximately 1.3 seconds, with total test suite execution completed in 26 seconds. HRV metrics produced by the system were consistent with expected physiological ranges, and stress classification logic performed reliably for typical ECG inputs.

---

## 6. Agent-Based vs Chat-Based Comparison

To evaluate the effectiveness of the agentic approach, we compared it with a chat-based workflow using a large language model.

The agent system completed the ECG analysis task in approximately 30 seconds with a single execution command. In contrast, the chat-based approach required 30–45 minutes, involving repeated prompting, manual code execution, and error correction. The agent approach demonstrated superior consistency, reduced cognitive load, and improved reproducibility, especially for structured and repetitive biomedical data processing tasks.

---

## 7. Discussion

Two limitations were identified during testing. First, corrupted ECG files do not currently report exact row indices for invalid values, making debugging less convenient. Second, long-duration ECG recordings (>30 minutes) may cause high memory usage due to full-array processing.

Despite these limitations, the system performs reliably under standard usage conditions. The modular agent design allows future improvements such as chunk-based processing, enhanced input validation, and adaptive patient-specific parameter tuning.

---

## 8. Conclusion

This project demonstrates that an agent-based AI system can effectively automate multi-dimensional ECG feature extraction and HRV analysis. By structuring the workflow into specialized agents, the system achieves significant reductions in analysis time while maintaining clinical interpretability and reproducibility. Compared to chat-based approaches, the agentic design is better suited for complex, repeatable biomedical signal-processing tasks and provides a scalable foundation for future intelligent healthcare applications.

---

## References

1. Pan, J., & Tompkins, W. J. (1985). A real-time QRS detection algorithm. *IEEE Transactions on Biomedical Engineering*.  
2. World Health Organization. Emergency Care System Framework.  
3. Recent clinical studies on automated ECG analysis and heart rate variability evaluation.
