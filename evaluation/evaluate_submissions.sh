#!/usr/bin/env zsh
#
# evaluate_submissions.sh - Evaluate course submissions for format compliance
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

set -eo pipefail

# Script directory and base paths
# Use $0 for zsh compatibility (BASH_SOURCE is bash-specific)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
CURRENT_YEAR=$(date +%Y)
YEAR="$CURRENT_YEAR"
GROUP_ONLY=false
INDIVIDUAL_ONLY=false
SPECIFIC_SUBMISSION=""
SHOW_CRITERIA=false
SHOW_LOGIC=false

# Submission types
INDIVIDUAL_SUBMISSIONS=("ssh-key" "case-brief" "report")
GROUP_SUBMISSIONS=("case-brief-group" "data" "project-code" "tests" "system-design" "slides" "video" "reflection")

# Folder mappings
declare -A FOLDER_MAP=(
    ["ssh-key"]="ssh-keys-individual"
    ["case-brief"]="case-brief-individual"
    ["report"]="report-individual"
    ["case-brief-group"]="case-brief-individual"
    ["data"]="data-group"
    ["project-code"]="project-code-group"
    ["tests"]="tests-group"
    ["system-design"]="system-design-group"
    ["slides"]="slides-demonstration-group"
    ["video"]="video-demonstration-group"
    ["reflection"]="reflection-group"
)

# ============================================================================
# HELP AND USAGE
# ============================================================================

show_help() {
    echo "evaluate_submissions.sh - Evaluate course submissions for format compliance"
    echo ""
    echo "USAGE:"
    echo "    ./evaluate_submissions.sh [OPTIONS]"
    echo ""
    echo "DESCRIPTION:"
    echo "    This script evaluates student submissions for the Agentic AI course,"
    echo "    checking if each submission fulfills the format requirements specified"
    echo "    in the respective README.md files."
    echo ""
    echo "    It generates two CSV files:"
    echo "    - YYYY_submissions_group.csv   - Group submission compliance"
    echo "    - YYYY_submissions_individual.csv - Individual submission compliance"
    echo ""
    echo "    Scores indicate compliance level:"
    echo "    - 100: Submitted and all format requirements fulfilled"
    echo "    - 1-99: Submitted but some requirements not fulfilled"
    echo "    - 0: Not submitted"
    echo ""
    echo "OPTIONS:"
    echo "    -y, --year YEAR       Year to evaluate (default: current year)"
    echo "    -g, --group           Generate only group CSV"
    echo "    -i, --individual      Generate only individual CSV"
    echo "    -s, --submission TYPE Check only specific submission type"
    echo "    -c, --criteria [TYPE] Show requirements for all or specific submission"
    echo "    -l, --logic [TYPE]    Show scoring algorithm for all or specific submission"
    echo "    -h, --help            Show this help message"
    echo ""
    echo "SUBMISSION TYPES:"
    echo "    Individual:"
    echo "        ssh-key           SSH public key submission"
    echo "        case-brief        Individual case brief"
    echo "        report            Technical report"
    echo ""
    echo "    Group:"
    echo "        case-brief-group  Group case brief"
    echo "        data              Data submission"
    echo "        project-code      Project code submission"
    echo "        tests             Test cases document"
    echo "        system-design     UML system design diagram"
    echo "        slides            Beamer presentation slides"
    echo "        video             Video demonstration (YouTube link)"
    echo "        reflection        Reflection document"
    echo ""
    echo "EXAMPLES:"
    echo "    # Evaluate all 2026 submissions"
    echo "    ./evaluate_submissions.sh"
    echo ""
    echo "    # Evaluate only group submissions for 2026"
    echo "    ./evaluate_submissions.sh --group"
    echo ""
    echo "    # Evaluate specific submission type"
    echo "    ./evaluate_submissions.sh --submission ssh-key"
    echo ""
    echo "    # Show requirements for case-brief"
    echo "    ./evaluate_submissions.sh --criteria case-brief"
    echo ""
    echo "    # Show scoring logic for all submissions"
    echo "    ./evaluate_submissions.sh --logic"
    echo ""
    echo "COPYRIGHT:"
    echo "    Copyright 2026 Torbjörn E. M. Nordling"
    echo "    Licensed under Apache License 2.0"
}

# ============================================================================
# CRITERIA DEFINITIONS (via get_criteria_array function)
# ============================================================================

is_valid_submission_type() {
    local sub="$1"
    for valid in "${INDIVIDUAL_SUBMISSIONS[@]}" "${GROUP_SUBMISSIONS[@]}"; do
        [[ "$valid" == "$sub" ]] && return 0
    done
    return 1
}

show_criteria() {
    local submission_type="${1:-all}"

    echo "========================================"
    echo "SUBMISSION REQUIREMENTS AND CRITERIA"
    echo "========================================"
    echo ""

    if [[ "$submission_type" == "all" ]]; then
        for sub in "${INDIVIDUAL_SUBMISSIONS[@]}" "${GROUP_SUBMISSIONS[@]}"; do
            print_criteria_for_submission "$sub"
        done
    else
        if is_valid_submission_type "$submission_type"; then
            print_criteria_for_submission "$submission_type"
        else
            echo "ERROR: Unknown submission type: $submission_type"
            echo "Valid types: ${INDIVIDUAL_SUBMISSIONS[*]} ${GROUP_SUBMISSIONS[*]}"
            exit 1
        fi
    fi
}

print_criteria_for_submission() {
    local sub="$1"
    echo "----------------------------------------"
    echo "Submission: $sub"
    echo "Folder: ${FOLDER_MAP[$sub]}"
    echo "----------------------------------------"
    echo ""
    echo "Criteria (weight: description):"
    echo ""

    local criteria_lines
    criteria_lines=$(get_criteria_array "$sub")

    local line
    for line in ${(f)criteria_lines}; do
        local name="${line%%:*}"
        local rest="${line#*:}"
        local weight="${rest%%:*}"
        local desc="${rest#*:}"
        printf "  %-25s %3d%%  %s\n" "$name" "$weight" "$desc"
    done
    echo ""
}

# ============================================================================
# LOGIC EXPLANATION
# ============================================================================

show_logic() {
    local submission_type="${1:-all}"

    echo "========================================"
    echo "SCORING ALGORITHM AND DECISION TREE"
    echo "========================================"
    echo ""
    echo "GENERAL ALGORITHM:"
    echo ""
    echo "1. For each submission folder, find files matching YYYY-* pattern"
    echo "2. Filter by the specified year"
    echo "3. For each submission found:"
    echo "   a. Check each criterion defined for that submission type"
    echo "   b. Each criterion has a weight (percentage of total score)"
    echo "   c. If criterion is met: add weight to score"
    echo "   d. If criterion not met: add to notes list"
    echo "4. Final score = sum of weights for met criteria"
    echo "5. Special cases:"
    echo "   - No submission found: score = 0"
    echo "   - Submission found but ALL criteria fail: score = 1"
    echo ""

    if [[ "$submission_type" == "all" ]]; then
        for sub in "${INDIVIDUAL_SUBMISSIONS[@]}" "${GROUP_SUBMISSIONS[@]}"; do
            print_logic_for_submission "$sub"
        done
    else
        if is_valid_submission_type "$submission_type"; then
            print_logic_for_submission "$submission_type"
        else
            echo "ERROR: Unknown submission type: $submission_type"
            exit 1
        fi
    fi
}

