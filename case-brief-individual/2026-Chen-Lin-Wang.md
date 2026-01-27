# Case Brief: Automated Workplace Stress Monitoring Using an HRV-based Stress Classifier using ECG Input Data

**Authors:** Chen Wei, Lin MeiLing, Wang XiaoMing

**License:** CC-BY-4.0

---

## Problem Statement

Occupational stress is a pervasive issue affecting employee health, productivity, and organizational costs. Traditional stress assessment relies on self-reported questionnaires (e.g., PSS, DASS-21), which are subjective, retrospective, and cannot provide real-time monitoring. This creates a critical gap: by the time chronic stress is identified, employees may already be experiencing burnout, cardiovascular complications, or mental health deterioration.

Heart Rate Variability (HRV) derived from electrocardiogram (ECG) signals provides an objective, physiological measure of autonomic nervous system activity and stress states. However, HRV analysis requires specialized signal processing knowledge, making it inaccessible to occupational health practitioners who lack biomedical engineering expertise. An AI-assisted system could bridge this gap by automating the complex analysis pipeline while providing interpretable results.

---

## Context

### Industry Landscape

- **Cost**: Globally, 12 billion working days are lost annually to depression and anxiety, costing US$ 1 trillion in lost productivity (WHO 2024). In the US alone, workplace stress costs employers $300 billion annually (The American Institute of Stress 2024)
- **Prevalence**: 77% of US workers report work-related stress (APA 2023)
- **Healthcare burden**: In the US stressed employees have 50% higher healthcare costs (NIOSH 1999)

### Current Solutions and Limitations

| Solution | Limitation |
|----------|------------|
| Self-report questionnaires | Subjective, recall bias, not real-time |
| Wearable fitness trackers | Consumer-grade accuracy, limited HRV metrics |
| Clinical HRV software | Requires expertise, expensive licenses, no AI interpretation |
| Manual ECG analysis | Time-consuming (10-30 min per recording), requires specialist |

### Stakeholders

1. **Occupational health practitioners** - Need accessible stress assessment tools
2. **Employees** - Deserve objective health monitoring without invasive procedures
3. **Employers/HR** - Require scalable solutions for workforce wellness programs
4. **Researchers** - Need reproducible, standardized HRV analysis pipelines to measure stress

---

## Analysis

### Root Causes

1. **Technical barrier**: HRV analysis requires understanding of signal processing (bandpass filtering, R-peak detection), time-domain metrics (SDNN, RMSSD), frequency-domain analysis (LF/HF ratio), and non-linear dynamics (sample entropy)—knowledge typically held only by biomedical engineers.

2. **Interpretation gap**: Even when HRV features are extracted, translating numerical values into actionable stress assessments requires clinical expertise and reference to normative data.

3. **Pipeline complexity**: A complete analysis involves multiple sequential steps (loading → filtering → peak detection → feature extraction → classification → interpretation), each with configurable parameters that affect downstream results.

4. **Classifier selection uncertainty**: With multiple classification algorithms available (ensemble methods, linear models, SVMs, neural networks), practitioners lack guidance on which approach suits their data characteristics.

5. **Device ecosystem fragmentation and privacy concerns**: Consumer wearable devices capable of ECG/HRV collection exhibit substantial variability in data privacy practices. A systematic analysis of 17 wearable manufacturers found that 76% posed high risk for transparency reporting, 65% lacked vulnerability disclosure programs, and 59% had inadequate breach notification procedures (Doherty et al. 2025). In workplace contexts, the U.S. Equal Employment Opportunity Commission (EEOC 2024) has flagged that biometric wearables collecting heart rate and physiological data may constitute "medical examinations" under the Americans with Disabilities Act, creating legal compliance risks for employers. ECG data is particularly sensitive as it can reveal cardiac conditions beyond stress states, raising concerns about potential health discrimination. This fragmented regulatory landscape—where HIPAA applies in clinical settings but state laws vary for consumer ECG devices—creates uncertainty about data ownership, consent requirements, and liability when deploying ECG-based stress monitoring in occupational health programs.

### Constraints

- **Regulatory**: Cannot replace clinical diagnosis; must augment human decision-making
- **Privacy**: ECG data is sensitive health information requiring secure handling (HIPAA/GDPR compliance)
- **Technical**: Minimum 60-180 seconds of clean ECG recording required for reliable frequency-domain HRV
- **Deployment**: Must work with varying ECG equipment (different sampling rates: 100-1000 Hz)

### Requirements

| Requirement | Specification |
|-------------|---------------|
| Input flexibility | Support multiple ECG formats (WESAD pickle, raw text, common clinical formats) |
| Processing transparency | Explainable pipeline with intermediate results visible |
| Classification accuracy | ≥85% accuracy for binary stress/baseline classification |
| Interpretability | Plain-language explanations of HRV metrics and stress predictions |
| Extensibility | Support for multiple classifiers with data-driven selection |

---

## Proposed Approach

