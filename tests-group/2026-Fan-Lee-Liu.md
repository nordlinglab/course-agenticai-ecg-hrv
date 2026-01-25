# Test Suite: HRV Analysis Agent

**Group:** 2026-Fan-Lee-Liu  
**Authors:** Fan Cheng-Yu, Lee Po-Lin, Liu Wu-Jun  
**License:** Apache-2.0 (code), CC-BY-4.0 (documentation)

---

## Overview

This test suite validates the functionality and reliability of the HRV Analysis Agent.
The system processes ECG signals, extracts heart rate variability (HRV) features,
and generates stress-level assessments and corresponding recommendations.

Tests focus on:
- ECG data loading and validation
- Signal processing and R-peak detection
- RR interval and HRV feature computation
- Agent decision logic
- End-to-end execution from raw data to recommendation

---

## Test Summary

| Category | Total | Passed | Failed |
|----------|-------|--------|--------|
| Unit Tests | 12 | 11 | 1 |
| Integration Tests | 5 | 5 | 0 |
| End-to-End Tests | 3 | 2 | 1 |
| **Total** | **20** | **18** | **2** |

**Pass Rate:** 90%

---

## Usage

```bash
pip install -r requirements.txt
python -m pytest tests/
python -m pytest tests/test_signal_processing.py
```
---

## Known Issues

1. Corrupted ECG CSV files do not report the exact row or timestamp of invalid data.
2. Long-duration ECG recordings (>30 minutes) may lead to high memory usage or processing timeouts.

---

## Test Cases

### Unit Tests: ECG Data Loader

TC-001: Load Valid ECG CSV File
- Description: Verify that a valid ECG CSV file can be loaded correctly
- Preconditions: CSV file exists in data-group/2026-Fan-Lee-Liu/
- Input: 300_bike_level1_20260113_211013_extended_poll.bin_align.csv
- Expected Output: ECG signal loaded as numeric array with correct length
- Actual Output: ECG signal loaded successfully and length printed
- Status: PASS

TC-002: Handle Missing ECG CSV File
- Description: Verify system behavior when ECG CSV file is missing
- Preconditions: None
- Input: missing_ecg.csv
- Expected Output: FileNotFoundError raised with descriptive message
- Actual Output: FileNotFoundError raised
- Status: PASS

TC-003: Handle Corrupted ECG CSV File
- Description: Verify handling of ECG CSV file containing non-numeric values
- Preconditions: CSV file contains non-numeric ECG values in column 3
- Input: corrupted_ecg.csv
- Expected Output: ValueError during numeric processing
- Actual Output: ValueError raised without row index information
- Status: FAIL
- Notes: Error message does not indicate exact corrupted row

---

### Unit Tests: R-Peak Detection and RR Interval Processing

TC-004: R-Peak Detection Using Squared Signal
- Description: Verify R-peak detection using squared ECG signal and find_peaks
- Preconditions: Valid ECG signal loaded
- Input: ECG signal array (fs = 300 Hz)
- Expected Output: Reasonable number of detected R-peaks
- Actual Output: 4992 R-peaks detected
- Status: PASS

TC-005: RR Interval Computation and Filtering
- Description: Verify RR interval computation and physiological range filtering
- Preconditions: R-peaks detected successfully
- Input: R-peak index array
- Expected Output: RR intervals within 300 ms to 2000 ms
- Actual Output: 1848 valid RR intervals retained
- Status: PASS

---

### Integration Tests

TC-010: Time-Domain HRV Feature Computation
- Description: Verify computation of time-domain HRV metrics from RR intervals
- Preconditions: Valid RR interval sequence available
- Input: RR intervals in milliseconds
- Expected Output: BPM, SDNN, and RMSSD values computed
- Actual Output: BPM 110.45, SDNN 138.90 ms, RMSSD 168.99 ms
- Status: PASS

TC-011: Agent Decision Logic
- Description: Verify stress state classification based on BPM and RMSSD
- Preconditions: HRV metrics computed
- Input: BPM 110.45, RMSSD 168.99
- Expected Output: Classified as high_stress
- Actual Output: Detected state high_stress
- Status: PASS

TC-012: Agent Action Recommendation
- Description: Verify recommendation generation based on detected stress state
- Preconditions: Stress state determined
- Input: high_stress
- Expected Output: Recommendation advising rest and avoiding caffeine
- Actual Output: Recommendation generated correctly
- Status: PASS

---

### End-to-End Tests

TC-018: Full HRV Analysis Pipeline Execution
- Description: Verify complete pipeline from ECG CSV input to final recommendation
- Preconditions: Valid ECG CSV file and functional agent logic
- Input: 300_bike_level1_20260113_211013_extended_poll.bin_align.csv
- Expected Output: HRV metrics computed and recommendation generated
- Actual Output: HRV results printed and recommendation displayed
- Status: PASS

TC-019: Large ECG CSV File Processing
- Description: Verify system behavior with long-duration ECG recordings
- Preconditions: Large ECG CSV file available
- Input: ECG CSV file (>30 minutes, fs = 300 Hz)
- Expected Output: Analysis completes within reasonable time
- Actual Output: Timeout or high memory usage observed
- Status: FAIL
- Notes: Optimization required for long-duration ECG processing

---

## Test Results Analysis
### Result Summary
Overall pass rate: 90% (18 / 20 tests)

Most test cases passed successfully, indicating that the HRV Analysis Agent
functions correctly for typical ECG inputs and produces reasonable HRV metrics and agent recommendations.

---

### Failed Tests Analysis

TC-003: Handle Corrupted ECG CSV File
- Root Cause: Numeric validation is performed after loading data without tracking row indices of invalid values.
- Impact: Low. Corrupted files are rejected, but debugging is inconvenient.
- Recommendation: Add explicit numeric validation and report row index or timestamp.

TC-019: Large ECG CSV File Processing
- Root Cause: Entire ECG signal is processed as a single array, causing
high memory usage for long recordings.
- Impact: Medium. Limits scalability on resource-constrained machines.
- Recommendation: Implement chunk-based or windowed ECG processing.

---

## Performance Metrics

| Metric | Value |
|--------|-------|
| Average test execution time | 1.3 seconds |
| Total test suite execution time | 26 seconds |
| Code coverage | 78% |

---

## Conclusion

The HRV Analysis Agent passes all critical tests related to ECG data loading, R-peak detection, RR interval processing, HRV feature extraction, and agent-based stress assessment. Identified failures are limited to edge cases involving corrupted input data and unusually long ECG recordings. These limitations do not affect standard usage scenarios and can be addressed through future improvements in input validation and performance optimization.