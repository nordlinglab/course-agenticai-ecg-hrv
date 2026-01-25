# Reflection: Agent vs Chat-Based HRV Analysis

**Group:** 2026-Chu-Lin-Lin
**Authors:** Chu YenChieh,Lin ChihYi,Lin WenHsin
**License:** CC-BY-4.0

## Tools

Custom Python-based AI agent system vs. Gemini

## Task Description

In this project, we analyzed multi-subject ECG recordings under different physiological conditions (Rest and Active) to evaluate heart rate variability (HRV).
The goal was to design an agentic, baseline-driven analysis pipeline that can automatically process datasets, validate signal quality.

## Agent Approach

Our agentic system performs the following steps:

- Automatically loads ECG CSV files based on dataset configuration

- Applies standardized preprocessing and R-peak detection

- Extracts RR intervals and HRV features

- Constructs personalized physiological baselines per subject and condition

- Evaluates each ECG segment against its baseline using rule-based validation

- Produces structured outputs, including baselines, pass rates, and visualizations

Once the pipeline is configured, the entire dataset can be analyzed fully automatically, without manual intervention for each file.

## Chat Approach

Using Gemini:
1. Manually providing individual-specific information, such as sampling rate and expected heart rate range

2. Uploading ECG signal segments through the chat interface

3. Receiving HRV analysis code snippets or interpretation suggestions

4. Re-entering individual context when the model loses track across interactions

5. Manually verifying whether the analysis results are physiologically reasonable

6. Repeating the same process for each ECG segment and each individual


Total time: ~60 minutes with multiple iterations.

## Performance Comparison

| Metric                      | Custom Python-based Agent Pipeline                       | Chat-based Workflow                      |
| --------------------------- | -------------------------------------------------------- | ---------------------------------------- |
| Time to complete (16 files) | ~1–3 minutes + visualization time *(depends on machine)* | ~60 minutes *(multi-step, iterative)* |
| Manual steps required       | 4 commands                                               | 10–20+ interactions                      |
| Errors encountered          | Low *(pipeline-integrated checks)*                       | Medium *(code copy/run/debug cycles)*    |
| Output consistency          | High *(config-driven)*                                   | Medium *(prompt-driven)*                 |


## Analysis

The performance difference mainly comes from:

1.**Workflow orchestration:**
The agentic pipeline coordinates multiple analysis stages automatically, whereas manual workflows require explicit execution of each step.

2.**State awareness:**
Personalized baselines allow the system to evaluate ECG segments in context, instead of relying on fixed thresholds.

3.**Built-in validation:**
The agent rejects physiologically implausible segments, reducing the risk of interpreting corrupted signals as valid data.

4.**Separation of concerns:**
Data processing, evaluation, and visualization are clearly separated, improving maintainability and clarity.

## Lessons Learned

- Agentic systems are especially effective for multi-step, repetitive analysis pipelines

- Rule-based personalization can significantly reduce activity-related bias without model training

- Standardized preprocessing is critical for reliable HRV extraction

- While initial pipeline design requires more effort, the benefit increases as dataset size grows