### Chat-Based Solution

A practitioner could use a conversational AI (e.g., ChatGPT) by:

1. **Copy-pasting** extracted HRV features into the chat with a standardized prompt template
2. **Asking** for interpretation: "Given SDNN=45ms, RMSSD=28ms, LF/HF=2.3, what is the likely stress state?"
3. **Iterating** on follow-up questions about specific metrics or clinical implications

**Limitations**: Requires manual feature extraction first; no direct ECG processing; results not reproducible; no PDF reports for documentation.

### Agentic AI Solution

An AI agent system using Claude as an orchestrator with specialized tools:

```
┌─────────────────────────────────────────────────────────────┐
│                    USER REQUEST                              │
│         "Analyze this ECG file for stress"                  │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 CLAUDE ORCHESTRATOR                          │
│  • Understands task and selects appropriate tools           │
│  • Dynamically chooses classifier based on data size        │
│  • Interprets results with clinical context                 │
│  • Generates documented PDF reports                         │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────┐
│  load_   │ process_ │ extract_ │ recommend│ classify_│report│
│  ecg     │ signal   │ features │ _clf     │ stress   │      │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────┘
```

**Agent capabilities:**
- **Autonomous pipeline execution**: Loads raw ECG, applies bandpass filtering (0.5-40 Hz), detects R-peaks, extracts 20 HRV features
- **Intelligent classifier selection**: Recommends optimal classifier from 20 options based on dataset size and priority (accuracy vs. speed)
- **Adaptive windowing**: Handles both short (<180s) and long recordings with sliding window aggregation
- **Explainable outputs**: Generates PDF reports with feature visualizations and plain-language interpretation

---

## Expected Outcomes

| Metric | Target | Rationale |
|--------|--------|-----------|
| Classification accuracy | ≥92% (achieved: 92.66%) | Exceeds WESAD paper baseline (85.44%) |
| Analysis time | <30 seconds per recording | Enables batch processing |
| User expertise required | Minimal (upload file, receive report) | Democratizes HRV analysis |
| Report completeness | All 20 HRV features + interpretation | Supports clinical documentation |

**Success indicators:**
- Occupational health practitioners can independently assess stress without biomedical training
- Reproducible results across different ECG equipment and formats
- Audit trail through generated PDF reports for longitudinal tracking

---

## References

1. Schmidt P, Reiss A, Duerichen R, Marberger C, Van Laerhoven K (2018). Introducing WESAD, a Multimodal Dataset for Wearable Stress and Affect Detection. *ICMI '18: Proceedings of the 20th ACM International Conference on Multimodal interaction*. DOI: 10.1145/3242969.3242985

2. Task Force of the European Society of Cardiology and the North American Society of Pacing and Electrophysiology (1996). Heart rate variability: Standards of measurement, physiological interpretation and clinical use. *Circulation*, 93(5), 1043-1065. PMID: 8598068

3. Shaffer F, Ginsberg JP (2017). An Overview of Heart Rate Variability Metrics and Norms. *Frontiers in Public Health*. 5:258. DOI: 10.3389/fpubh.2017.00258

4. American Psychological Association (APA) (2023). 2023 Work in America Survey: Workplaces as engines of psychological health and well-being. URL: https://www.apa.org/pubs/reports/work-in-america/2023-workplace-health-well-being (Accessed 2026-01-23)

5. World Health Organization (WHO) (2024). Mental health at work (Fact sheet). URL: https://www.who.int/news-room/fact-sheets/detail/mental-health-at-work (Accessed 2026-01-23)

6. The American Institute of Stress (2024). 80% Of Employees Report ‘Productivity Anxiety’ And Lower Well-Being In New Study. URL: https://www.stress.org/news/80-of-employees-report-productivity-anxiety-and-lower-well-being-in-new-study/ (Accessed 2026-01-23)

7. National Institute for Occupational Safety and Health (NIOSH) (1999). Stress At Work Booklet. Publication No. 99-101. URL: https://www.cdc.gov/niosh/docs/99-101/default.html (Accessed 2026-01-23)

8. Doherty C, Baldwin M, Lambe R, Altini M, Caulfield B (2025). Privacy in consumer wearable technologies: a living systematic analysis of data policies across leading manufacturers. *NPJ Digital Medicine*. DOI: 10.1038/s41746-025-01757-1

9. U.S. Equal Employment Opportunity Commission (EEOC) (2024). Wearables in the Workplace: The Use of Wearables and Other Monitoring Technology Under Federal Employment Discrimination Laws (Fact Sheet). URL: https://www.eeoc.gov/laws/guidance/wearables-workplace-use-wearables-and-other-monitoring-technology-under-federal (Accessed 2026-01-23)

10. U.S. Government Accountability Office (GAO) (2024). Science & Tech Spotlight: Wearable Technologies in the Workplace. GAO-24-107303. URL: https://www.gao.gov/products/gao-24-107303 (Accessed 2026-01-23)
