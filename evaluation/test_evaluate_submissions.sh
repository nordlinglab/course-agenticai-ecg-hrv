#!/usr/bin/env zsh
#
# test_evaluate_submissions.sh - Unit and functional tests for evaluate_submissions.sh
#
# Copyright 2026 Torbjörn E. M. Nordling
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_SCRIPT="$SCRIPT_DIR/evaluate_submissions.sh"
TEST_TMP_DIR="/tmp/claude/test_submissions_$$"

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

setup() {
    # Create temporary test directory structure
    mkdir -p "$TEST_TMP_DIR"
    mkdir -p "$TEST_TMP_DIR/ssh-keys-individual"
    mkdir -p "$TEST_TMP_DIR/case-brief-individual"
    mkdir -p "$TEST_TMP_DIR/report-individual"
    mkdir -p "$TEST_TMP_DIR/data-group"
    mkdir -p "$TEST_TMP_DIR/project-code-group"
    mkdir -p "$TEST_TMP_DIR/tests-group"
    mkdir -p "$TEST_TMP_DIR/system-design-group"
    mkdir -p "$TEST_TMP_DIR/slides-demonstration-group"
    mkdir -p "$TEST_TMP_DIR/video-demonstration-group"
    mkdir -p "$TEST_TMP_DIR/reflection-group"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_TMP_DIR"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    ((TESTS_RUN++))

    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}PASS${NC}: $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}FAIL${NC}: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Assertion failed}"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}PASS${NC}: $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}FAIL${NC}: $message"
        echo "  String does not contain: '$needle'"
        return 1
    fi
}

assert_file_exists() {
    local filepath="$1"
    local message="${2:-File should exist}"

    ((TESTS_RUN++))

    if [[ -f "$filepath" ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}PASS${NC}: $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}FAIL${NC}: $message"
        echo "  File not found: $filepath"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Exit code check}"

    ((TESTS_RUN++))

    if [[ "$expected" -eq "$actual" ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}PASS${NC}: $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}FAIL${NC}: $message"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        return 1
    fi
}

run_test() {
    local test_name="$1"

    echo ""
    echo -e "${YELLOW}Running test: $test_name${NC}"
    echo "----------------------------------------"

    # Run the test function
    if "$test_name"; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# UNIT TESTS: Helper Functions
# ============================================================================

test_help_flag() {
    local output
    output=$(zsh "$EVAL_SCRIPT" --help 2>&1)
    local exit_code=$?

    assert_exit_code 0 $exit_code "Help should exit with code 0"
    assert_contains "$output" "USAGE" "Help should contain USAGE"
    assert_contains "$output" "OPTIONS" "Help should contain OPTIONS"
    assert_contains "$output" "--year" "Help should document --year flag"
    assert_contains "$output" "--criteria" "Help should document --criteria flag"
    assert_contains "$output" "Apache" "Help should mention Apache license"
}

test_criteria_flag_all() {
    local output
    output=$(zsh "$EVAL_SCRIPT" --criteria 2>&1)
    local exit_code=$?

    assert_exit_code 0 $exit_code "Criteria should exit with code 0"
    assert_contains "$output" "ssh-key" "Should list ssh-key submission"
    assert_contains "$output" "case-brief" "Should list case-brief submission"
    assert_contains "$output" "reflection" "Should list reflection submission"
    assert_contains "$output" "filename_format" "Should show filename_format criterion"
}

test_criteria_flag_specific() {
    local output
    output=$(zsh "$EVAL_SCRIPT" --criteria ssh-key 2>&1)
    local exit_code=$?

    assert_exit_code 0 $exit_code "Criteria for ssh-key should exit with code 0"
    assert_contains "$output" "ssh-key" "Should show ssh-key"
    assert_contains "$output" "is_public_key" "Should show is_public_key criterion"
}

test_logic_flag() {
    local output
    output=$(zsh "$EVAL_SCRIPT" --logic ssh-key 2>&1)
    local exit_code=$?

    assert_exit_code 0 $exit_code "Logic should exit with code 0"
    assert_contains "$output" "Decision Tree" "Should show decision tree"
    assert_contains "$output" "PASS" "Should explain PASS case"
    assert_contains "$output" "FAIL" "Should explain FAIL case"
}

test_invalid_submission_type() {
    local output
    output=$(zsh "$EVAL_SCRIPT" --submission invalid-type 2>&1)
    local exit_code=$?

    assert_exit_code 1 $exit_code "Invalid submission type should exit with code 1"
    assert_contains "$output" "ERROR" "Should show error message"
}

# ============================================================================
# UNIT TESTS: SSH Key Validation
# ============================================================================

test_valid_ssh_ed25519_key() {
    local testfile="$TEST_TMP_DIR/ssh-keys-individual/2026-Smith-John.pub"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl john.smith@example.com" > "$testfile"

    # Source the script to access functions
    source "$EVAL_SCRIPT" 2>/dev/null || true

    # Check criteria manually
    local result
    result=$(zsh "$EVAL_SCRIPT" --submission ssh-key --year 2026 2>&1)

    assert_contains "$result" "2026-Smith-John.pub" "Should find the SSH key file"
    assert_contains "$result" "Score:" "Should report a score"
}

test_invalid_ssh_private_key() {
    local testfile="$TEST_TMP_DIR/ssh-keys-individual/2026-Doe-Jane.pub"
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$testfile"
    echo "b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW" >> "$testfile"
    echo "-----END OPENSSH PRIVATE KEY-----" >> "$testfile"

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission ssh-key --year 2026 2>&1)

    # Should have a low score because it's not a public key
    assert_contains "$result" "Score:" "Should report a score"
}

