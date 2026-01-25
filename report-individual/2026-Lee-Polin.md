\# Technical Report: Multi-dimensional ECG Feature Extraction via Agentic AI



\*\*Author:\*\* 2026-Lee-Polin

\*\*Group Members:\*\* Fan Chengyu, Lee Polin, Liu Wujun

\*\*License:\*\* CC-BY-4.0



\## Abstract



This report presents a batch-processing agent system for electrocardiogram (ECG) and photoplethysmogram (PPG) analysis, designed to extract heart rate variability (HRV) and cardiac-related physiological features. The system automatically processes multiple CSV files, performs signal normalization, Pan–Tompkins-based R-peak detection, and extracts both time-domain and frequency-domain HRV metrics, including BPM, SDNN, RMSSD, and LF/HF ratio. Additional morphological features such as P-wave candidates and ST-segment level are also estimated. The results are visualized and saved automatically for each input file. This system demonstrates how a rule-based, interpretable agent pipeline can integrate signal processing, feature extraction, and automated reporting in a scalable batch analysis framework.



\## 1. Introduction



ECG and PPG signals are widely used for assessing cardiovascular function and autonomic nervous system activity. HRV metrics derived from ECG provide important indicators of physiological stress, fatigue, and cardiac health. In practical scenarios, physiological data are often collected across multiple sessions or subjects, requiring automated batch analysis rather than single-file processing.



The goal of this project is to develop an agent-based analysis system that can:



1\. Automatically process multiple ECG/PPG files

2\. Perform robust signal preprocessing

3\. Extract time-domain and frequency-domain HRV features

4\. Identify basic cardiac morphological indicators

5\. Generate visual and numerical summaries for each recording



The emphasis of this system is robustness, interpretability, and scalability rather than complex machine learning models.



\## 2. System Architecture



The system follows a batch-oriented agent pipeline architecture. A single Python script coordinates data loading, signal processing, feature extraction, and visualization for all files within a specified directory. Rather than interactive orchestration or model-based decision making, the architecture prioritizes reproducibility and deterministic execution for large collections of physiological recordings.



\### 2.1 Overall Pipeline



1\. Dynamic path resolution and batch file discovery

2\. Signal normalization and bandpass filtering

3\. R-peak detection using Pan–Tompkins logic

4\. HRV feature extraction (time and frequency domains)

5\. Morphological feature estimation (P-wave, ST level)

6\. Automated visualization and result export



\### 2.2 Component Descriptions



Table 1 summarizes the main functional components of the proposed system and their corresponding roles within the batch analysis pipeline.



| Component | Type | Description |

|---------|------|-------------|

| Path Manager | Tool | Dynamically resolves project paths and locates CSV files |

| ECG/PPG Loader | Tool | Reads multi-channel CSV data and selects ECG/PPG signals |

| Signal Preprocessor | Tool | Applies detrending, normalization, and bandpass filtering |

| R-Peak Detector | Tool | Detects R-peaks using Pan–Tompkins-inspired processing |

| HRV Extractor | Tool | Computes BPM, SDNN, RMSSD, and LF/HF ratio |

| Morphology Analyzer | Tool | Estimates P-wave candidates and ST-segment level |

| Visualization Agent | Agent | Generates plots and saves result images automatically |



\## 3. Implementation



The following sections describe the technical implementation of the proposed system, with emphasis on how each processing stage corresponds to concrete algorithmic operations in the batch execution script.



\### 3.1 Batch Processing and File Management



The system automatically discovers all CSV files within a predefined data directory using dynamic path resolution. This design allows the analysis script to be executed from different directory locations without manual path modification. Each file is processed independently within an iterative loop, ensuring that failures in individual recordings do not interrupt the overall batch analysis.



\### 3.2 Signal Preprocessing



