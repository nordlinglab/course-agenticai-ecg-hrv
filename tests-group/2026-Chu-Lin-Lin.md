# Test Suite: Agentic ECG HRV Baseline Evaluation System

**Group:** 2026-Chu-Lin-Lin  
**Authors:** Chu YenChieh,Lin ChihYi,Lin WenHsin  
**Date:** 2026-01-20
**License:** Apache-2.0 (code), CC-BY-4.0 (documentation)

---

## Overview

This test suite validates an **agentic, rule-based ECG HRV analysis system**.  
Instead of evaluating machine learning model accuracy, the tests focus on verifying:

- Correct ECG data loading and validation
- Robust signal processing and R-peak detection
- Correct HRV feature extraction
- Proper baseline construction and rule-based evaluation
- Stable end-to-end dataset analysis behavior

The goal of the test suite is to ensure that the system behaves consistently and safely under various signal conditions and dataset configurations.

---

## Test Summary

### Overall Test Execution

-   **Total Tests Collected:** 274
-   **Tests Passed:** 274
-   **Tests Failed:** 0
-   **Warnings:** 9



*Note: Detailed numerical counts for "Total", "Passed", and "Failed" are provided for the overall execution. Per-category breakdowns are not available in this summary. The "Status" column in the original summary (if present) indicated high-level completion and success.*

Overall Status: PASS (with warnings)

---

## Usage

```bash
# Install dependencies
pip install -r requirements.txt

# Run all tests
python -m pytest tests/

# Run a specific test module
python -m pytest tests/test_orchestrator.py
```
---

## Known Issues

| Issue                        | Impact                                                  | Notes                                                                        |
| ---------------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Legacy classifier tests      | Some tests assume model training interfaces             | Classifier module is retained for extensibility but not used in this project |
| Dataset-specific assumptions | Tests may fail if dataset structure differs from config | Ensure dataset follows `person/condition/*.csv` layout                       |
| Very short ECG signals       | HRV features may be invalid                             | Expected behavior (test verifies rejection)                                  |


---

## Test Cases


#### TC-001: Load Valid ECG CSV

- Description: Verify that a valid ECG CSV file is loaded correctly

- Preconditions: CSV file exists with numeric ECG column

- Input: Sample ECG CSV (≥ 30 seconds)

- Expected Output: ECG signal array loaded successfully

- Actual Output: Signal loaded without errors

- Status: PASS

#### TC-002: Handle Missing ECG File

- Description: Verify graceful handling of missing files

- Preconditions: None

- Input: Non-existent CSV file path

- Expected Output: FileNotFoundError with descriptive message

- Actual Output: Correct exception raised

- Status: PASS

#### TC-003: Validate ECG Signal Quality

- Description: Detect flat, NaN, or invalid ECG signals

- Preconditions: Malformed ECG input

- Input: Constant or NaN-valued signal

- Expected Output: Validation failure

- Actual Output: Validation failure detected

- Status: PASS

### Integration Tests
#### TC-010: Baseline Construction per Subject and Condition

- Description: Verify personalized baseline construction

- Preconditions: Multiple ECG files per person/state

- Input: Dataset with Rest and Active conditions

- Expected Output: Baseline statistics generated per person/state

- Actual Output: Baselines stored in baselines.json

- Status: PASS

#### TC-011: Window-Based Evaluation Logic

- Description: Verify pass/fail decision for ECG windows

- Preconditions: Valid RR intervals

- Input: Synthetic HRV feature values

- Expected Output: Correct pass/fail decision

- Actual Output: Decision matches expected rule

- Status: PASS

### End-to-End Tests
#### TC-020: Full Dataset Analysis Execution

- Description: Verify complete dataset analysis workflow

- Preconditions: Dataset directory and config.yaml available

- Input: Real ECG dataset (CSV)

- Expected Output:

    - baselines.json

    - pass_rates.csv

    - per-file evaluation outputs

- Actual Output: All outputs generated successfully

- Status: PASS
---
## Test Results Analysis
### Result Summary

- Core functionality tests passed successfully
- No critical failures affecting baseline evaluation logic

### Warnings Analysis

Several warnings were observed during test execution:

-   **`DeprecationWarning: datetime.datetime.utcfromtimestamp()`**: This is a deprecation warning from the Python standard library `dateutil` module. It does not impact the system's functionality but indicates that the usage of `utcfromtimestamp()` will be removed in future Python versions.
-   **`FutureWarning: Class PassiveAggressiveClassifier is deprecated`**: This warning confirms the "Legacy classifier tests" known issue. While the classifier tests passed, `PassiveAggressiveClassifier` is deprecated in `scikit-learn`. The recommendation is to use `SGDClassifier` instead. This does not impact the current rule-based system, as classifier training is outside the project's scope, but highlights a need for future refactoring if ML models are integrated.
-   **`RuntimeWarning: invalid value encountered in reduce`**: These warnings occurred during `TestValidateEcgData::test_validate_data_with_inf`. This is expected behavior as the test is specifically designed to handle and validate malformed input data containing `inf` values.
-   **`UserWarning: loadtxt: input contained no data`**: This warning originated from `TestECGLoader::test_load_empty_file`. This is also expected, as the test aims to verify the loader's behavior when encountering an empty file.

### Performance Metrics

| Metric                 | Value                                               |
| ---------------------- | --------------------------------------------------- |
| Average unit test time | < 1 second                                          |
| Total test suite time  | ~20 seconds                                         |
| Code coverage          | Focused on agent orchestration and evaluation logic |

---

### Conclusion

The test suite confirms that the system reliably performs rule-based, agentic ECG evaluation across multiple subjects and conditions.
Within the defined operational boundaries, the system can be used safely for dataset-level physiological assessment without requiring model training.

---

*Report generated on 2026-01-20*