print_logic_for_submission() {
    local sub="$1"
    echo "----------------------------------------"
    echo "Decision Tree for: $sub"
    echo "----------------------------------------"
    echo ""
    echo "START"
    echo "  |"
    echo "  v"
    echo "Find files in ${FOLDER_MAP[$sub]}/ matching ${YEAR}-*"
    echo "  |"
    echo "  +-- No files found --> Score: 0, Notes: 'No submission'"
    echo "  |"
    echo "  v (files found)"
    echo "For each criterion:"
    echo ""

    local criteria_lines
    criteria_lines=$(get_criteria_array "$sub")

    local line
    for line in ${(f)criteria_lines}; do
        local name="${line%%:*}"
        local rest="${line#*:}"
        local weight="${rest%%:*}"
        echo "  Check: $name"
        echo "    |"
        echo "    +-- PASS --> Add $weight to score"
        echo "    +-- FAIL --> Add '$name' to notes"
        echo ""
    done

    echo "Calculate final score:"
    echo "  - If score == 0 but file exists: score = 1"
    echo "  - Otherwise: score = sum of passed criteria weights"
    echo ""
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Check if string contains only ASCII characters
is_ascii() {
    local str="$1"
    [[ "$str" =~ ^[[:print:]]+$ ]] && ! [[ "$str" =~ [^[:ascii:]] ]]
}

# Extract family names from filename
# Format: YYYY-FamilyName1-FamilyName2-FamilyName3.ext -> FamilyName1 FamilyName2 FamilyName3
extract_family_names() {
    local filename="$1"
    local basename="${filename%.*}"  # Remove extension
    # Remove year prefix
    local names="${basename#*-}"
    # For individual files (YYYY-FamilyName-FirstName), take only family name
    if [[ "$names" =~ ^([A-Za-z]+)-([A-Za-z]+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        # For group files, extract all family names (alphabetical list)
        echo "$names" | tr '-' ' '
    fi
}

# Extract full name for individual submissions
# Format: YYYY-FamilyName-FirstName.ext -> FamilyName FirstName
extract_full_name() {
    local filename="$1"
    local basename="${filename%.*}"
    local names="${basename#*-}"
    if [[ "$names" =~ ^([A-Za-z]+)-([A-Za-z]+)$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        echo "$names" | tr '-' ' '
    fi
}

# Check if filename matches year pattern
matches_year() {
    local filename="$1"
    local year="$2"
    [[ "$filename" =~ ^${year}- ]]
}

# ============================================================================
# CRITERION CHECK FUNCTIONS
# ============================================================================

# Check if file has correct individual filename format: YYYY-FamilyName-FirstName.ext
check_individual_filename_format() {
    local filepath="$1"
    local year="$2"
    local filename=$(basename "$filepath")

    # Pattern: YYYY-FamilyName-FirstName.ext (ASCII only, capital first letters)
    if [[ "$filename" =~ ^${year}-[A-Z][a-zA-Z]+-[A-Z][a-zA-Z]+\.[a-z]+$ ]]; then
        return 0
    fi
    return 1
}

# Check if file has correct group filename format: YYYY-FamilyName1-FamilyName2[-FamilyName3...].ext
check_group_filename_format() {
    local filepath="$1"
    local year="$2"
    local filename=$(basename "$filepath")

    # Pattern: YYYY-Name1-Name2[-Name3...].ext (at least 2 family names)
    if [[ "$filename" =~ ^${year}-[A-Z][a-zA-Z]+-[A-Z][a-zA-Z]+(-[A-Z][a-zA-Z]+)*\.[a-z]+$ ]]; then
        return 0
    fi
    return 1
}

# Check if folder has correct group folder format
check_group_folder_format() {
    local folderpath="$1"
    local year="$2"
    local foldername=$(basename "$folderpath")

    # Pattern: YYYY-Name1-Name2[-Name3...] (at least 2 family names, no extension)
    if [[ "$foldername" =~ ^${year}-[A-Z][a-zA-Z]+-[A-Z][a-zA-Z]+(-[A-Z][a-zA-Z]+)*$ ]]; then
        return 0
    fi
    return 1
}

# Check if file content contains a pattern (case-insensitive)
content_contains() {
    local filepath="$1"
    local pattern="$2"
    grep -qi "$pattern" "$filepath" 2>/dev/null
}

# Check if file is a valid SSH public key
is_valid_ssh_public_key() {
    local filepath="$1"
    local content=$(cat "$filepath" 2>/dev/null)

    # Should start with ssh-ed25519 or ssh-rsa
    [[ "$content" =~ ^ssh-(ed25519|rsa)[[:space:]] ]]
}

# Check if SSH key is single line
is_single_line_key() {
    local filepath="$1"
    local linecount=$(wc -l < "$filepath" 2>/dev/null | tr -d ' ')
    [[ "$linecount" -le 1 ]]
}

# Check if SSH key has email comment
has_email_comment() {
    local filepath="$1"
    local content=$(cat "$filepath" 2>/dev/null)
    [[ "$content" =~ [[:space:]][^[:space:]]+@[^[:space:]]+$ ]]
}

# Check if URL is valid YouTube format
is_youtube_url() {
    local content="$1"
    # Use grep for regex - zsh =~ has issues with complex patterns
    echo "$content" | grep -qE "^https?://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[a-zA-Z0-9_-]+"
}

# ============================================================================
# SUBMISSION EVALUATION FUNCTIONS
# ============================================================================

# Check a single criterion
# Returns: 0 if passed, 1 if failed
check_criterion() {
    local criterion="$1"
    local submission_type="$2"
    local filepath="$3"
    local year="$4"

    case "$criterion" in
        filename_format)
            if [[ "$submission_type" == "ssh-key" || "$submission_type" == "case-brief" || "$submission_type" == "report" ]]; then
                check_individual_filename_format "$filepath" "$year" && return 0
            else
                check_group_filename_format "$filepath" "$year" && return 0
            fi
            return 1
            ;;
        folder_format)
            check_group_folder_format "$filepath" "$year" && return 0
            return 1
            ;;
        file_extension)
            local ext="${filepath##*.}"
            case "$submission_type" in
                ssh-key) [[ "$ext" == "pub" ]] && return 0 ;;
                case-brief|case-brief-group|report|tests|reflection) [[ "$ext" == "md" ]] && return 0 ;;
                system-design) [[ "$ext" == "drawio" ]] && return 0 ;;
                slides) [[ "$ext" == "tex" ]] && return 0 ;;
                video) [[ "$ext" == "txt" ]] && return 0 ;;
            esac
            return 1
            ;;
        is_public_key)
            is_valid_ssh_public_key "$filepath" && return 0
            return 1
            ;;
        single_line)
            is_single_line_key "$filepath" && return 0
            return 1
            ;;
        has_email_comment)
            has_email_comment "$filepath" && return 0
            return 1
            ;;
        key_type_valid)
            local content=$(cat "$filepath" 2>/dev/null)
            [[ "$content" =~ ^ssh-(ed25519|rsa) ]] && return 0
            return 1
            ;;
        has_license)
            content_contains "$filepath" "license\|License\|LICENSE\|CC-BY\|Apache\|SPDX" && return 0
            return 1
            ;;
        has_title)
            content_contains "$filepath" "^#.*\|title\|Title" && return 0
            return 1
            ;;
        has_problem_statement)
            content_contains "$filepath" "problem\|Problem" && return 0
            return 1
            ;;
        has_context)
            content_contains "$filepath" "context\|Context\|background\|Background" && return 0
            return 1
            ;;
        has_analysis)
            content_contains "$filepath" "analysis\|Analysis" && return 0
            return 1
            ;;
        has_proposed_approach)
            content_contains "$filepath" "approach\|Approach\|solution\|Solution\|proposal\|Proposal" && return 0
            return 1
            ;;
        has_expected_outcomes)
            content_contains "$filepath" "outcome\|Outcome\|expected\|Expected" && return 0
            return 1
            ;;
        length_max_1250)
            # Count words in markdown file (excluding code blocks for fairness)
            local word_count
            word_count=$(cat "$filepath" 2>/dev/null | sed '/^```/,/^```$/d' | wc -w | tr -d ' ')
            [[ "$word_count" -le 1250 ]] && return 0
            return 1
            ;;
        length_max_750)
            # Count words in markdown file (excluding code blocks for fairness)
            local word_count
            word_count=$(cat "$filepath" 2>/dev/null | sed '/^```/,/^```$/d' | wc -w | tr -d ' ')
            [[ "$word_count" -le 750 ]] && return 0
            return 1
            ;;
        has_title_author)
            content_contains "$filepath" "author\|Author" && return 0
            return 1
            ;;
        has_abstract)
            content_contains "$filepath" "abstract\|Abstract" && return 0
            return 1
            ;;
        has_introduction)
            content_contains "$filepath" "introduction\|Introduction" && return 0
            return 1
            ;;
        has_system_architecture)
            content_contains "$filepath" "architecture\|Architecture" && return 0
            return 1
            ;;
        has_implementation)
            content_contains "$filepath" "implementation\|Implementation" && return 0
            return 1
            ;;
        has_results)
            content_contains "$filepath" "result\|Result\|demo\|Demo\|demonstration\|Demonstration" && return 0
            return 1
            ;;
        has_discussion)
            content_contains "$filepath" "discussion\|Discussion" && return 0
            return 1
            ;;
        has_conclusion)
            content_contains "$filepath" "conclusion\|Conclusion" && return 0
            return 1
            ;;
        has_conclusions)
            # For slides - check for conclusions section
            content_contains "$filepath" "conclusion\|Conclusion" && return 0
            return 1
            ;;
        has_problem)
            # For slides - check for problem statement or motivation
            content_contains "$filepath" "problem\|Problem\|motivation\|Motivation" && return 0
            return 1
            ;;
        has_challenges)
            # For slides - check for challenges or lessons learned section
            content_contains "$filepath" "challenge\|Challenge\|difficult\|Difficult\|lesson\|Lesson" && return 0
            return 1
            ;;
        no_template_files)
            # Check that NordlingLab beamer template files have been removed
            # Reference: https://bitbucket.org/nordlinglab/nordlinglab-template-beamer/
            local dir_name=$(dirname "$filepath")

            # List of template files that should not be included
            local template_files=(
                "NordlingLab_template_beamer.tex"
                "beamercolorthemeNordlingLab.sty"
                "beamerfontthemeNordlingLab.sty"
                "beamerinnerthemeNordlingLab.sty"
                "beamerouterthemeNordlingLab.sty"
                "beamerouterthemeNordlingLab169.sty"
                "beamerthemeNordlingLab.sty"
                "beamerthemeNordlingLab169.sty"
                "CClogo.pdf"
                "NCKUMElogo.pdf"
                "NCKUlogo.pdf"
                "NordlingLabbanner169.pdf"
                "NordlingLabbanner43.pdf"
                "NordlingLablogo.pdf"
                "NordlingLabtriple.pdf"
            )

            # Check if any template file exists in the submission directory
            local tfile
            for tfile in "${template_files[@]}"; do
                if [[ -f "$dir_name/$tfile" ]]; then
                    return 1
                fi
            done

            return 0
            ;;
        has_references)
            content_contains "$filepath" "reference\|Reference\|bibliography\|Bibliography\|citation\|Citation" && return 0
            return 1
            ;;
        figure_format)
            # Check if figures exist and are named correctly
            # Expected: YYYY-FamilyName-FirstName-FigureX.{pdf,png,jpg} or folder YYYY-FamilyName-FirstName-Figures/
            local base_name="${filepath%.*}"
            local dir_name=$(dirname "$filepath")
            local base_only=$(basename "$base_name")
            local figures_folder="${base_only}-Figures"

            # Check for figures folder
            if [[ -d "$dir_name/$figures_folder" ]]; then
                return 0
            fi

            # Check for individual figure files (YYYY-Name-Name-Figure1.pdf, etc.)
            # Use find instead of ls to avoid glob expansion errors
            if find "$dir_name" -maxdepth 1 -name "${base_only}-Figure*" \( -name "*.pdf" -o -name "*.png" -o -name "*.jpg" \) 2>/dev/null | grep -q .; then
                return 0
            fi

            # No figures found - check if the report mentions figures
            # If they mention figures but don't have properly named files, fail
            if content_contains "$filepath" "Figure\|figure\|Fig\\."; then
                # Report mentions figures - check if any image files exist in the directory
                if find "$dir_name" -maxdepth 1 \( -name "*.pdf" -o -name "*.png" -o -name "*.jpg" \) ! -name "*.md" 2>/dev/null | grep -q .; then
                    # Has some image files - could be figures (pass with benefit of doubt)
                    return 0
                fi
                return 1
            fi

            # No figures mentioned and none found - acceptable
            return 0
            ;;
        has_readme)
            [[ -f "$filepath/README.md" ]] && return 0
            return 1
            ;;
        readme_has_source)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "source\|Source" && return 0
            return 1
            ;;
        readme_has_license)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "license\|License" && return 0
            return 1
            ;;
        readme_has_format)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "format\|Format" && return 0
            return 1
            ;;
        readme_has_privacy)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "privacy\|Privacy\|PII\|identifiable" && return 0
            return 1
            ;;
        readme_has_statistics)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "statistic\|Statistic\|subject\|Subject\|sample\|Sample\|demographic\|Demographic\|rate\|Rate" && return 0
            return 1
            ;;
        readme_has_preprocessing)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "preprocess\|Preprocess\|transform\|Transform\|clean\|Clean\|filter\|Filter" && return 0
            return 1
            ;;
        readme_has_usage)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "usage\|Usage\|use\|Use" && return 0
            return 1
            ;;
        has_requirements)
            [[ -f "$filepath/requirements.txt" ]] && return 0
            return 1
            ;;
        only_ascii_filenames)
            # Check that all files in folder have ASCII-only names (bytes 0-127)
            local non_ascii
            non_ascii=$(find "$filepath" -type f 2>/dev/null | while read -r f; do
                local name=$(basename "$f")
                # Check if any byte value is >= 128 (non-ASCII)
                local has_non_ascii=$(printf '%s' "$name" | od -An -tu1 | tr ' ' '\n' | awk '$1 >= 128 {found=1; exit} END {print found+0}')
                if [[ "$has_non_ascii" == "1" ]]; then
                    echo "$f"
                fi
            done | head -1)
            [[ -z "$non_ascii" ]] && return 0
            return 1
            ;;
        has_license_file)
            # Check for LICENSE file (LICENSE, LICENSE.txt, LICENSE.md, etc.)
            if find "$filepath" -maxdepth 1 -name "LICENSE*" -type f 2>/dev/null | grep -q .; then
                return 0
            fi
            return 1
            ;;
        readme_has_title)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "^#\|title\|Title\|Project" && return 0
            return 1
            ;;
        readme_has_authors)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "author\|Author\|member\|Member\|team\|Team" && return 0
            return 1
            ;;
        readme_has_description)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "description\|Description\|what\|What\|overview\|Overview" && return 0
            return 1
            ;;
        readme_has_requirements)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "requirement\|Requirement\|depend\|Depend\|need\|Need" && return 0
            return 1
            ;;
        readme_has_api_keys)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "API\|api\|key\|Key\|credential\|Credential\|token\|Token" && return 0
            return 1
            ;;
        readme_has_testing)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "test\|Test\|pytest\|unittest" && return 0
            return 1
            ;;
        readme_has_known_issues)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "known issue\|Known Issue\|limitation\|Limitation\|caveat\|Caveat" && return 0
            return 1
            ;;
        readme_has_install)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "install\|Install\|setup\|Setup" && return 0
            return 1
            ;;
        readme_has_architecture)
            [[ -f "$filepath/README.md" ]] && content_contains "$filepath/README.md" "architecture\|Architecture" && return 0
            return 1
            ;;
        no_api_keys)
            if find "$filepath" -name "*.py" -exec grep -l "ANTHROPIC_API_KEY\s*=\s*['\"]sk-" {} \; 2>/dev/null | head -1 | grep -q .; then
                return 1
            fi
            return 0
            ;;
        has_overview)
            content_contains "$filepath" "overview\|Overview" && return 0
            return 1
            ;;
        has_test_summary)
            content_contains "$filepath" "summary\|Summary\|Total\|Passed\|Failed" && return 0
            return 1
            ;;
        has_usage)
            content_contains "$filepath" "usage\|Usage\|run\|Run" && return 0
            return 1
            ;;
        has_test_cases)
            content_contains "$filepath" "TC-\|test case\|Test Case" && return 0
            return 1
            ;;
        has_known_issues)
            content_contains "$filepath" "known issue\|Known Issue\|known issues\|Known Issues\|limitation\|Limitation" && return 0
            return 1
            ;;
        has_test_id)
            # Accept any sequential numbering scheme (TC-001, T-1, #1, 1., etc.)
            # Check for numbered test cases or explicit ID fields
            if grep -qE "(TC-|T-|#)?[0-9]+[.:)\s]|Test ID|test id|ID:" "$filepath" 2>/dev/null; then
                return 0
            fi
            return 1
            ;;
        has_unit_tests)
            content_contains "$filepath" "unit test\|Unit Test\|unit-test\|unittest" && return 0
            return 1
            ;;
        has_integration_tests)
            content_contains "$filepath" "integration test\|Integration Test\|integration-test" && return 0
            return 1
            ;;
        has_e2e_tests)
            content_contains "$filepath" "end-to-end\|End-to-End\|e2e\|E2E\|end to end\|End to End" && return 0
            return 1
            ;;
        has_test_description)
            content_contains "$filepath" "description\|Description\|what the test\|What the test" && return 0
            return 1
            ;;
        has_preconditions)
            content_contains "$filepath" "precondition\|Precondition\|pre-condition\|Pre-condition\|setup\|Setup\|required state" && return 0
            return 1
            ;;
        has_input)
            content_contains "$filepath" "input\|Input\|test data\|Test data\|parameter\|Parameter" && return 0
            return 1
            ;;
        has_expected_output)
            content_contains "$filepath" "expected output\|Expected Output\|expected result\|Expected Result\|should happen\|Should happen" && return 0
            return 1
            ;;
        has_actual_output)
            content_contains "$filepath" "actual output\|Actual Output\|actual result\|Actual Result\|actually happened\|Actually happened" && return 0
            return 1
            ;;
        has_status)
            content_contains "$filepath" "PASS\|FAIL\|PARTIAL\|status\|Status" && return 0
            return 1
            ;;
        has_result_summary)
            content_contains "$filepath" "result summary\|Result Summary\|summary\|Summary\|statistics\|Statistics\|pass/fail\|Pass/Fail" && return 0
            return 1
            ;;
        has_failed_analysis)
            content_contains "$filepath" "failed test\|Failed Test\|root cause\|Root Cause\|impact\|Impact\|recommendation\|Recommendation" && return 0
            return 1
            ;;
        has_performance_metrics)
            content_contains "$filepath" "performance\|Performance\|execution time\|Execution Time\|coverage\|Coverage" && return 0
            return 1
            ;;
        has_pdf)
            local dir=$(dirname "$filepath")
            local base=$(basename "$filepath" .drawio)
            [[ -f "$dir/${base}.pdf" ]] && return 0
            return 1
            ;;
        pdf_single_page)
            # Check that PDF export has exactly one page
            local dir=$(dirname "$filepath")
            local base=$(basename "$filepath" .drawio)
            local pdf_file="$dir/${base}.pdf"

            if [[ ! -f "$pdf_file" ]]; then
                # No PDF file, can't check
                return 1
            fi

            local page_count=""
            if command -v exiftool &>/dev/null; then
                page_count=$(exiftool -PageCount -s -s -s "$pdf_file" 2>/dev/null)
            elif command -v pdfinfo &>/dev/null; then
                page_count=$(pdfinfo "$pdf_file" 2>/dev/null | grep -i "^Pages:" | awk '{print $2}')
            else
                # Neither tool available, pass by default
                return 0
            fi

            [[ "$page_count" == "1" ]] && return 0
            return 1
            ;;
        uses_uml)
            content_contains "$filepath" "component\|<<\|stereotype" && return 0
            return 1
            ;;
        has_components)
            content_contains "$filepath" "mxCell\|component\|<<" && return 0
            return 1
            ;;
        has_connections)
            content_contains "$filepath" "edge\|arrow\|flow" && return 0
            return 1
            ;;
        uses_beamer)
            content_contains "$filepath" "documentclass.*beamer\|beamer" && return 0
            return 1
            ;;
        uses_169_aspect)
            content_contains "$filepath" "aspectratio=169\|169" && return 0
            return 1
            ;;
        uses_nordlinglab_theme)
            content_contains "$filepath" "NordlingLab169\|NordlingLab" && return 0
            return 1
            ;;
        has_title_slide)
            content_contains "$filepath" "titlepage\|title" && return 0
            return 1
            ;;
        has_required_sections)
            content_contains "$filepath" "section\|begin{frame}" && return 0
            return 1
            ;;
        contains_youtube_url|url_format_valid)
            local content=$(cat "$filepath" 2>/dev/null | head -1)
            is_youtube_url "$content" && return 0
            return 1
            ;;
        url_is_single_line)
            local linecount=$(wc -l < "$filepath" 2>/dev/null | tr -d ' ')
            [[ "$linecount" -le 1 ]] && return 0
            return 1
            ;;
        is_public)
            # Two-step check:
            # 1. Verify URL returns a valid YouTube video (works without yt-dlp)
            # 2. Check if video is public (requires yt-dlp)
            local url=$(cat "$filepath" 2>/dev/null | head -1 | tr -d '[:space:]')
            if ! is_youtube_url "$url"; then
                return 1
            fi

            # Step 1: Check if video exists using YouTube oEmbed API (no yt-dlp needed)
            # oEmbed returns 200 for valid public videos, 401/404 for unavailable
            local oembed_url="https://www.youtube.com/oembed?url=${url}&format=json"
            local http_code
            http_code=$(curl -s -o /dev/null -w "%{http_code}" "$oembed_url" 2>/dev/null)
            if [[ "$http_code" != "200" ]]; then
                # Video doesn't exist or is not accessible
                return 1
            fi

            # Step 2: If yt-dlp available, verify it's public (not unlisted)
            if command -v yt-dlp &>/dev/null; then
                local availability
                availability=$(yt-dlp --skip-download --no-warnings --print "%(availability)s" "$url" 2>/dev/null)
                if [[ "$availability" == "public" ]]; then
                    return 0
                fi
                # If we got any response, video exists - check if it's not private
                if [[ -n "$availability" && "$availability" != "private" ]]; then
                    return 0
                fi
            else
                # yt-dlp not installed - oEmbed passed, so video is likely public
                return 0
            fi
            return 1
            ;;
        duration_max_12min)
            # Check if video duration is max 12.5 minutes (750 seconds)
            local url=$(cat "$filepath" 2>/dev/null | head -1 | tr -d '[:space:]')
            if ! command -v yt-dlp &>/dev/null; then
                return 0
            fi
            if ! is_youtube_url "$url"; then
                return 1
            fi
            local duration
            duration=$(yt-dlp --skip-download --no-warnings --print "%(duration)s" "$url" 2>/dev/null)
            if [[ -z "$duration" || "$duration" == "NA" ]]; then
                return 1
            fi
            # Max 750 seconds (12.5 minutes)
            [[ "$duration" -le 750 ]] && return 0
            return 1
            ;;
        resolution_min_1080p)
            # Check if video has at least 1080p resolution available
            local url=$(cat "$filepath" 2>/dev/null | head -1 | tr -d '[:space:]')
            if ! command -v yt-dlp &>/dev/null; then
                return 0
            fi
            if ! is_youtube_url "$url"; then
                return 1
            fi
            local height
            height=$(yt-dlp --skip-download --no-warnings --print "%(height)s" "$url" 2>/dev/null)
            if [[ -z "$height" || "$height" == "NA" ]]; then
                return 1
            fi
            # Min 1080 pixels height
            [[ "$height" -ge 1080 ]] && return 0
            return 1
            ;;
        has_subtitles)
            # Check if video has subtitles (English or Chinese)
            local url=$(cat "$filepath" 2>/dev/null | head -1 | tr -d '[:space:]')
            if ! command -v yt-dlp &>/dev/null; then
                return 0
            fi
            if ! is_youtube_url "$url"; then
                return 1
            fi
            local subs
            subs=$(yt-dlp --skip-download --no-warnings --list-subs "$url" 2>/dev/null)
            # Check for any subtitles (en, zh, zh-TW, zh-Hant, or auto-generated)
            if echo "$subs" | grep -qiE "^(en|zh|zh-TW|zh-Hant|zh-Hans)"; then
                return 0
            fi
            # Also accept auto-generated subtitles
            if echo "$subs" | grep -qi "subtitle"; then
                return 0
            fi
            return 1
            ;;
        has_authors)
            content_contains "$filepath" "author\|Author\|group\|Group\|member\|Member" && return 0
            return 1
            ;;
        has_tools)
            content_contains "$filepath" "tool\|Tool" && return 0
            return 1
            ;;
        has_task_description)
            content_contains "$filepath" "task\|Task" && return 0
            return 1
            ;;
        has_agent_approach)
            content_contains "$filepath" "agent\|Agent" && return 0
            return 1
            ;;
        has_chat_approach)
            content_contains "$filepath" "chat\|Chat" && return 0
            return 1
            ;;
        has_comparison)
            content_contains "$filepath" "comparison\|Comparison\|vs\|VS" && return 0
            return 1
            ;;
        has_lessons)
            content_contains "$filepath" "lesson\|Lesson\|learn\|Learn" && return 0
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Get criteria for a submission type as array
# Format: array of "name:weight:desc"
get_criteria_array() {
    local submission_type="$1"

    case "$submission_type" in
        ssh-key)
            echo "filename_format:20:File named correctly"
            echo "file_extension:15:Has .pub extension"
            echo "is_public_key:25:Is valid public key"
            echo "single_line:15:Key on single line"
            echo "has_email_comment:15:Has email comment"
            echo "key_type_valid:10:Valid key type"
            ;;
        case-brief)
            echo "filename_format:15:File named correctly"
            echo "file_extension:10:Has .md extension"
            echo "has_license:10:Has license"
            echo "has_title:10:Has title"
            echo "has_problem_statement:10:Has problem statement"
            echo "has_context:10:Has context"
            echo "has_analysis:10:Has analysis"
            echo "has_proposed_approach:10:Has approach"
            echo "has_expected_outcomes:10:Has outcomes"
            echo "length_max_1250:5:Length max 1250 words"
            ;;
        report)
            echo "filename_format:10:File named correctly"
            echo "file_extension:5:Has .md extension"
            echo "figure_format:5:Figures named correctly"
            echo "has_license:8:Has license"
            echo "has_title_author:8:Has title/author"
            echo "has_abstract:8:Has abstract"
            echo "has_introduction:8:Has introduction"
            echo "has_system_architecture:8:Has architecture"
            echo "has_implementation:8:Has implementation"
            echo "has_results:8:Has results"
            echo "has_discussion:8:Has discussion"
            echo "has_conclusion:8:Has conclusion"
            echo "has_references:8:Has references"
            ;;
        case-brief-group)
            echo "filename_format:15:File named correctly"
            echo "file_extension:10:Has .md extension"
            echo "has_license:10:Has license"
            echo "has_title:10:Has title"
            echo "has_problem_statement:10:Has problem statement"
            echo "has_context:10:Has context"
            echo "has_analysis:10:Has analysis"
            echo "has_proposed_approach:10:Has approach"
            echo "has_expected_outcomes:10:Has outcomes"
            echo "length_max_1250:5:Length max 1250 words"
            ;;
        data)
            echo "folder_format:10:Folder named correctly"
            echo "has_readme:10:Has README.md"
            echo "only_ascii_filenames:8:Only ASCII filenames"
            # README sections
            echo "readme_has_title:8:README has title"
            echo "readme_has_authors:8:README has authors"
            echo "readme_has_source:8:README has source"
            echo "readme_has_license:8:README has license"
            echo "readme_has_statistics:8:README has statistics"
            echo "readme_has_format:8:README has format"
            echo "readme_has_preprocessing:8:README has preprocessing"
            echo "readme_has_privacy:8:README has privacy"
            echo "readme_has_usage:8:README has usage"
            ;;
        project-code)
            echo "folder_format:10:Folder named correctly"
            echo "has_readme:10:Has README.md"
            echo "has_license_file:5:Has LICENSE file"
            echo "has_requirements:10:Has requirements.txt"
            echo "no_api_keys:5:No hardcoded keys"
            echo "only_ascii_filenames:5:Only ASCII filenames"
            # README sections
            echo "readme_has_title:5:README has title"
            echo "readme_has_authors:5:README has authors"
            echo "readme_has_license:5:README has license"
            echo "readme_has_description:5:README has description"
            echo "readme_has_requirements:5:README has requirements"
            echo "readme_has_api_keys:5:README has API keys"
            echo "readme_has_install:5:README has install"
            echo "readme_has_usage:5:README has usage"
            echo "readme_has_architecture:5:README has architecture"
            echo "readme_has_testing:5:README has testing"
            echo "readme_has_known_issues:5:README has known issues"
            ;;
        tests)
            echo "filename_format:5:File named correctly"
            echo "file_extension:5:Has .md extension"
            echo "has_license:5:Has license"
            echo "has_overview:5:Has overview"
            echo "has_usage:5:Has usage"
            echo "has_known_issues:5:Has known issues"
            # Test types
            echo "has_unit_tests:5:Has unit tests"
            echo "has_integration_tests:5:Has integration tests"
            echo "has_e2e_tests:5:Has E2E tests"
            # Test case fields
            echo "has_test_id:5:Has test ID"
            echo "has_test_description:5:Has test description"
            echo "has_preconditions:5:Has preconditions"
            echo "has_input:5:Has input"
            echo "has_expected_output:5:Has expected output"
            echo "has_actual_output:5:Has actual output"
            echo "has_status:5:Has status"
            # Analysis fields
            echo "has_result_summary:5:Has result summary"
            echo "has_failed_analysis:5:Has failed analysis"
            echo "has_performance_metrics:5:Has performance"
            echo "has_conclusion:5:Has conclusion"
            ;;
        system-design)
            echo "filename_format:10:File named correctly"
            echo "file_extension:10:Has .drawio extension"
            echo "has_pdf:15:Has exported PDF"
            echo "pdf_single_page:10:PDF is single page"
            echo "has_license:10:Has license"
            echo "uses_uml:15:Uses UML"
            echo "has_components:15:Has components"
            echo "has_connections:15:Has connections"
            ;;
        slides)
            echo "filename_format:15:File named correctly"
            echo "file_extension:5:Has .tex extension"
            echo "figure_format:5:Figures named correctly"
            echo "no_template_files:10:No template files"
            echo "has_license:5:Has license"
            echo "has_title_slide:5:Has title slide"
            echo "has_problem:5:Has problem"
            echo "has_system_architecture:5:Has architecture"
            echo "has_results:5:Has results"
            echo "has_challenges:5:Has challenges"
            echo "has_conclusions:5:Has conclusions"
            echo "uses_beamer:10:Uses Beamer"
            echo "uses_169_aspect:10:Uses 16:9"
            echo "uses_nordlinglab_theme:10:Uses NL theme"
            ;;
        video)
            echo "filename_format:10:File named correctly"
            echo "file_extension:5:Has .txt extension"
            echo "contains_youtube_url:15:Has YouTube URL"
            echo "url_is_single_line:5:Single line"
            echo "url_format_valid:5:Valid URL format"
            echo "is_public:15:Video is public"
            echo "duration_max_12min:15:Duration max 12.5 min"
            echo "resolution_min_1080p:15:Resolution min 1080p"
            echo "has_subtitles:15:Has subtitles"
            ;;
        reflection)
            echo "filename_format:10:File named correctly"
            echo "file_extension:8:Has .md extension"
            echo "length_max_750:10:Length max 750 words"
            echo "has_license:8:Has license"
            echo "has_authors:8:Has authors"
            echo "has_tools:8:Has tools"
            echo "has_task_description:8:Has task desc"
            echo "has_agent_approach:8:Has agent approach"
            echo "has_chat_approach:8:Has chat approach"
            echo "has_comparison:8:Has comparison"
            echo "has_lessons:8:Has lessons"
            echo "has_analysis:8:Has analysis"
            ;;
    esac
}