Raw ECG and PPG signals are first detrended and normalized using a robust normalization strategy based on mean removal and variance scaling. This step mitigates inter-file amplitude variability and sensor-specific DC offsets, which were observed to cause waveform saturation or near-flat signals during preliminary testing. After normalization, ECG signals are passed through a 5–15 Hz bandpass filter to enhance QRS complexes and suppress baseline wander and high-frequency noise prior to peak detection.



\### 3.3 R-Peak Detection



R-peaks are detected using a simplified Pan–Tompkins-inspired pipeline consisting of signal differentiation, squaring, and moving-window integration. Peak candidates are identified using amplitude and refractory constraints to prevent physiologically implausible detections. Files with insufficient detected R-peaks are excluded from subsequent feature extraction to avoid unstable HRV calculations.



\### 3.4 HRV Feature Extraction



RR intervals are computed from detected R-peaks and converted to milliseconds. Time-domain HRV metrics, including BPM, SDNN, and RMSSD, are calculated directly from these intervals. For frequency-domain analysis, Welch’s method is applied to the RR interval series to estimate power spectral density. LF and HF band powers are integrated using numerical trapezoidal integration, and the LF/HF ratio is derived as an indicator of autonomic balance.



\### 3.5 Morphological Feature Estimation



In addition to HRV metrics, the system performs basic ECG morphological estimation. P-wave candidate locations are identified using a fixed pre-R search window, where the maximum signal amplitude within the window is selected as a heuristic P-wave estimate. ST-segment level is approximated by sampling the ECG signal at a fixed temporal offset following each R-peak and averaging across beats. These morphological features are included to provide complementary structural information beyond interval-based HRV analysis.



\### 3.6 Visualization and Output



For each processed file, the system generates annotated ECG plots displaying detected R-peaks and estimated P-wave candidates, along with corresponding PPG signal plots for reference. A summary text box containing key numerical metrics is embedded directly within the ECG visualization. All output figures are automatically saved using the source filename, ensuring traceability between raw data and generated results.



\## 4. Results



The system successfully processes multiple ECG/PPG recordings in a fully automated manner. For each file, the output includes numerical HRV metrics, estimated ST-segment level, annotated ECG and PPG visualizations, and saved result images for offline review. The batch-oriented design enables efficient analysis of heterogeneous physiological datasets without manual file handling or interactive intervention.



\## 5. Discussion



\### 5.1 Strengths



\- Fully automated batch processing with deterministic execution

\- Robust normalization addressing inter-file amplitude variability

\- Integration of HRV metrics with basic ECG morphological estimation

\- Clear and interpretable rule-based design aligned with signal processing principles



\### 5.2 Limitations



\- Fixed temporal windows and thresholds may not generalize across populations

\- P-wave detection relies on heuristic rules and is not clinically validated

\- No subject-specific baseline adaptation or temporal modeling

\- Offline analysis only, without real-time streaming support



\### 5.3 Lessons Learned



This project highlights the importance of explicitly aligning system architecture descriptions with actual implementation logic. Even without machine learning models, carefully structured signal processing pipelines can deliver scalable and interpretable physiological analysis when batch robustness and reproducibility are prioritized.



\## 6. Conclusion



This project demonstrates a batch-oriented ECG/PPG analysis agent system capable of extracting HRV and cardiac-related features from multiple recordings automatically. By combining robust preprocessing, interval-based HRV computation, heuristic morphological estimation, and automated visualization, the system provides a transparent and scalable framework for physiological data analysis. Future work may incorporate adaptive thresholds, subject-specific baselines, and real-time processing capabilities.



\## 7. References



Pan, J., \& Tompkins, W. J. (1985). A real-time QRS detection algorithm. IEEE Transactions on Biomedical Engineering, 32(3), 230–236.



Task Force of the European Society of Cardiology and the North American Society of Pacing and Electrophysiology. (1996). Heart rate variability: standards of measurement, physiological interpretation and clinical use. Circulation, 93(5), 1043–1065.