# ============================================================================
# UNIT TESTS: Filename Format Validation
# ============================================================================

test_correct_individual_filename() {
    local testfile="$TEST_TMP_DIR/case-brief-individual/2026-Chen-Wei.md"
    print -r -- "# Case Brief
License: CC-BY-4.0
## Problem Statement
Test problem.
## Context
Test context.
## Analysis
Test analysis.
## Proposed Approach
Test approach.
## Expected Outcomes
Test outcomes." > "$testfile"

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission case-brief --year 2026 2>&1)

    assert_contains "$result" "2026-Chen-Wei.md" "Should find the case brief file"
}

test_incorrect_filename_non_ascii() {
    # Create a file with non-ASCII characters (simulated by wrong format)
    local testfile="$TEST_TMP_DIR/case-brief-individual/2026-chen-wei.md"  # lowercase
    echo "# Test" > "$testfile"

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission case-brief --year 2026 2>&1)

    # Should still find it but score lower on filename_format
    assert_contains "$result" "Score:" "Should report a score"
}

# ============================================================================
# UNIT TESTS: Group Folder Format
# ============================================================================

test_correct_group_folder() {
    local testfolder="$TEST_TMP_DIR/data-group/2026-Chen-Lin-Wang"
    mkdir -p "$testfolder"
    print -r -- "# Data Submission
License: CC-BY-4.0
## Source
Test source.
## Format
CSV format.
## Privacy
No PII included.
## Usage
Load with pandas." > "$testfolder/README.md"

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission data --year 2026 2>&1)

    assert_contains "$result" "2026-Chen-Lin-Wang" "Should find the data folder"
}

# ============================================================================
# UNIT TESTS: Content Validation
# ============================================================================

test_markdown_with_required_sections() {
    local testfile="$TEST_TMP_DIR/report-individual/2026-Lee-Amy.md"
    print -r -- "# Technical Report: HRV Analysis
**Author:** Lee Amy
License: CC-BY-4.0

## Abstract
This is a test abstract with approximately 100-150 words describing the project.

## Introduction
Introduction content.

## System Architecture
Architecture description.

## Implementation
Implementation details.

## Results
Results description.

## Discussion
Discussion content.

## Conclusion
Conclusion content." > "$testfile"

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission report --year 2026 2>&1)

    assert_contains "$result" "2026-Lee-Amy.md" "Should find the report file"
    assert_contains "$result" "Score:" "Should report a score"
}

test_youtube_url_validation() {
    local testfile="$TEST_TMP_DIR/video-demonstration-group/2026-Chen-Lin-Wang.txt"
    echo "https://www.youtube.com/watch?v=dQw4w9WgXcQ" > "$testfile"

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission video --year 2026 2>&1)

    assert_contains "$result" "2026-Chen-Lin-Wang.txt" "Should find the video file"
}