# Evaluate a single file against criteria
# Returns: score and notes separated by |
evaluate_submission() {
    local submission_type="$1"
    local filepath="$2"
    local year="$3"

    local score=0
    local notes=""

    # Get criteria as lines
    local criteria_lines
    criteria_lines=$(get_criteria_array "$submission_type")

    # Process each criterion
    local line
    for line in ${(f)criteria_lines}; do
        local criterion="${line%%:*}"
        local rest="${line#*:}"
        local weight="${rest%%:*}"

        if check_criterion "$criterion" "$submission_type" "$filepath" "$year"; then
            score=$((score + weight))
        else
            [[ -n "$notes" ]] && notes="$notes; "
            notes="${notes}${criterion}"
        fi
    done

    # If score is 0 but file exists, set to 1
    if [[ $score -eq 0 ]]; then
        score=1
    fi

    echo "${score}|${notes}"
}

# ============================================================================
# FIND SUBMISSIONS
# ============================================================================

# Find all individual submissions of a type for a year
find_individual_submissions() {
    local submission_type="$1"
    local year="$2"
    local folder="${FOLDER_MAP[$submission_type]}"
    local folder_path="$BASE_DIR/$folder"

    [[ ! -d "$folder_path" ]] && return

    case "$submission_type" in
        ssh-key)
            find "$folder_path" -maxdepth 1 -name "${year}-*.pub" -type f 2>/dev/null | sort
            ;;
        case-brief|report)
            # Find individual markdown files (YYYY-FamilyName-FirstName.md format)
            find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | while read -r f; do
                local basename=$(basename "$f" .md)
                local name_part="${basename#${year}-}"
                # Individual format: exactly two name parts separated by dash
                if [[ "$name_part" =~ ^[A-Za-z]+-[A-Za-z]+$ ]]; then
                    echo "$f"
                fi
            done | sort
            ;;
    esac
}

