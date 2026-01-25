# Data: Multi-dimensional ECG Batch Analysis code integration

**Group:** 2026-Fan-Lee-Liu
**Authors:** Lee Polin, Student; Liu, Wujun; Fan, Chenyu
**License:** CC-BY-4.0

## Dataset Overview

### Source
[cite_start]The data utilized in this project consists of 16 ECG/PPG recordings collected for validating the Agentic AI analysis system. All datasets are stored in `.\data-group\2026-Fan-Lee-Liu\raw\` for batch processing.

### Statistics
| Property | Value |
|----------|-------|
| Total Subjects | [cite_start]16 files (Batch processed)  |
| Sampling Rate | [cite_start]50 Hz [cite: 15] |
| Data Format | [cite_start]CSV (Time-series)  |
| Total Duration | [cite_start]~5 seconds per recording [cite: 32] |
| Metrics Extracted | [cite_start]BPM, SDNN, RMSSD, LF/HF Ratio, ST-Level [cite: 10, 137] |

### Format
The raw data files are structured as tabular CSV files with the following characteristics:
- **Encoding:** UTF-8
- **Structure:** Single or multi-channel time-series data representing normalized electrical potential and optical signals.

## System Architecture & Workflow

[cite_start]The analysis is conducted using an Agentic AI workflow as illustrated in the system design[cite: 30, 31]:
1. [cite_start]**Pre-processing Agent**: Applies `robust_normalize` to correct DC offsets and baseline drift[cite: 17, 34, 133].
2. [cite_start]**Core Engine**: Implements the Pan-Tompkins Algorithm for robust R-peak detection[cite: 6, 19, 30, 134].
3. [cite_start]**Parallel Feature Agents**: Simultaneously extracts time-domain, frequency-domain, and morphological metrics[cite: 7, 134].
4. [cite_start]**Automated Reporting**: Generates visualized reports in `.png` format.


## Usage Instructions

### Automated Batch Analysis
The project code located at `.\project-code-group\2026-Fan-Lee-Liu\2026-Fan-Lee-Liu.py` is designed to automatically traverse and process all data files in the target directory.

**Execution Command:**
```bash
# Navigate to the code directory
cd .\project-code-group\2026-Fan-Lee-Liu\

# Execute the batch analysis
python 2026-Fan-Liu.py