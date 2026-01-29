# Data: HRV Analysis Dataset for Agentic AI

**Group Folder:** `2026-Khan-Liu-Peng`  
**Course:** Agentic AI, NCKU  
**License:** CC-BY-4.0  

---

## 1. Source

This dataset is used for training, testing, and demonstrating an AI agent system for Heart Rate Variability (HRV) analysis in smart healthcare scenarios.

The submission integrates **multiple public datasets** to improve robustness and generalizability of the agent workflow.

### 1.1 Primary Data Source — SWELL-KW

**Dataset:** Koldijk, S., et al. (2014). *The SWELL Knowledge Work Dataset for Stress and User Modeling Research*

**Description:** ECG and contextual data collected during knowledge work tasks under different stress conditions.

**URL:** <http://cs.ru.nl/~skoldijk/SWELL-KW/Dataset.html>

**License:** Creative Commons Attribution 4.0 International (CC-BY-4.0)

### 1.2 Secondary Data Source — WESAD

**Dataset:** Schmidt, P., et al. (2018). *WESAD: A Multimodal Dataset for Wearable Stress and Affect Detection*

**Description:** Multimodal physiological dataset including ECG, EDA, respiration, and temperature, collected using wearable sensors under controlled stress conditions.

**Repository (UCI ML Repository):** <https://archive.ics.uci.edu/ml/datasets/WESAD>

**Original Publication:** Schmidt, P. et al., “Introducing WESAD, a Multimodal Dataset for Wearable Stress and Affect Detection,” *ICMI 2018*.

**License:** Creative Commons Attribution 4.0 International (CC-BY-4.0)

---

## 2. Data Description

This submission contains **processed HRV features** derived from ECG signals originating from the SWELL-KW and WESAD datasets.

> Raw physiological signals are **not redistributed**.  
> Only anonymized, derived features are included.

### Folder Structure

```text
2026-Khan-Liu-Peng/
├── README.md
├── raw/                # (optional) raw data pointers or synthetic examples
│   └── *.txt
├── processed/
│   └── *.csv
└── metadata.json       # optional
```

### File Overview

| File | Description | Format |
| :--- | :--- | :--- |
| `processed/hrv_features.csv` | Extracted HRV features | CSV (UTF-8) |
| `processed/labels.csv` | Stress condition labels | CSV (UTF-8) |
| `metadata.json` | Dataset metadata (optional) | JSON |

### 2.1 `hrv_features.csv`

| Column | Type | Description |
| :--- | :--- | :--- |
| `dataset` | string | Source dataset (`SWELL`, `WESAD`) |
| `subject_id` | string | Anonymized subject ID |
| `window_id` | int | Sliding window index |
| `sdnn` | float | Standard deviation of NN intervals (ms) |
| `rmssd` | float | Root mean square of successive differences (ms) |
| `pnn50` | float | Percentage of NN intervals > 50 ms |
| `lf_power` | float | Low-frequency power (ms²) |
| `hf_power` | float | High-frequency power (ms²) |
| `lf_hf_ratio` | float | LF/HF ratio |

### 2.2 `labels.csv`

| Column | Type | Description |
| :--- | :--- | :--- |
| `dataset` | string | Source dataset (`SWELL`, `WESAD`) |
| `subject_id` | string | Anonymized subject identifier |
| `window_id` | int | Window index |
| `condition` | string | Experimental condition |
| `stress_label` | int | Binary stress label (0 = neutral, 1 = stressed) |

---

## 3. Preprocessing

The following preprocessing pipeline was applied consistently across datasets:

1. ECG band-pass filtering (0.5–40 Hz)
2. R-peak detection using the Pan–Tompkins algorithm
3. RR interval computation
4. HRV feature extraction using 3-minute windows with 50% overlap
5. Removal of outlier windows (RR < 300 ms or RR > 2000 ms)
6. Dataset harmonization (feature units and naming aligned)

This standardized pipeline enables **cross-dataset agent evaluation**.

---

## 4. Usage

### Example (Python)

```python
import pandas as pd

features = pd.read_csv("processed/hrv_features.csv")
labels = pd.read_csv("processed/labels.csv")

data = features.merge(
    labels,
    on=["dataset", "subject_id", "window_id"]
)

# Example: dataset-aware split
train_data = data[data["dataset"] == "SWELL"]
test_data  = data[data["dataset"] == "WESAD"]
```

Typical use cases:

* HRV-based stress detection
* Cross-dataset generalization testing
* Agentic AI pipelines (sense → analyze → evaluate → adapt)

---

## 5. Privacy Statement

**CRITICAL COMPLIANCE CONFIRMATION**

* No personally identifiable information (PII) is included
* All subject identifiers are anonymized
* No raw physiological signals are redistributed
* All original datasets were collected with informed consent and IRB approval

This submission fully complies with course data privacy requirements.

---

## 6. Dataset Statistics (Approx.)

| Metric | SWELL-KW | WESAD |
| :--- | :--- | :--- |
| Subjects | 25 | 15 |
| Conditions | 3 | 3 |
| HRV Features | 6 | 6 |
| Window Length | 3 min | 3 min |

---

## 7. License

This dataset is distributed under:  
**Creative Commons Attribution 4.0 International (CC-BY-4.0)** Attribution is required when using or redistributing this data.

---

## 8. Authors

* Khan, S.
* Liu, A.
* Peng, T.

---

## 9. Notes for Instructors

This data submission supports evaluation of **Agentic AI workflows** by enabling:

* Multi-source data reasoning
* Robustness testing
* Comparison between Chat-based and Agent-based AI systems