# Find all group submissions of a type for a year
find_group_submissions() {
    local submission_type="$1"
    local year="$2"
    local folder="${FOLDER_MAP[$submission_type]}"
    local folder_path="$BASE_DIR/$folder"

    [[ ! -d "$folder_path" ]] && return

    case "$submission_type" in
        case-brief-group)
            # Find group markdown files (3+ name parts)
            find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | while read -r f; do
                local basename=$(basename "$f" .md)
                local name_part="${basename#${year}-}"
                # Group format: at least 3 name parts
                local dash_count=$(echo "$name_part" | tr -cd '-' | wc -c)
                if [[ "$dash_count" -ge 2 ]]; then
                    echo "$f"
                fi
            done | sort
            ;;
        data|project-code)
            # Find folders
            find "$folder_path" -maxdepth 1 -type d -name "${year}-*" 2>/dev/null | sort
            ;;
        tests|reflection)
            # Find markdown files
            find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | sort
            ;;
        system-design)
            find "$folder_path" -maxdepth 1 -name "${year}-*.drawio" -type f 2>/dev/null | sort
            ;;
        slides)
            find "$folder_path" -maxdepth 1 -name "${year}-*.tex" -type f 2>/dev/null | sort
            ;;
        video)
            find "$folder_path" -maxdepth 1 -name "${year}-*.txt" -type f 2>/dev/null | sort
            ;;
    esac
}

