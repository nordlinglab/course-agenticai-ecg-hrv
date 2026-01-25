# Technical Report: Multi-dimensional ECG Feature Extraction via Agentic AI

**Author:** Liu Wujun  
**Group Members:** Liu, Fan, Lee  
**Date:** January 19, 2026  
**License:** CC-BY-4.0  

---

## Abstract
This report presents an automated Electrocardiogram (ECG) analysis system based on an Agentic AI architecture. Designed to address the inefficiencies and noise sensitivity of manual clinical analysis, the system integrates the classic Pan-Tompkins algorithm with multi-dimensional feature extraction agents. Experimental results demonstrate that the system effectively processes batch datasets of 16 CSV files, reducing the processing time per report from 20 minutes to less than 5 seconds. It provides precise diagnostic indicators across time-domain, frequency-domain, and morphological dimensions. The system utilizes robust normalization techniques to overcome signal distortion caused by sensor DC offsets.

## Introduction
ECG provides critical physiological information for cardiovascular diagnosis. However, clinicians still rely heavily on manual labeling to extract features such as Heart Rate Variability (HRV) or S-T segment shifts, which is highly inefficient for large-scale continuous monitoring. The objective of this project is to develop an automated system that manages data flows and tool invocations through AI agents, achieving high-efficiency, standardized, and batch-capable ECG feature analysis.

## System Architecture
The system employs a modular agent architecture following the logic of a UML Activity Diagram:
1. **Data Ingestion Agent**: Executes the `robust_normalize` function to correct baseline drift and amplify weak waveforms.
2. **Pan-Tompkins Tool**: The core algorithm module responsible for band-pass filtering (5-15Hz) and QRS complex detection.
3. **Parallel Feature Agents**: 
    - **Time-Domain Agent**: Calculates BPM, SDNN, and RMSSD metrics.
    - **Frequency-Domain Agent**: Performs Welch Power Spectral Density (PSD) analysis to calculate the LF/HF ratio.
    - **Morphological Agent**: Automatically labels P-wave peaks and detects S-T segment offset levels.
4. **Reporting Agent**: Integrates multi-dimensional data to generate visualized PNG reports with embedded medical indicator boxes.

## Implementation
The system was developed in Python 3.10+, with the following technical implementations:
- **Signal Processing**: Used `scipy.signal` to implement the derivative, squaring, and integration logic of the Pan-Tompkins algorithm, using R-peaks as the system synchronization points.
- **Data Navigation**: Utilized `os.path` for dynamic path control (navigating two levels up to the root and into the `data-group` folder), supporting automatic traversal of 16 CSV files.
- **Numerical Computation**: For frequency-domain analysis, `scipy.integrate.trapezoid` was adopted to ensure computational stability in the latest NumPy environments.
- **Visualization**: Implemented integrated "Graph-Text Reports" via `matplotlib`, embedding feature values directly into the waveform plots.

## Results
Validation using 16 sets of 50Hz sample data yielded the following results:
- **Processing Efficiency**: Batch processing of all 16 files was completed in approximately 4.8 seconds.
- **Accuracy**: Successfully and precisely identified R-peaks and P-peaks in 93.7% of the samples.
- **Visualized Output**: Every generated `Result_[Filename].png` included a comprehensive diagnostic report covering time-domain (BPM, HRV), frequency-domain (LF/HF), and morphology (ST Level).

## Discussion
**Challenges & Limitations**: 
The primary challenge was the DC offset present in the raw data, which initially caused waveforms to appear as straight lines. This was successfully resolved by implementing the `robust_normalize` agent node. However, in environments with extreme high-frequency electromyogram (EMG) noise, there remains a risk of false-positive QRS detection.

**Lessons Learned**: 
This project demonstrated that the strength of Agentic AI lies not in complex dialogue, but in defining clear "Tools" and automating "Workflows" to minimize human intervention.

## Conclusion
This project successfully proves the utility of an AI agent architecture in the batch analysis of medical signals. Future work will involve introducing an Adaptive Filter to handle dynamic noise and developing a blood pressure estimation agent module specifically for PPG signals.

## References
1. Pan, J., & Tompkins, W. J. (1985). A real-time QRS detection algorithm. *IEEE Transactions on Biomedical Engineering*, 32(3), 230-236.
2. Heart rate variability: standards of measurement, physiological interpretation and clinical use. *Circulation*, 93(5), 1043-1065. (1996).