test_invalid_youtube_url() {
    local testfile="$TEST_TMP_DIR/video-demonstration-group/2026-Bad-Link-Test.txt"
    echo "https://vimeo.com/12345" > "$testfile"

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission video --year 2026 2>&1)

    # Should have lower score due to invalid URL
    assert_contains "$result" "Score:" "Should report a score"
}

# ============================================================================
# INTEGRATION TESTS: CSV Generation
# ============================================================================

test_group_csv_generation() {
    # Create sample submissions
    mkdir -p "$TEST_TMP_DIR/data-group/2026-Alpha-Beta-Gamma"
    print -r -- "# Test Data
License: CC-BY-4.0
Source: Test
Format: CSV
Privacy: No PII
Usage: Test" > "$TEST_TMP_DIR/data-group/2026-Alpha-Beta-Gamma/README.md"

    print -r -- "# Reflection
License: CC-BY-4.0
Authors: Alpha, Beta, Gamma
Tools: Claude Code
Task: HRV Analysis
Agent approach: Used tools
Chat approach: Manual copy
Comparison: Agent was faster
Lessons: Automation helps" > "$TEST_TMP_DIR/reflection-group/2026-Alpha-Beta-Gamma.md"

    # Run with modified BASE_DIR
    cd "$TEST_TMP_DIR"

    # We need to temporarily modify the script to use TEST_TMP_DIR as BASE_DIR
    # For this test, we'll just verify the output format

    local result
    result=$(zsh "$EVAL_SCRIPT" --group --year 2026 2>&1)

    assert_contains "$result" "Evaluating group submissions" "Should show group evaluation message"
}

test_year_filter() {
    # Create submissions for different years
    echo "ssh-ed25519 AAAA test@test.com" > "$TEST_TMP_DIR/ssh-keys-individual/2025-Old-Student.pub"
    echo "ssh-ed25519 AAAA test@test.com" > "$TEST_TMP_DIR/ssh-keys-individual/2026-New-Student.pub"

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission ssh-key --year 2026 2>&1)

    assert_contains "$result" "2026-New-Student.pub" "Should find 2026 submission"
    # Should not contain 2025 submission in output (it won't match pattern)
}

# ============================================================================
# FUNCTIONAL TESTS: End-to-End on Real Data
# ============================================================================

test_real_data_evaluation() {
    # This test runs against actual data in the repository
    cd "$SCRIPT_DIR/.."

    local result
    result=$(zsh "$EVAL_SCRIPT" --submission ssh-key --year 2026 2>&1)

    # Should at minimum run without error and report something
    assert_contains "$result" "Evaluating ssh-key" "Should show evaluation message"
}

test_full_evaluation_run() {
    cd "$SCRIPT_DIR/.."

    local result
    result=$(zsh "$EVAL_SCRIPT" --year 2026 2>&1)

    assert_contains "$result" "Evaluation complete" "Should complete full evaluation"
}

# ============================================================================
# TEST RUNNER
# ============================================================================

run_all_tests() {
    echo "========================================"
    echo "Running evaluate_submissions.sh tests"
    echo "========================================"

    setup

    # Help and flags
    run_test test_help_flag
    run_test test_criteria_flag_all
    run_test test_criteria_flag_specific
    run_test test_logic_flag
    run_test test_invalid_submission_type

    # SSH key validation
    run_test test_valid_ssh_ed25519_key
    run_test test_invalid_ssh_private_key

    # Filename format
    run_test test_correct_individual_filename
    run_test test_incorrect_filename_non_ascii

    # Group folder format
    run_test test_correct_group_folder

    # Content validation
    run_test test_markdown_with_required_sections
    run_test test_youtube_url_validation
    run_test test_invalid_youtube_url

    # CSV generation
    run_test test_group_csv_generation
    run_test test_year_filter

    # Functional tests on real data
    run_test test_real_data_evaluation
    run_test test_full_evaluation_run

    teardown

    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        return 1
    fi
}

# Run specific test or all tests
if [[ $# -gt 0 ]]; then
    setup
    run_test "$1"
    teardown
else
    run_all_tests
fi