# ============================================================================
# CSV OPERATIONS
# ============================================================================

# Initialize CSV with headers
initialize_group_csv() {
    local csvfile="$1"

    local header="Group Members"
    for sub in "${GROUP_SUBMISSIONS[@]}"; do
        header="$header,$sub"
    done
    for sub in "${GROUP_SUBMISSIONS[@]}"; do
        header="$header,${sub}_notes"
    done

    echo "$header" > "$csvfile"
}

initialize_individual_csv() {
    local csvfile="$1"

    local header="Student Name"
    for sub in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
        header="$header,$sub"
    done
    for sub in "${GROUP_SUBMISSIONS[@]}"; do
        header="$header,$sub"
    done
    for sub in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
        header="$header,${sub}_notes"
    done
    for sub in "${GROUP_SUBMISSIONS[@]}"; do
        header="$header,${sub}_notes"
    done

    echo "$header" > "$csvfile"
}

# Read existing CSV into associative array
# Format: results[row_key,column_name] = value
declare -A CSV_DATA

load_csv() {
    local csvfile="$1"
    local header line_num line row_key i
    local -a values

    [[ ! -f "$csvfile" ]] && return 1

    # Read header
    IFS= read -r header < "$csvfile"
    # Use zsh array splitting (no here-strings needed)
    CSV_COLUMNS=(${(s:,:)header})

    # Read data rows
    line_num=0
    while IFS= read -r line; do
        ((line_num++))
        [[ $line_num -eq 1 ]] && continue  # Skip header

        # Use zsh array splitting
        values=(${(s:,:)line})
        row_key="${values[1]}"  # zsh arrays are 1-indexed

        for i in {1..${#CSV_COLUMNS[@]}}; do
            # Note: Do NOT quote the key - zsh stores literal quotes
            CSV_DATA[$row_key,${CSV_COLUMNS[$i]}]=${values[$i]:-}
        done
    done < "$csvfile"

    return 0
}

# Update or add a value in CSV data
# Warns if new value is lower than existing
# Note: row_key should use underscores instead of spaces for storage
update_csv_value() {
    local row_key="$1"
    local column="$2"
    local new_value="$3"

    # Convert spaces to underscores in key for storage
    local storage_key="${row_key// /_}"

    local existing="${CSV_DATA[$storage_key,$column]:-}"

    if [[ -n "$existing" && "$existing" =~ ^[0-9]+$ && "$new_value" =~ ^[0-9]+$ ]]; then
        if [[ "$new_value" -lt "$existing" ]]; then
            echo "WARNING: Score lowered for '$row_key' in '$column': $existing -> $new_value"
        fi
    fi

    CSV_DATA[$storage_key,$column]=$new_value
}

# Write CSV data to file
write_csv() {
    local csvfile="$1"
    local header="$2"
    local key row_key row col display_name
    local -a header_cols
    local -a unique_rows

    print -r -- "$header" > "$csvfile"

    # Get unique row keys into an array (keys use underscores)
    # Note: Do NOT quote ${(k)...} - quoting adds literal quotes to keys
    typeset -A row_keys_map
    for key in ${(k)CSV_DATA}; do
        row_key="${key%%,*}"
        row_keys_map[$row_key]=1
    done
    unique_rows=(${(k)row_keys_map})

    # Write each row
    # Use zsh array splitting
    header_cols=(${(s:,:)header})
    for row_key in ${unique_rows[@]}; do
        # Convert underscores back to spaces for display
        display_name="${row_key//_/ }"
        row="$display_name"
        for col in ${header_cols[@]:1}; do  # Skip first column (row key)
            row="$row,${CSV_DATA[$row_key,$col]:-0}"
        done
        print -r -- "$row"
    done | sort >> "$csvfile"
}

# ============================================================================
# MAIN EVALUATION LOGIC
# ============================================================================

evaluate_group_submissions() {
    local year="$1"
    local csvfile="${year}_submissions_group.csv"

    echo "Evaluating group submissions for year $year..."
    echo ""

    # Clear any existing CSV data (start fresh each run)
    CSV_DATA=()

    # Build header
    local header="Group Members"
    for sub in "${GROUP_SUBMISSIONS[@]}"; do
        header="$header,$sub"
    done
    for sub in "${GROUP_SUBMISSIONS[@]}"; do
        header="$header,${sub}_notes"
    done

    # Track which groups we've found
    declare -A found_groups

    # Evaluate each submission type
    local submissions filepath group_key filename result score notes display_key
    for submission_type in "${GROUP_SUBMISSIONS[@]}"; do
        echo "Checking $submission_type submissions..."

        submissions=$(find_group_submissions "$submission_type" "$year")

        if [[ -z "$submissions" ]]; then
            echo "  No submissions found"
            continue
        fi

        # Use zsh array splitting to iterate (avoids here-string temp files)
        for filepath in ${(f)submissions}; do
            [[ -z "$filepath" ]] && continue

            filename=$(basename "$filepath")

            if [[ -d "$filepath" ]]; then
                group_key=$(basename "$filepath")
            else
                group_key="${filename%.*}"
            fi
            group_key="${group_key#${year}-}"
            # Strip common suffixes from group key
            group_key="${group_key%-data}"
            group_key="${group_key%-code}"
            group_key="${group_key%-Figures}"

            echo "  Found: $filename"

            result=$(evaluate_submission "$submission_type" "$filepath" "$year")
            score="${result%%|*}"
            notes="${result#*|}"

            # Convert group key to display format (space-separated)
            display_key=$(echo "$group_key" | tr '-' ' ')

            # Store with underscores in found_groups to avoid quoting issues
            # Note: Do NOT use quotes around $storage_key_for_group - zsh stores literal quotes
            local storage_key_for_group="${display_key// /_}"
            found_groups[$storage_key_for_group]=1
            update_csv_value "$display_key" "$submission_type" "$score"
            update_csv_value "$display_key" "${submission_type}_notes" "$notes"
        done

        echo ""
    done

    # Set score 0 for groups with no submission for a type
    # found_groups keys are already underscore-based to avoid quoting issues
    # Note: Do NOT quote ${(k)found_groups} - quoting adds literal quotes to keys
    local group_storage_key group_display
    for group_storage_key in ${(k)found_groups}; do
        # Convert underscores back to spaces for display
        group_display="${group_storage_key//_/ }"
        for submission_type in "${GROUP_SUBMISSIONS[@]}"; do
            if [[ -z "${CSV_DATA[$group_storage_key,$submission_type]:-}" ]]; then
                update_csv_value "$group_display" "$submission_type" "0"
                update_csv_value "$group_display" "${submission_type}_notes" "No submission"
            fi
        done
    done

    # Write CSV
    write_csv "$csvfile" "$header"
    echo "Group CSV written to: $csvfile"
}

evaluate_individual_submissions() {
    local year="$1"
    local group_csvfile="${year}_submissions_group.csv"
    local csvfile="${year}_submissions_individual.csv"

    echo ""
    echo "Evaluating individual submissions for year $year..."
    echo ""

    # Clear any existing CSV data (start fresh each run)
    CSV_DATA=()

    # Build header
    local header="Student Name"
    for sub in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
        header="$header,$sub"
    done
    for sub in "${GROUP_SUBMISSIONS[@]}"; do
        header="$header,$sub"
    done
    for sub in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
        header="$header,${sub}_notes"
    done
    for sub in "${GROUP_SUBMISSIONS[@]}"; do
        header="$header,${sub}_notes"
    done

    # Track students
    declare -A found_students
    declare -A student_groups  # Map student to their group key

    # Declare loop variables (all at start to avoid zsh output issues)
    local submissions filepath filename result score notes base name_part family_name first_name student_key
    local group_members rest idx sub student student_family notes_idx
    local -a values

    # Evaluate individual submissions
    for submission_type in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
        echo "Checking $submission_type submissions..."

        submissions=$(find_individual_submissions "$submission_type" "$year")

        if [[ -z "$submissions" ]]; then
            echo "  No submissions found"
            continue
        fi

        # Use zsh array splitting to iterate (avoids here-string temp files)
        for filepath in ${(f)submissions}; do
            [[ -z "$filepath" ]] && continue

            filename=$(basename "$filepath")
            echo "  Found: $filename"

            result=$(evaluate_submission "$submission_type" "$filepath" "$year")
            score="${result%%|*}"
            notes="${result#*|}"

            # Extract student name
            base="${filename%.*}"
            name_part="${base#${year}-}"
            family_name="${name_part%%-*}"
            first_name="${name_part#*-}"
            student_key="$family_name $first_name"

            found_students[$student_key]=1
            update_csv_value "$student_key" "$submission_type" "$score"
            update_csv_value "$student_key" "${submission_type}_notes" "$notes"
        done

        echo ""
    done

    # Load group CSV to copy group scores
    if [[ -f "$group_csvfile" ]]; then
        echo "Copying group scores from $group_csvfile..."

        # Build mapping from student family names to group scores
        while IFS=',' read -r group_members rest; do
            [[ "$group_members" == "Group Members" ]] && continue

            # Use zsh array splitting
            values=(${(s:,:):-${group_members},${rest}})

            # Parse the CSV line properly
            idx=0
            for sub in "${GROUP_SUBMISSIONS[@]}"; do
                ((idx++))
                score="${values[$((idx+1))]:-0}"  # zsh arrays are 1-indexed

                # Find notes column
                notes_idx=$((idx + 1 + ${#GROUP_SUBMISSIONS[@]}))
                notes="${values[$notes_idx]:-}"

                # Assign to each student whose family name is in the group
                for student in ${(k)found_students}; do
                    student_family="${student%% *}"
                    if [[ "$group_members" == *"$student_family"* ]]; then
                        update_csv_value "$student" "$sub" "$score"
                        update_csv_value "$student" "${sub}_notes" "$notes"
                        student_groups[$student]=$group_members
                    fi
                done
            done
        done < "$group_csvfile"
    fi

    # Set score 0 for students with no submission
    local storage_key
    for student in ${(k)found_students}; do
        storage_key="${student// /_}"
        for submission_type in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
            if [[ -z "${CSV_DATA[$storage_key,$submission_type]:-}" ]]; then
                update_csv_value "$student" "$submission_type" "0"
                update_csv_value "$student" "${submission_type}_notes" "No submission"
            fi
        done
        for submission_type in "${GROUP_SUBMISSIONS[@]}"; do
            if [[ -z "${CSV_DATA[$storage_key,$submission_type]:-}" ]]; then
                update_csv_value "$student" "$submission_type" "0"
                update_csv_value "$student" "${submission_type}_notes" "No group submission"
            fi
        done
    done

    # Write CSV
    write_csv "$csvfile" "$header"
    echo "Individual CSV written to: $csvfile"
}

# Evaluate a single submission type
evaluate_single_submission() {
    local submission_type="$1"
    local year="$2"

    echo "Evaluating $submission_type submissions for year $year..."
    echo ""

    local is_individual=false
    for sub in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
        [[ "$sub" == "$submission_type" ]] && is_individual=true
    done

    if $is_individual; then
        local submissions=$(find_individual_submissions "$submission_type" "$year")

        if [[ -z "$submissions" ]]; then
            echo "No submissions found for $submission_type"
            return
        fi

        # Use zsh array splitting to iterate (avoids here-string temp files)
        local filepath
        for filepath in ${(f)submissions}; do
            [[ -z "$filepath" ]] && continue

            local filename=$(basename "$filepath")
            echo "Evaluating: $filename"

            local result=$(evaluate_submission "$submission_type" "$filepath" "$year")
            local score="${result%%|*}"
            local notes="${result#*|}"

            echo "  Score: $score"
            [[ -n "$notes" ]] && echo "  Missing: $notes"
            echo ""
        done
    else
        local submissions=$(find_group_submissions "$submission_type" "$year")

        if [[ -z "$submissions" ]]; then
            echo "No submissions found for $submission_type"
            return
        fi

        # Use zsh array splitting to iterate (avoids here-string temp files)
        local filepath
        for filepath in ${(f)submissions}; do
            [[ -z "$filepath" ]] && continue

            local filename=$(basename "$filepath")
            echo "Evaluating: $filename"

            local result=$(evaluate_submission "$submission_type" "$filepath" "$year")
            local score="${result%%|*}"
            local notes="${result#*|}"

            echo "  Score: $score"
            [[ -n "$notes" ]] && echo "  Missing: $notes"
            echo ""
        done
    fi
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--year)
                YEAR="$2"
                shift 2
                ;;
            -g|--group)
                GROUP_ONLY=true
                shift
                ;;
            -i|--individual)
                INDIVIDUAL_ONLY=true
                shift
                ;;
            -s|--submission)
                SPECIFIC_SUBMISSION="$2"
                shift 2
                ;;
            -c|--criteria)
                SHOW_CRITERIA=true
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    SPECIFIC_SUBMISSION="$2"
                    shift
                fi
                shift
                ;;
            -l|--logic)
                SHOW_LOGIC=true
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    SPECIFIC_SUBMISSION="$2"
                    shift
                fi
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    parse_args "$@"

    # Handle informational flags
    if $SHOW_CRITERIA; then
        show_criteria "${SPECIFIC_SUBMISSION:-all}"
        exit 0
    fi

    if $SHOW_LOGIC; then
        show_logic "${SPECIFIC_SUBMISSION:-all}"
        exit 0
    fi

    # Validate year
    if ! [[ "$YEAR" =~ ^[0-9]{4}$ ]]; then
        echo "ERROR: Invalid year format: $YEAR"
        exit 1
    fi

    echo "========================================"
    echo "Course Submission Evaluation"
    echo "Year: $YEAR"
    echo "========================================"
    echo ""

    # Check for yt-dlp (needed for video metadata checks)
    if ! command -v yt-dlp &>/dev/null; then
        echo -e "${YELLOW}NOTE: yt-dlp not found. Video checks (duration, resolution, subtitles) will be skipped.${NC}"
        echo "      Install yt-dlp for full video evaluation:"
        echo "        macOS:  brew install yt-dlp"
        echo "        Linux:  pip install yt-dlp  OR  sudo apt install yt-dlp"
        echo ""
    fi

    # Check for exiftool or pdfinfo (needed for PDF page count)
    if ! command -v exiftool &>/dev/null && ! command -v pdfinfo &>/dev/null; then
        echo -e "${YELLOW}NOTE: exiftool/pdfinfo not found. PDF page count check will be skipped.${NC}"
        echo "      Install exiftool for PDF page validation:"
        echo "        macOS:  brew install exiftool"
        echo "        Linux:  sudo apt install libimage-exiftool-perl  OR  sudo apt install poppler-utils (for pdfinfo)"
        echo ""
    fi

    # Handle specific submission evaluation
    if [[ -n "$SPECIFIC_SUBMISSION" ]]; then
        # Validate submission type
        local valid=false
        for sub in "${INDIVIDUAL_SUBMISSIONS[@]}" "${GROUP_SUBMISSIONS[@]}"; do
            [[ "$sub" == "$SPECIFIC_SUBMISSION" ]] && valid=true
        done

        if ! $valid; then
            echo "ERROR: Unknown submission type: $SPECIFIC_SUBMISSION"
            echo "Valid types: ${INDIVIDUAL_SUBMISSIONS[*]} ${GROUP_SUBMISSIONS[*]}"
            exit 1
        fi

        evaluate_single_submission "$SPECIFIC_SUBMISSION" "$YEAR"
        exit 0
    fi

    # Normal evaluation - generate CSVs
    if ! $INDIVIDUAL_ONLY; then
        evaluate_group_submissions "$YEAR"
    fi

    if ! $GROUP_ONLY; then
        evaluate_individual_submissions "$YEAR"
    fi

    echo ""
    echo "========================================"
    echo "Evaluation complete!"
    echo "========================================"
}

main "$@"
