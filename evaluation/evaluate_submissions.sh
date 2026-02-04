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
VERBOSE=false
COOKIES_FROM_BROWSER=""

# Video metadata cache settings
VIDEO_CACHE_DIR="${SCRIPT_DIR}/.video_cache"
VIDEO_CACHE_MAX_AGE_DAYS=30

# Partial credit scoring globals
CRITERION_SCORE_PCT=100
AUTHOR_SCORE_PENALTIES=""
SINGULAR_PLURAL_DETAIL=""

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
    echo "    -v, --verbose         Show detailed check-by-check output for each file"
    echo "    --cookies-from-browser BROWSER"
    echo "                          Use cookies from browser for yt-dlp (e.g., firefox, chrome)"
    echo "                          Speeds up YouTube checks significantly"
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

# ============================================================================
# NAME EXTRACTION AND VALIDATION
# ============================================================================
#
# FILENAME FORMAT RULES:
# - Individual: YYYY-FamilyName-FirstName.ext (exactly 2 name parts)
# - Group: YYYY-FamilyName1-FamilyName2-FamilyName3.ext (2-4 family names)
#
# VALIDATION RULES:
# 1. Names must start with uppercase letter
# 2. Names must contain only ASCII letters
# 3. Group names must be in alphabetical order
# 4. Filenames must NOT include submission type suffixes (tests, reflection, etc.)
#
# Known submission type suffixes to filter out (case-insensitive):
# These are tags that should NOT be treated as names
KNOWN_SUFFIXES=("data" "code" "tests" "test" "reflection" "video" "slides" "slide" "Figures" "figure" "Figure" "report" "system" "design" "brief" "case" "project" "group" "individual")

# Allowed suffixes for group folder names (only these are valid)
ALLOWED_FOLDER_SUFFIXES=("data" "code")

# Calculate Levenshtein distance between two strings
# Returns: distance as integer
levenshtein_distance() {
    local s1="$1"
    local s2="$2"
    local len1=${#s1}
    local len2=${#s2}

    # Quick checks
    [[ "$s1" == "$s2" ]] && echo 0 && return
    [[ $len1 -eq 0 ]] && echo $len2 && return
    [[ $len2 -eq 0 ]] && echo $len1 && return

    # For efficiency, only compute if lengths differ by at most 1
    local len_diff=$((len1 > len2 ? len1 - len2 : len2 - len1))
    if [[ $len_diff -gt 1 ]]; then
        echo $len_diff
        return
    fi

    # Simple character-by-character comparison for short strings
    local i diff=0
    local c1 c2
    local max_len=$((len1 > len2 ? len1 : len2))
    for ((i=0; i<max_len; i++)); do
        c1="${s1:$i:1}"
        c2="${s2:$i:1}"
        if [[ "$c1" != "$c2" ]]; then
            diff=$((diff + 1))
        fi
    done
    echo $diff
}

# Check if a word is a known tag (exact or fuzzy match with 1 char tolerance)
# Returns: 0 if matches a tag, 1 if not a tag
# Sets global TAG_MATCH to the matched tag name (for reporting)
TAG_MATCH=""
is_known_tag() {
    local word="$1"
    local word_lower="${(L)word}"  # lowercase

    TAG_MATCH=""

    local tag
    for tag in "${KNOWN_SUFFIXES[@]}"; do
        local tag_lower="${(L)tag}"

        # Exact match
        if [[ "$word_lower" == "$tag_lower" ]]; then
            TAG_MATCH="$tag"
            return 0
        fi

        # Fuzzy match (1 character difference)
        local dist=$(levenshtein_distance "$word_lower" "$tag_lower")
        if [[ $dist -eq 1 ]]; then
            TAG_MATCH="$tag (fuzzy match from '$word')"
            return 0
        fi
    done

    return 1
}

# Check if a suffix is allowed for folder names
# Only -data and -code are allowed
is_allowed_folder_suffix() {
    local suffix="$1"
    local suffix_lower="${(L)suffix}"

    local allowed
    for allowed in "${ALLOWED_FOLDER_SUFFIXES[@]}"; do
        [[ "$suffix_lower" == "${(L)allowed}" ]] && return 0
    done
    return 1
}

# Remove known submission type suffixes from a name string
# This prevents "Khan-Liu-Peng-tests" from being parsed as 4 names
# Loops until no more suffixes can be stripped (handles "Khan-Liu-Peng-system-design")
strip_submission_suffixes() {
    local name="$1"
    local prev_name=""
    local suffix

    # Keep stripping suffixes until no more changes
    while [[ "$name" != "$prev_name" ]]; do
        prev_name="$name"
        for suffix in "${KNOWN_SUFFIXES[@]}"; do
            # Remove suffix with dash prefix (case insensitive)
            name="${name%-${suffix}}"
            name="${name%-${(L)suffix}}"  # lowercase version
            name="${name%-${(C)suffix}}"  # capitalized version
        done
    done
    echo "$name"
}

# Check if a string looks like a valid name (capitalized, ASCII only)
is_valid_name() {
    local name="$1"
    # Must start with uppercase, followed by lowercase letters only
    [[ "$name" =~ ^[A-Z][a-z]+$ ]]
}

# Check if names are in alphabetical order
are_names_alphabetical() {
    local names="$1"  # Space-separated names
    local -a name_array
    name_array=(${(s: :)names})

    local i prev_name curr_name
    prev_name=""
    for curr_name in "${name_array[@]}"; do
        if [[ -n "$prev_name" ]]; then
            # Compare case-insensitively
            if [[ "${(L)curr_name}" < "${(L)prev_name}" ]]; then
                return 1
            fi
        fi
        prev_name="$curr_name"
    done
    return 0
}

# Extract family names from filename
# Format: YYYY-FamilyName1-FamilyName2-FamilyName3.ext -> FamilyName1 FamilyName2 FamilyName3
# Returns: space-separated family names (cleaned of submission type suffixes)
extract_family_names() {
    local filename="$1"
    local basename="${filename%.*}"  # Remove extension

    # Remove year prefix (YYYY-)
    local names="${basename#*-}"

    # Strip known submission type suffixes
    names=$(strip_submission_suffixes "$names")

    # For individual files (YYYY-FamilyName-FirstName), take only family name
    if [[ "$names" =~ ^([A-Za-z]+)-([A-Za-z]+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        # For group files, extract all family names (alphabetical list)
        # Convert dashes to spaces
        echo "$names" | tr '-' ' '
    fi
}

# Extract potential family names from a full name string
# Handles formats:
#   - "2026-Chen-KunYu" → "Chen KunYu" (strip year, both parts are candidates)
#   - "Wei JungYing" → "Wei JungYing" (both are candidates)
#   - "Liu TzuEn Andrew" → "Liu Andrew" (first and last)
# Returns: space-separated potential family names (first and last parts)
extract_potential_family_names() {
    local full_name="$1"

    # Handle YYYY-Name-Name format
    if [[ "$full_name" =~ ^[0-9]{2,4}[-_] ]]; then
        # Strip year prefix (YYYY- or YY-)
        full_name="${full_name#*-}"
        # Strip submission suffixes
        full_name=$(strip_submission_suffixes "$full_name")
        # Convert dashes to spaces
        full_name="${full_name//-/ }"
    fi

    local -a words
    # Split on whitespace
    words=(${(s: :)full_name})
    local count=${#words[@]}

    if [[ $count -eq 0 ]]; then
        echo ""
    elif [[ $count -eq 1 ]]; then
        echo "${words[1]}"
    elif [[ $count -eq 2 ]]; then
        # Both could be family name
        echo "${words[1]} ${words[2]}"
    else
        # First and last are potential family names
        echo "${words[1]} ${words[$count]}"
    fi
}

# Parse author line to extract individual author names
# Handles formats:
#   - "2026-Fan-Cheng-Yu" → "Fan Cheng Yu"
#   - "Fan ChengYu, Lee PoLin" → ["Fan ChengYu", "Lee PoLin"]
#   - "Chen, Lin, Wang" → ["Chen", "Lin", "Wang"]
#   - "Wei JungYing, Wu KunChe" → ["Wei JungYing", "Wu KunChe"]
# Returns: newline-separated list of author names
parse_author_names() {
    local author_line="$1"

    # Remove markdown formatting
    author_line=$(echo "$author_line" | sed 's/\*//g' | sed 's/#//g')

    # Check if it's a YYYY-Name-Name format
    if [[ "$author_line" =~ ^[0-9]{4}-[A-Za-z] ]]; then
        # Strip year prefix and convert dashes to spaces
        local names="${author_line#*-}"
        names=$(strip_submission_suffixes "$names")
        echo "$names" | tr '-' ' '
        return
    fi

    # Split by comma to get individual authors
    local -a authors_raw
    # Use parameter expansion to split on comma
    authors_raw=(${(s:,:)author_line})

    local author
    for author in "${authors_raw[@]}"; do
        # Trim whitespace
        author=$(echo "$author" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -n "$author" ]] && echo "$author"
    done
}

# Extract author names from file content
# Looks for common patterns within first 15 lines:
#   - "Author:", "Authors:"
#   - "Group:", "Group members:"
#   - "Team:", "Team members:"
# Returns: newline-separated list of author full names found in content
extract_authors_from_content() {
    local filepath="$1"
    local content_file="$filepath"

    # For folders (data, project-code), look in README.md
    if [[ -d "$filepath" ]]; then
        content_file="$filepath/README.md"
    fi

    if [[ ! -f "$content_file" ]]; then
        echo ""
        return
    fi

    # Read first 15 lines for author information
    local first_lines
    first_lines=$(head -15 "$content_file" 2>/dev/null || true)

    # Try multiple patterns to find authors
    # IMPORTANT: Patterns must require a colon to avoid matching titles like "Group Tests"
    local author_line=""

    # Pattern 1: "Author:" or "Authors:" (with optional ** markdown)
    # Must have colon after the keyword
    author_line=$(echo "$first_lines" | grep -iE "^[*#[:space:]]*authors?[*]*[[:space:]]*:" | head -1 | sed 's/^[^:]*://' || true)

    # Pattern 2: "Group:" or "Group members:" (must have colon)
    if [[ -z "$author_line" ]]; then
        author_line=$(echo "$first_lines" | grep -iE "^[*#[:space:]]*(group|group members?)[*]*[[:space:]]*:" | head -1 | sed 's/^[^:]*://' || true)
    fi

    # Pattern 3: "Team:" or "Team members:" (must have colon)
    if [[ -z "$author_line" ]]; then
        author_line=$(echo "$first_lines" | grep -iE "^[*#[:space:]]*(team|team members?)[*]*[[:space:]]*:" | head -1 | sed 's/^[^:]*://' || true)
    fi

    if [[ -z "$author_line" ]]; then
        echo ""
        return
    fi

    # Truncate to first 100 characters
    author_line="${author_line:0:100}"

    # Parse the author names
    parse_author_names "$author_line"
}

# Normalize a name string to canonical form for comparison
# Normalize student name for duplicate detection
# Removes ALL separators and spaces, lowercases for comparison
# "Fan Cheng-Yu" → "fanchengyu"
# "Fan ChengYu" → "fanchengyu"
# This allows detecting same student with different name spellings
normalize_student_key() {
    local name="$1"
    # Remove year prefix if present
    if [[ "$name" =~ ^[0-9]{2,4}[-_] ]]; then
        name="${name#*[-_]}"
    fi
    # Strip known submission suffixes
    name=$(strip_submission_suffixes "$name")
    # Remove ALL separators (dashes, spaces, commas, etc.) and lowercase
    name=$(echo "$name" | sed 's/[-_ ,;:]//g' | tr '[:upper:]' '[:lower:]')
    echo "$name"
}

# Strips year prefix, converts separators to spaces, lowercases
# "2026-Fan-Cheng-Yu" → "fan cheng yu"
# "Fan ChengYu" → "fan chengyu"
normalize_name_string() {
    local name="$1"

    # Remove markdown/special characters FIRST (before year stripping)
    name=$(echo "$name" | sed 's/[*#`()"]//g')

    # Strip year prefix (YYYY- or YY-)
    if [[ "$name" =~ ^[0-9]{2,4}[-_] ]]; then
        name="${name#*[-_]}"
    fi

    # Strip known submission suffixes
    name=$(strip_submission_suffixes "$name")

    # Convert common separators to spaces (use sed for clarity)
    name=$(echo "$name" | sed 's/[-_,;:]/ /g')

    # Collapse multiple spaces, trim, lowercase
    name=$(echo "$name" | tr -s ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')

    echo "$name"
}

# ============================================================================
# PARTIAL CREDIT SCORING FOR AUTHOR CHECKS
# ============================================================================

# Check if any name in the author line has year-prefix format (e.g., 2026-Chen-KunYu)
# This is the only format we penalize as it's clearly a filename format, not a name
# Returns: 0 if year-prefix found (bad), 1 if no year-prefix (good)
has_year_prefix_format() {
    local author_line="$1"
    # Matches: 2026-Chen-KunYu, 2026-Lin-Chih-Yi, etc.
    echo "$author_line" | grep -qE '(^|[,;[:space:]])20[0-9]{2}-[A-Za-z]'
}

# Count the number of authors in an author line
# Handles comma-separated, semicolon-separated, and "and" separated names
# Returns: integer count
count_authors_in_line() {
    local author_line="$1"

    # Remove markdown formatting
    author_line=$(echo "$author_line" | sed 's/[*#`]//g')

    # Replace " and " with comma, semicolons with comma for uniform counting
    author_line=$(echo "$author_line" | sed 's/ and /,/gi' | tr ';' ',')

    # Count entries by counting commas + 1 (if there's content)
    # First check if there's any content at all
    if ! echo "$author_line" | grep -q '[A-Za-z]'; then
        echo "0"
        return
    fi

    # Count commas and add 1
    local comma_count
    comma_count=$(echo "$author_line" | tr -cd ',' | wc -c | tr -d ' ')
    local count=$((comma_count + 1))

    echo "$count"
}

# Check if Author/Authors keyword matches the number of authors
# Returns: 0 if correct, 1 if mismatch
# Also sets SINGULAR_PLURAL_DETAIL with explanation
check_singular_plural_match() {
    local filepath="$1"
    local author_count="$2"

    # Read first 20 lines to find author line
    local first_lines
    first_lines=$(head -20 "$filepath" 2>/dev/null)

    # Check for "Authors:" (plural with 's') - must have 's' before colon
    local has_plural=false
    local has_singular=false

    if echo "$first_lines" | grep -qiE '^[*#[:space:]]*authors[*]*[[:space:]]*:'; then
        has_plural=true
    fi

    # Check for "Author:" (singular) - must NOT have 's' before colon
    # Use word boundary to distinguish Author: from Authors:
    if echo "$first_lines" | grep -qiE '^[*#[:space:]]*author[*]*[[:space:]]*:' && \
       ! echo "$first_lines" | grep -qiE '^[*#[:space:]]*authors[*]*[[:space:]]*:'; then
        has_singular=true
    fi

    # Determine if there's a mismatch
    if [[ $author_count -ge 2 ]] && $has_singular && ! $has_plural; then
        SINGULAR_PLURAL_DETAIL="uses 'Author:' for $author_count authors"
        return 1
    fi

    if [[ $author_count -eq 1 ]] && $has_plural; then
        SINGULAR_PLURAL_DETAIL="uses 'Authors:' for 1 author"
        return 1
    fi

    SINGULAR_PLURAL_DETAIL=""
    return 0
}

# Calculate partial credit score for author-related criteria
# Returns: "score|penalties" string (e.g., "50|singular/plural mismatch; ")
# Arguments: filepath, is_group (true/false)
calculate_author_score() {
    local filepath="$1"
    local is_group="$2"

    local score=100
    local penalties=""

    # Get author line content
    local author_line
    author_line=$(extract_authors_from_content "$filepath" | tr '\n' ',' | sed 's/,$//')

    if [[ -z "$author_line" ]]; then
        echo "0|no author info found"
        return
    fi

    # Count authors
    local author_count
    author_count=$(count_authors_in_line "$author_line")

    # Check 1: Singular/plural mismatch
    if ! check_singular_plural_match "$filepath" "$author_count"; then
        score=$((score / 2))
        penalties="${penalties}${SINGULAR_PLURAL_DETAIL}; "
    fi

    # Check 2: Year-prefix format (e.g., 2026-Chen-KunYu)
    if has_year_prefix_format "$author_line"; then
        score=$((score / 2))
        penalties="${penalties}year-prefix format (e.g. 2026-Name); "
    fi

    # Return score and penalties separated by |
    echo "${score}|${penalties}"
}

# Extract all potential family names from content authors
# Returns: space-separated list of all potential family names (lowercase for comparison)
get_content_family_names() {
    local filepath="$1"
    local content_authors
    local -a family_names
    local -a author_lines
    local author potential name

    # Get all authors from content (newline-separated)
    content_authors=$(extract_authors_from_content "$filepath")

    if [[ -z "$content_authors" ]]; then
        echo ""
        return
    fi

    # For each author, extract potential family names
    # Use zsh array splitting instead of here document
    author_lines=(${(f)content_authors})

    for author in "${author_lines[@]}"; do
        [[ -z "$author" ]] && continue
        potential=$(extract_potential_family_names "$author")
        for name in ${(s: :)potential}; do
            family_names+=("${(L)name}")  # lowercase for comparison
        done
    done

    # Return unique family names
    echo "${family_names[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

# Compare filename names with content authors
# Returns: "match", "mismatch", or "no_content"
compare_filename_to_content() {
    local filepath="$1"
    local filename_names="$2"  # Space-separated names from filename

    # Get content authors
    local content_authors
    content_authors=$(extract_authors_from_content "$filepath")

    if [[ -z "$content_authors" ]]; then
        echo "no_content"
        return
    fi

    # Normalize filename names
    local filename_normalized
    filename_normalized=$(normalize_name_string "$filename_names")

    # Check each content author line for a match
    local -a author_lines
    author_lines=(${(f)content_authors})

    local author content_normalized
    for author in "${author_lines[@]}"; do
        [[ -z "$author" ]] && continue
        content_normalized=$(normalize_name_string "$author")

        # Direct match after normalization
        if [[ "$filename_normalized" == "$content_normalized" ]]; then
            echo "match"
            return
        fi
    done

    # If single content author that normalizes to match filename, it's a match
    if [[ ${#author_lines[@]} -eq 1 ]]; then
        # Already checked above, so no match
        echo "mismatch"
        return
    fi

    # For multiple authors, check if all filename names appear in combined content
    # This handles group submissions where content has multiple author lines
    local all_content_names=""
    for author in "${author_lines[@]}"; do
        [[ -z "$author" ]] && continue
        all_content_names="$all_content_names $(normalize_name_string "$author")"
    done

    # Check if all filename name parts appear in content
    local -a filename_parts
    filename_parts=(${(s: :)filename_normalized})
    local all_found=true
    local part
    for part in "${filename_parts[@]}"; do
        if ! echo " $all_content_names " | grep -qi " $part "; then
            all_found=false
            break
        fi
    done

    if $all_found; then
        echo "match"
    else
        echo "mismatch"
    fi
}

# Validate group name format and check for discrepancies
# Outputs warnings to terminal if issues found
validate_group_names() {
    local filepath="$1"
    local filename_names="$2"  # Space-separated names from filename
    local submission_type="$3"

    local -a name_array
    name_array=(${(s: :)filename_names})
    local name_count=${#name_array[@]}
    local warnings=""

    # Check 1: Validate each name looks like a proper name (capitalized)
    # Skip warnings for known tags (system, design, slides, etc.)
    local name
    for name in "${name_array[@]}"; do
        if ! is_valid_name "$name"; then
            # Skip warning if it's a known tag
            if ! is_known_tag "$name"; then
                warnings="${warnings}    WARNING: '$name' doesn't look like a valid name (should be capitalized)\n"
            fi
        fi
    done

    # Check 2: Verify names are in alphabetical order (heuristic - needs content verification)
    # Filter out known tags before checking alphabetical order
    local names_without_tags=""
    for name in "${name_array[@]}"; do
        if ! is_known_tag "$name"; then
            [[ -n "$names_without_tags" ]] && names_without_tags="$names_without_tags "
            names_without_tags="$names_without_tags$name"
        fi
    done
    local not_alphabetical=false
    if [[ -n "$names_without_tags" ]] && ! are_names_alphabetical "$names_without_tags"; then
        not_alphabetical=true
    fi

    # Check 3: Detect if this looks like an individual misplaced in group folder
    # Individual format: FamilyName FirstName [MiddleName/EnglishName] (1 family + 1-2 given names)
    # Group format: FamilyName1 FamilyName2 [FamilyName3] (2-4 family names, alphabetically sorted)
    #
    # Detection heuristics for individuals:
    # - 2 names: second name has mixed case (TzuEn) or is short (≤4 chars)
    # - 3 names: middle name has mixed case (indicates FirstName MiddleName pattern)
    local looks_like_individual=false

    if [[ $name_count -eq 2 ]]; then
        local second_name="${name_array[2]}"
        if [[ "$second_name" =~ [a-z][A-Z] ]] || [[ ${#second_name} -le 4 ]]; then
            looks_like_individual=true
        fi
    elif [[ $name_count -eq 3 ]]; then
        local second_name="${name_array[2]}"
        if [[ "$second_name" =~ [a-z][A-Z] ]]; then
            looks_like_individual=true
        fi
    fi

    # Check 4: Compare filename names with content authors
    local comparison_result
    comparison_result=$(compare_filename_to_content "$filepath" "$filename_names")

    local verified_by_content=false
    local content_mismatch=false

    case "$comparison_result" in
        match)
            verified_by_content=true
            # Content confirms, clear individual suspicion for groups
            local content_authors
            content_authors=$(extract_authors_from_content "$filepath")
            local content_author_count=0
            local -a content_lines
            content_lines=(${(f)content_authors})
            for line in "${content_lines[@]}"; do
                [[ -n "$line" ]] && content_author_count=$((content_author_count + 1))
            done
            if [[ $content_author_count -ge 2 ]]; then
                looks_like_individual=false
            fi
            ;;
        mismatch)
            content_mismatch=true
            ;;
        no_content)
            # No author info in content, rely on heuristics only
            ;;
    esac

    # Output warnings based on verification results
    if $content_mismatch; then
        local content_authors_display
        content_authors_display=$(extract_authors_from_content "$filepath" | tr '\n' ',' | sed 's/,$//')
        warnings="${warnings}    WARNING: Filename names ($filename_names) don't match authors in content ($content_authors_display)\n"
    fi

    if $looks_like_individual; then
        if $verified_by_content; then
            # Content confirmed it's actually a group despite heuristics
            : # No warning
        else
            warnings="${warnings}    WARNING: '$filename_names' appears to be an INDIVIDUAL name, not a group (misplaced in group folder?)\n"
        fi
    fi

    if $not_alphabetical && ! $verified_by_content; then
        warnings="${warnings}    WARNING: Names not in alphabetical order: $names_without_tags\n"
    fi

    # Output warnings if any
    if [[ -n "$warnings" ]]; then
        echo -e "$warnings"
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
# Files should NOT have any tag suffixes (unlike folders which allow -data/-code)
check_group_filename_format() {
    local filepath="$1"
    local year="$2"
    local filename=$(basename "$filepath")
    local basename="${filename%.*}"  # Remove extension

    # First check basic pattern
    if ! [[ "$filename" =~ ^${year}-[A-Za-z]+-[A-Za-z]+(-[A-Za-z]+)*\.[a-z]+$ ]]; then
        return 1
    fi

    # Extract parts after year (Name1-Name2-Name3...)
    local names_part="${basename#${year}-}"
    local -a parts
    parts=(${(s:-:)names_part})

    # Check each part - if any is a known tag, fail
    local part
    for part in "${parts[@]}"; do
        if is_known_tag "$part"; then
            [[ "$VERBOSE" == "true" ]] && echo -n -e "${YELLOW}(contains tag: $TAG_MATCH) ${NC}" >&2
            return 1
        fi
    done

    # Now check proper capitalization (all names should be Capitalized)
    if [[ "$filename" =~ ^${year}-[A-Z][a-zA-Z]+-[A-Z][a-zA-Z]+(-[A-Z][a-zA-Z]+)*\.[a-z]+$ ]]; then
        return 0
    fi
    return 1
}

# Check if folder has correct group folder format
# Pattern: YYYY-Name1-Name2[-Name3...][-data|-code] (at least 2 family names)
# Only -data and -code suffixes are allowed; other tags like -slides, -system-design are NOT allowed
check_group_folder_format() {
    local folderpath="$1"
    local year="$2"
    local foldername=$(basename "$folderpath")

    # First check basic pattern
    if ! [[ "$foldername" =~ ^${year}-[A-Za-z]+-[A-Za-z]+(-[A-Za-z]+)*$ ]]; then
        return 1
    fi

    # Extract parts after year (Name1-Name2-Name3[-suffix])
    local names_part="${foldername#${year}-}"
    local -a parts
    parts=(${(s:-:)names_part})

    # Check each part - if any is a known tag, it must be an allowed suffix at the end
    local i part
    local num_parts=${#parts[@]}
    local found_disallowed_tag=""

    for ((i=1; i<=num_parts; i++)); do
        part="${parts[$i]}"
        if is_known_tag "$part"; then
            # It's a tag - check if it's allowed and at the end
            if [[ $i -eq $num_parts ]]; then
                # Last part - check if it's an allowed suffix
                if ! is_allowed_folder_suffix "$part"; then
                    found_disallowed_tag="$TAG_MATCH"
                fi
            else
                # Tag in the middle - not allowed
                found_disallowed_tag="$TAG_MATCH"
            fi
        fi
    done

    if [[ -n "$found_disallowed_tag" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo -n -e "${YELLOW}(contains disallowed tag: $found_disallowed_tag) ${NC}" >&2
        return 1
    fi

    # Now check proper capitalization (all name parts should be Capitalized, allowed suffixes are lowercase)
    # Allow last part to be lowercase if it's an allowed suffix
    local last_part="${parts[$num_parts]}"
    if is_allowed_folder_suffix "$last_part"; then
        # Remove last part for capitalization check
        local names_without_suffix="${names_part%-${last_part}}"
        if [[ "$names_without_suffix" =~ ^[A-Z][a-zA-Z]+(-[A-Z][a-zA-Z]+)*$ ]]; then
            return 0
        fi
    else
        # No suffix - all parts must be capitalized names
        if [[ "$names_part" =~ ^[A-Z][a-zA-Z]+(-[A-Z][a-zA-Z]+)*$ ]]; then
            return 0
        fi
    fi

    return 1
}

# Find the main file inside a folder submission
# For system-design: looks for .drawio file
# For slides: looks for .tex file
# Returns: path to main file, or empty if not found
find_main_file_in_folder() {
    local folderpath="$1"
    local submission_type="$2"

    [[ ! -d "$folderpath" ]] && echo "" && return

    case "$submission_type" in
        system-design)
            # Find .drawio file in folder
            find "$folderpath" -maxdepth 1 -name "*.drawio" -type f 2>/dev/null | head -1
            ;;
        slides)
            # Find .tex file in folder (prefer main.tex if exists)
            if [[ -f "$folderpath/main.tex" ]]; then
                echo "$folderpath/main.tex"
            else
                find "$folderpath" -maxdepth 1 -name "*.tex" -type f 2>/dev/null | head -1
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get the effective file path for evaluation
# If submission is a folder, returns the main file inside; otherwise returns the path as-is
get_effective_filepath() {
    local filepath="$1"
    local submission_type="$2"

    if [[ -d "$filepath" ]]; then
        find_main_file_in_folder "$filepath" "$submission_type"
    else
        echo "$filepath"
    fi
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

# Run a command with timeout (default 5 seconds)
# Returns the command output, or empty if timed out
# Sets TIMEOUT_OCCURRED=1 if timeout happened
# Temp directory for script artifacts (includes PID to avoid conflicts)
EVAL_TMP_DIR="${TMPDIR:-/tmp}/evaluate_submissions_$$"
TIMEOUT_STDERR_FILE="${EVAL_TMP_DIR}/cmd_stderr_eval"

# Cleanup function - removes temp dir on successful exit
cleanup_tmp() {
    if [[ -d "$EVAL_TMP_DIR" ]]; then
        rm -rf "$EVAL_TMP_DIR"
    fi
}

# Sets TIMEOUT_OCCURRED=1 if command timed out
# Writes stderr to $TIMEOUT_STDERR_FILE for reading after call
run_with_timeout() {
    local timeout_secs="${1:-5}"
    shift
    local cmd="$*"

    mkdir -p "$EVAL_TMP_DIR" 2>/dev/null || true
    : > "$TIMEOUT_STDERR_FILE" 2>/dev/null || true  # Clear the stderr file

    local exit_code
    local output

    # Use timeout command if available (GNU coreutils), otherwise use perl
    if command -v timeout &>/dev/null; then
        output=$(timeout "$timeout_secs" sh -c "$cmd" 2>"$TIMEOUT_STDERR_FILE")
        exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            echo "TIMEOUT"
            return 124
        fi
    elif command -v gtimeout &>/dev/null; then
        # macOS with coreutils installed via brew
        output=$(gtimeout "$timeout_secs" sh -c "$cmd" 2>"$TIMEOUT_STDERR_FILE")
        exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            echo "TIMEOUT"
            return 124
        fi
    else
        # Fallback: use perl for timeout on macOS
        output=$(perl -e '
            use strict;
            use warnings;
            $SIG{ALRM} = sub { exit 124 };
            alarm(shift);
            exec(@ARGV) or exit 1;
        ' "$timeout_secs" sh -c "$cmd" 2>"$TIMEOUT_STDERR_FILE")
        exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            echo "TIMEOUT"
            return 124
        fi
    fi

    echo "$output"
    return $exit_code
}

# Helper to get last command's stderr (call after run_with_timeout)
get_last_stderr() {
    cat "$TIMEOUT_STDERR_FILE" 2>/dev/null
}

# ============================================================================
# VIDEO METADATA CACHE
# ============================================================================

# Check if bgutil-ytdlp-pot-provider is available (pip package OR Docker container)
# Returns 0 if available, 1 if not
is_bgutil_pot_provider_available() {
    # Check 1: Python package installed
    if python3 -c "import bgutil_ytdlp_pot_provider" 2>/dev/null; then
        return 0
    fi
    # Check 2: Docker HTTP server running on port 4416
    if curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 http://127.0.0.1:4416/ 2>/dev/null | grep -q "200\|404"; then
        return 0
    fi
    return 1
}

# Extract YouTube video ID from URL
get_youtube_video_id() {
    local url="$1"
    # Handle youtu.be/ID and youtube.com/watch?v=ID formats
    if echo "$url" | grep -qE "youtu\.be/"; then
        echo "$url" | sed -E 's|.*youtu\.be/([a-zA-Z0-9_-]+).*|\1|'
    elif echo "$url" | grep -qE "youtube\.com/watch"; then
        echo "$url" | sed -E 's|.*[?&]v=([a-zA-Z0-9_-]+).*|\1|'
    else
        echo ""
    fi
}

# Get cache file path for a video ID
get_video_cache_path() {
    local video_id="$1"
    echo "${VIDEO_CACHE_DIR}/${video_id}.json"
}

# Check if cache is valid (exists and less than VIDEO_CACHE_MAX_AGE_DAYS old)
is_cache_valid() {
    local cache_file="$1"
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi

    # Check file age
    local file_age_days
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: use stat with -f %m for modification time
        local file_mtime=$(stat -f %m "$cache_file" 2>/dev/null)
        local current_time=$(date +%s)
        file_age_days=$(( (current_time - file_mtime) / 86400 ))
    else
        # Linux: use stat with -c %Y
        local file_mtime=$(stat -c %Y "$cache_file" 2>/dev/null)
        local current_time=$(date +%s)
        file_age_days=$(( (current_time - file_mtime) / 86400 ))
    fi

    [[ $file_age_days -lt $VIDEO_CACHE_MAX_AGE_DAYS ]]
}

# Track videos that failed to fetch in this run (to avoid retrying)
declare -A FAILED_VIDEO_FETCHES

# Fetch and cache video metadata using yt-dlp (single request for all data)
fetch_video_metadata() {
    local url="$1"
    local video_id=$(get_youtube_video_id "$url")

    if [[ -z "$video_id" ]]; then
        return 1
    fi

    # Check if we already failed to fetch this video in this run
    if [[ -n "${FAILED_VIDEO_FETCHES[$video_id]:-}" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo -n -e "${YELLOW}(skip-failed) ${NC}" >&2
        return 1
    fi

    local cache_file=$(get_video_cache_path "$video_id")

    # Check if we have valid cached data
    if is_cache_valid "$cache_file"; then
        [[ "$VERBOSE" == "true" ]] && echo -n -e "${GREEN}(cached) ${NC}" >&2
        return 0
    fi

    # Create cache directory if needed
    mkdir -p "$VIDEO_CACHE_DIR"

    # Build yt-dlp command with optional cookies - use native JSON output
    local yt_dlp_cmd="yt-dlp --skip-download --no-warnings --dump-json"
    if [[ -n "$COOKIES_FROM_BROWSER" ]]; then
        yt_dlp_cmd="$yt_dlp_cmd --cookies-from-browser $COOKIES_FROM_BROWSER"
    fi
    yt_dlp_cmd="$yt_dlp_cmd '$url'"

    LAST_CMD="$yt_dlp_cmd"
    local result
    result=$(run_with_timeout 60 "$yt_dlp_cmd")

    if [[ "$result" == "TIMEOUT" ]]; then
        # Mark as failed so we don't retry
        FAILED_VIDEO_FETCHES[$video_id]=1
        if [[ "$VERBOSE" == "true" ]]; then
            echo -n -e "${YELLOW}WARNING: yt-dlp timed out (60s) fetching video metadata${NC}" >&2
            echo -e "        ${YELLOW}Command: $LAST_CMD${NC}" >&2
            if ! is_bgutil_pot_provider_available; then
                echo -e "        ${YELLOW}TIP: Start PO token provider: docker start bgutil-provider${NC}" >&2
            fi
            if [[ -z "$COOKIES_FROM_BROWSER" ]]; then
                echo -e "        ${YELLOW}TIP: Use browser cookies: --cookies-from-browser firefox${NC}" >&2
            fi
        fi
        return 1
    fi

    if [[ -z "$result" ]]; then
        # Mark as failed so we don't retry
        FAILED_VIDEO_FETCHES[$video_id]=1
        if [[ "$VERBOSE" == "true" ]]; then
            echo -n -e "${YELLOW}Failed to fetch video metadata${NC}" >&2
            echo -e "        ${YELLOW}Command: $LAST_CMD${NC}" >&2
            local stderr_out=$(get_last_stderr)
            [[ -n "$stderr_out" ]] && echo -e "        ${YELLOW}Error: $stderr_out${NC}" >&2
        fi
        return 1
    fi

    # Save to cache
    echo "$result" > "$cache_file"
    [[ "$VERBOSE" == "true" ]] && echo -n -e "${GREEN}(fetched) ${NC}" >&2
    return 0
}

# Get a specific field from cached video metadata
get_cached_video_field() {
    local url="$1"
    local field="$2"
    local video_id=$(get_youtube_video_id "$url")

    if [[ -z "$video_id" ]]; then
        echo ""
        return 1
    fi

    local cache_file=$(get_video_cache_path "$video_id")

    if [[ ! -f "$cache_file" ]]; then
        echo ""
        return 1
    fi

    # Extract field from cached JSON using jq
    local value
    value=$(jq -r ".$field // empty" "$cache_file" 2>/dev/null)
    echo "$value"
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
            # For system-design and slides: FAIL if submission is a folder instead of a file
            if [[ "$submission_type" == "system-design" || "$submission_type" == "slides" ]]; then
                if [[ -d "$filepath" ]]; then
                    local foldername=$(basename "$filepath")
                    local msg="folder submitted, expected file"
                    # Also check for disallowed tags in folder name
                    local names_part="${foldername#${year}-}"
                    local -a parts
                    parts=(${(s:-:)names_part})
                    local part found_tags=""
                    for part in "${parts[@]}"; do
                        if is_known_tag "$part"; then
                            if ! is_allowed_folder_suffix "$part"; then
                                [[ -n "$found_tags" ]] && found_tags="$found_tags, "
                                found_tags="${found_tags}${TAG_MATCH}"
                            fi
                        fi
                    done
                    if [[ -n "$found_tags" ]]; then
                        msg="$msg; disallowed tags: $found_tags"
                    fi
                    [[ "$VERBOSE" == "true" ]] && echo -n -e "${YELLOW}($msg) ${NC}" >&2
                    return 1
                fi
            fi
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
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            local ext="${check_path##*.}"
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
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "license\|License\|LICENSE\|CC-BY\|Apache\|SPDX" && return 0
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
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "architecture\|Architecture" && return 0
            return 1
            ;;
        has_implementation)
            content_contains "$filepath" "implementation\|Implementation" && return 0
            return 1
            ;;
        has_results)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "result\|Result\|demo\|Demo\|demonstration\|Demonstration" && return 0
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
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "conclusion\|Conclusion" && return 0
            return 1
            ;;
        has_problem)
            # For slides - check for problem statement or motivation
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "problem\|Problem\|motivation\|Motivation" && return 0
            return 1
            ;;
        has_challenges)
            # For slides - check for challenges or lessons learned section
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "challenge\|Challenge\|difficult\|Difficult\|lesson\|Lesson" && return 0
            return 1
            ;;
        no_template_files)
            # Check that NordlingLab beamer template files have been removed
            # Reference: https://bitbucket.org/nordlinglab/nordlinglab-template-beamer/
            local dir_name
            # For folder submissions, check inside the folder
            if [[ -d "$filepath" ]]; then
                dir_name="$filepath"
            else
                dir_name=$(dirname "$filepath")
            fi

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
            local check_path="$filepath"
            local dir_name
            local base_name
            local base_only

            # For folder submissions, check inside the folder
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                dir_name="$filepath"
                base_only=$(basename "$filepath")
            else
                dir_name=$(dirname "$filepath")
                base_name="${filepath%.*}"
                base_only=$(basename "$base_name")
            fi
            [[ -z "$check_path" ]] && return 1
            local figures_folder="${base_only}-Figures"

            # Check for figures folder
            if [[ -d "$dir_name/$figures_folder" ]]; then
                return 0
            fi
            # Also check for Figures subfolder inside submission folder
            if [[ -d "$dir_name" ]] && [[ -d "$dir_name/Figures" ]]; then
                return 0
            fi

            # Check for individual figure files (YYYY-Name-Name-Figure1.pdf, etc.)
            # Use find instead of ls to avoid glob expansion errors
            if find "$dir_name" -maxdepth 1 -name "${base_only}-Figure*" \( -name "*.pdf" -o -name "*.png" -o -name "*.jpg" \) 2>/dev/null | grep -q .; then
                return 0
            fi
            # For folder submissions, also check for any figure files inside
            if [[ -d "$filepath" ]]; then
                if find "$filepath" -maxdepth 1 -name "*.pdf" -o -name "*.png" -o -name "*.jpg" 2>/dev/null | grep -q .; then
                    return 0
                fi
            fi

            # No figures found - check if the report mentions figures
            # If they mention figures but don't have properly named files, fail
            if content_contains "$check_path" "Figure\|figure\|Fig\\."; then
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
            # For README files in group submissions (with partial credit)
            if [[ ! -f "$filepath/README.md" ]]; then
                CRITERION_SCORE_PCT=0
                AUTHOR_SCORE_PENALTIES="no README.md found"
                return 1
            fi
            if ! content_contains "$filepath/README.md" "author\|Author\|member\|Member\|team\|Team"; then
                CRITERION_SCORE_PCT=0
                AUTHOR_SCORE_PENALTIES="no author info in README"
                return 1
            fi
            local result
            result=$(calculate_author_score "$filepath/README.md" "true")
            CRITERION_SCORE_PCT="${result%%|*}"
            AUTHOR_SCORE_PENALTIES="${result#*|}"
            [[ $CRITERION_SCORE_PCT -gt 0 ]] && return 0
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
            local check_path="$filepath"
            # For folder submissions, check inside the folder
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            local dir=$(dirname "$check_path")
            local base=$(basename "$check_path" .drawio)
            [[ -f "$dir/${base}.pdf" ]] && return 0
            # Also check for any .pdf file in the folder
            [[ -d "$filepath" ]] && find "$filepath" -maxdepth 1 -name "*.pdf" -type f 2>/dev/null | grep -q . && return 0
            return 1
            ;;
        pdf_single_page)
            # Check that PDF export has exactly one page
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            local dir=$(dirname "$check_path")
            local base=$(basename "$check_path" .drawio)
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
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "component\|<<\|stereotype" && return 0
            return 1
            ;;
        has_components)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "mxCell\|component\|<<" && return 0
            return 1
            ;;
        has_connections)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "edge\|arrow\|flow" && return 0
            return 1
            ;;
        uses_beamer)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "documentclass.*beamer\|beamer" && return 0
            return 1
            ;;
        uses_169_aspect)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "aspectratio=169\|169" && return 0
            return 1
            ;;
        uses_nordlinglab_theme)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "NordlingLab169\|NordlingLab" && return 0
            return 1
            ;;
        has_title_slide)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "titlepage\|title" && return 0
            return 1
            ;;
        has_required_sections)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && return 1
            fi
            content_contains "$check_path" "section\|begin{frame}" && return 0
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
            # Check if video is public using oEmbed API (fast) and cached yt-dlp data
            local url=$(cat "$filepath" 2>/dev/null | head -1 | tr -d '[:space:]')
            if ! is_youtube_url "$url"; then
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}Invalid YouTube URL: '$url'${NC}" >&2
                fi
                return 1
            fi

            # Step 1: Check if video exists using YouTube oEmbed API (no yt-dlp needed, fast)
            local oembed_url="https://www.youtube.com/oembed?url=${url}&format=json"
            local http_code
            LAST_CMD="curl -s -o /dev/null -w '%{http_code}' '$oembed_url'"
            http_code=$(run_with_timeout 5 "$LAST_CMD")
            if [[ "$http_code" == "TIMEOUT" ]]; then
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}WARNING: curl timed out (5s), skipping is_public check${NC}" >&2
                    echo -e "        ${YELLOW}Command: $LAST_CMD${NC}" >&2
                fi
                return 0  # Skip check on timeout
            fi
            if [[ "$http_code" != "200" ]]; then
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}Command: $LAST_CMD${NC}" >&2
                    echo -e "        ${YELLOW}HTTP code: $http_code (expected 200)${NC}" >&2
                fi
                return 1
            fi

            # Step 2: Check cached availability if yt-dlp available
            if command -v yt-dlp &>/dev/null; then
                # Fetch metadata (will use cache if valid)
                if ! fetch_video_metadata "$url"; then
                    # Failed to fetch, but oEmbed passed so likely public
                    return 0
                fi
                local availability=$(get_cached_video_field "$url" "availability")
                if [[ "$availability" == "public" || -z "$availability" ]]; then
                    return 0
                fi
                if [[ "$availability" != "private" ]]; then
                    return 0
                fi
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}Availability: $availability (expected 'public' or non-private)${NC}" >&2
                fi
                return 1
            fi
            # yt-dlp not installed - oEmbed passed, so video is likely public
            return 0
            ;;
        duration_max_12min)
            # Check if video duration is max 12.5 minutes (750 seconds)
            local url=$(cat "$filepath" 2>/dev/null | head -1 | tr -d '[:space:]')
            if ! command -v yt-dlp &>/dev/null; then
                return 0
            fi
            if ! is_youtube_url "$url"; then
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}Invalid YouTube URL: '$url'${NC}" >&2
                fi
                return 1
            fi

            # Fetch metadata (will use cache if valid)
            if ! fetch_video_metadata "$url"; then
                return 0  # Skip check if fetch failed
            fi

            local duration=$(get_cached_video_field "$url" "duration")
            if [[ -z "$duration" || "$duration" == "NA" || "$duration" == "null" ]]; then
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}Duration: '$duration' (empty or NA)${NC}" >&2
                fi
                return 1
            fi
            # Max 750 seconds (12.5 minutes)
            if [[ "$duration" -le 750 ]]; then
                return 0
            fi
            if [[ "$VERBOSE" == "true" ]]; then
                echo -n -e "${YELLOW}Duration: ${duration}s exceeds max 750s (12.5 min)${NC}" >&2
            fi
            return 1
            ;;
        resolution_min_1080p)
            # Check if video has at least 1080p resolution available
            local url=$(cat "$filepath" 2>/dev/null | head -1 | tr -d '[:space:]')
            if ! command -v yt-dlp &>/dev/null; then
                return 0
            fi
            if ! is_youtube_url "$url"; then
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}Invalid YouTube URL: '$url'${NC}" >&2
                fi
                return 1
            fi

            # Fetch metadata (will use cache if valid)
            if ! fetch_video_metadata "$url"; then
                return 0  # Skip check if fetch failed
            fi

            local height=$(get_cached_video_field "$url" "height")
            if [[ -z "$height" || "$height" == "NA" || "$height" == "null" ]]; then
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}Height: '$height' (empty or NA)${NC}" >&2
                fi
                return 1
            fi
            # Min 1080 pixels height
            if [[ "$height" -ge 1080 ]]; then
                return 0
            fi
            if [[ "$VERBOSE" == "true" ]]; then
                echo -n -e "${YELLOW}Resolution: ${height}p is below 1080p minimum${NC}" >&2
            fi
            return 1
            ;;
        has_subtitles)
            # Check if video has subtitles (English or Chinese)
            local url=$(cat "$filepath" 2>/dev/null | head -1 | tr -d '[:space:]')
            if ! command -v yt-dlp &>/dev/null; then
                return 0
            fi
            if ! is_youtube_url "$url"; then
                if [[ "$VERBOSE" == "true" ]]; then
                    echo -n -e "${YELLOW}Invalid YouTube URL: '$url'${NC}" >&2
                fi
                return 1
            fi

            # Fetch metadata (will use cache if valid)
            if ! fetch_video_metadata "$url"; then
                return 0  # Skip check if fetch failed
            fi

            local video_id=$(get_youtube_video_id "$url")
            local cache_file=$(get_video_cache_path "$video_id")

            # Check for subtitles using jq - look for language keys in subtitles or automatic_captions
            # Accepted languages: en, zh, zh-TW, zh-Hant, zh-Hans
            if jq -e '.subtitles | has("en") or has("zh") or has("zh-TW") or has("zh-Hant") or has("zh-Hans")' "$cache_file" >/dev/null 2>&1; then
                return 0
            fi

            # Also check automatic_captions
            if jq -e '.automatic_captions | has("en") or has("zh") or has("zh-TW") or has("zh-Hant") or has("zh-Hans")' "$cache_file" >/dev/null 2>&1; then
                return 0
            fi
            if [[ "$VERBOSE" == "true" ]]; then
                echo -n -e "${YELLOW}No matching subtitles found (en/zh/zh-TW/zh-Hant/zh-Hans)${NC}" >&2
            fi
            return 1
            ;;
        has_author)
            # For individual submissions - singular author (with partial credit)
            if ! content_contains "$filepath" "[Aa]uthor"; then
                CRITERION_SCORE_PCT=0
                AUTHOR_SCORE_PENALTIES="no author info found"
                return 1
            fi
            local result
            result=$(calculate_author_score "$filepath" "false")
            CRITERION_SCORE_PCT="${result%%|*}"
            AUTHOR_SCORE_PENALTIES="${result#*|}"
            [[ $CRITERION_SCORE_PCT -gt 0 ]] && return 0
            return 1
            ;;
        has_authors)
            # For group submissions - author(s)/group members/team (with partial credit)
            local check_path="$filepath"
            # For folder submissions, check the main file inside
            if [[ -d "$filepath" ]]; then
                check_path=$(get_effective_filepath "$filepath" "$submission_type")
                [[ -z "$check_path" ]] && {
                    CRITERION_SCORE_PCT=0
                    AUTHOR_SCORE_PENALTIES="no main file found in folder"
                    return 1
                }
            fi
            if ! content_contains "$check_path" "[Aa]uthors\|[Aa]uthor\|[Gg]roup\|[Mm]embers\|[Tt]eam"; then
                CRITERION_SCORE_PCT=0
                AUTHOR_SCORE_PENALTIES="no author info found"
                return 1
            fi
            local result
            result=$(calculate_author_score "$check_path" "true")
            CRITERION_SCORE_PCT="${result%%|*}"
            AUTHOR_SCORE_PENALTIES="${result#*|}"
            [[ $CRITERION_SCORE_PCT -gt 0 ]] && return 0
            return 1
            ;;
        has_group_members)
            # Specifically for report - check for group members section
            content_contains "$filepath" "[Gg]roup\|[Mm]embers\|[Tt]eam" && return 0
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
            echo "filename_format:10:File named correctly"
            echo "file_extension:5:Has .md extension"
            echo "has_license:10:Has license"
            echo "has_author:10:Has author"
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
            echo "has_license:7:Has license"
            echo "has_title:7:Has title"
            echo "has_author:7:Has author"
            echo "has_group_members:6:Has group members"
            echo "has_abstract:7:Has abstract"
            echo "has_introduction:7:Has introduction"
            echo "has_system_architecture:7:Has architecture"
            echo "has_implementation:7:Has implementation"
            echo "has_results:6:Has results"
            echo "has_discussion:6:Has discussion"
            echo "has_conclusion:6:Has conclusion"
            echo "has_references:7:Has references"
            ;;
        case-brief-group)
            echo "filename_format:10:File named correctly"
            echo "file_extension:5:Has .md extension"
            echo "has_license:10:Has license"
            echo "has_authors:10:Has authors"
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
            echo "has_authors:5:Has authors"
            echo "has_overview:5:Has overview"
            echo "has_usage:5:Has usage"
            echo "has_known_issues:3:Has known issues"
            # Test types
            echo "has_unit_tests:5:Has unit tests"
            echo "has_integration_tests:5:Has integration tests"
            echo "has_e2e_tests:5:Has E2E tests"
            # Test case fields
            echo "has_test_id:4:Has test ID"
            echo "has_test_description:5:Has test description"
            echo "has_preconditions:5:Has preconditions"
            echo "has_input:5:Has input"
            echo "has_expected_output:5:Has expected output"
            echo "has_actual_output:5:Has actual output"
            echo "has_status:5:Has status"
            # Analysis fields
            echo "has_result_summary:5:Has result summary"
            echo "has_failed_analysis:3:Has failed analysis"
            echo "has_performance_metrics:5:Has performance"
            echo "has_conclusion:5:Has conclusion"
            ;;
        system-design)
            echo "filename_format:10:File named correctly"
            echo "file_extension:5:Has .drawio extension"
            echo "has_pdf:10:Has exported PDF"
            echo "pdf_single_page:10:PDF is single page"
            echo "has_license:10:Has license"
            echo "has_authors:10:Has authors"
            echo "uses_uml:15:Uses UML"
            echo "has_components:15:Has components"
            echo "has_connections:15:Has connections"
            ;;
        slides)
            echo "filename_format:10:File named correctly"
            echo "file_extension:5:Has .tex extension"
            echo "figure_format:5:Figures named correctly"
            echo "no_template_files:5:No template files"
            echo "has_license:5:Has license"
            echo "has_authors:10:Has authors"
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

    [[ "$VERBOSE" == "true" ]] && echo "      Checking criteria for: $(basename "$filepath")" >&2

    # Process each criterion
    local line
    for line in ${(f)criteria_lines}; do
        local criterion="${line%%:*}"
        local rest="${line#*:}"
        local weight="${rest%%:*}"
        local description="${rest#*:}"

        if [[ "$VERBOSE" == "true" ]]; then
            echo -n "        $criterion (weight: $weight)... " >&2
        fi

        # Reset partial credit percentage (some criteria set this for partial scoring)
        CRITERION_SCORE_PCT=100
        AUTHOR_SCORE_PENALTIES=""

        if check_criterion "$criterion" "$submission_type" "$filepath" "$year"; then
            # Calculate points with potential partial credit
            local earned_points=$((weight * CRITERION_SCORE_PCT / 100))
            score=$((score + earned_points))

            if [[ $CRITERION_SCORE_PCT -eq 100 ]]; then
                [[ "$VERBOSE" == "true" ]] && echo -e "\033[0;32mPASS\033[0m (+$weight)" >&2
            else
                # Partial credit
                [[ "$VERBOSE" == "true" ]] && echo -e "\033[0;33mPARTIAL\033[0m (+$earned_points of $weight, ${CRITERION_SCORE_PCT}%)" >&2
                if [[ "$VERBOSE" == "true" && -n "$AUTHOR_SCORE_PENALTIES" ]]; then
                    echo -e "          \033[0;33m↳ ${AUTHOR_SCORE_PENALTIES}\033[0m" >&2
                fi
                # Add to notes with partial indicator
                [[ -n "$notes" ]] && notes="$notes; "
                notes="${notes}${criterion}(${CRITERION_SCORE_PCT}%)"
            fi
        else
            [[ -n "$notes" ]] && notes="$notes; "
            notes="${notes}${criterion}"
            [[ "$VERBOSE" == "true" ]] && echo -e "\033[0;31mFAIL\033[0m" >&2
        fi
    done

    # If score is 0 but file exists, set to 1
    if [[ $score -eq 0 ]]; then
        score=1
    fi

    [[ "$VERBOSE" == "true" ]] && echo "      Total score: $score" >&2

    echo "${score}|${notes}"
}

# ============================================================================
# FIND SUBMISSIONS
# ============================================================================

# Detect if a case-brief is individual or group based on content
# Returns "individual", "group", or "unknown"
# Individual: has "Author:" (singular) with typically one name
# Group: has "Authors:" (plural), "Group:", "Members:", or "Author:" with 3+ names
is_group_case_brief() {
    local filepath="$1"
    local first_lines
    local author_line

    [[ ! -f "$filepath" ]] && echo "unknown" && return

    # Read first 20 lines to find author line
    first_lines=$(head -20 "$filepath" 2>/dev/null)

    # Check for "Authors:" (plural with 's') - definitely group
    if echo "$first_lines" | grep -qiE "^[*#[:space:]]*authors[*]*[[:space:]]*:"; then
        echo "group"
        return
    fi

    # Check for "Group:" or "Members:" - definitely group
    if echo "$first_lines" | grep -qiE "^[*#[:space:]]*(group|members)[*]*[[:space:]]*:"; then
        echo "group"
        return
    fi

    # Check for "Author:" (singular) and analyze content
    author_line=$(echo "$first_lines" | grep -iE "^[*#[:space:]]*author[*]*[[:space:]]*:" | head -1)
    if [[ -n "$author_line" ]]; then
        # Extract the part after "Author:"
        local names_part="${author_line#*:}"
        # Remove markdown formatting
        names_part=$(echo "$names_part" | sed 's/[*#]//g')

        # Count potential names by looking for patterns:
        # - Comma-separated names (e.g., "Name1, Name2, Name3")
        # - Multiple YYYY- prefixed names
        local comma_count=$(echo "$names_part" | tr -cd ',' | wc -c)
        local year_prefix_count=$(echo "$names_part" | grep -oE '20[0-9]{2}-' | wc -l)

        # If 2+ commas OR 2+ year-prefixed names, it's a group (3+ people)
        if [[ "$comma_count" -ge 2 ]] || [[ "$year_prefix_count" -ge 2 ]]; then
            echo "group"
            return
        fi

        # Single author - individual
        echo "individual"
        return
    fi

    echo "unknown"
}

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
        case-brief)
            # Find individual case-briefs based on content (Author: singular, not Authors: plural)
            # This filters out group case-briefs that were placed in the individual folder
            find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | while read -r f; do
                local brief_type=$(is_group_case_brief "$f")
                # Include if individual or unknown (give benefit of doubt)
                if [[ "$brief_type" != "group" ]]; then
                    echo "$f"
                fi
            done | sort
            ;;
        report)
            # Find ALL report markdown files matching YYYY-*.md pattern
            # Files with naming errors will get filename_format=0 but still be evaluated
            find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | sort
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
            # Find group markdown files based on content (Authors: plural)
            # Filter out individual submissions that were misplaced in this folder
            find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | while read -r f; do
                local brief_type=$(is_group_case_brief "$f")
                if [[ "$brief_type" == "group" ]]; then
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
            # Find .drawio files AND folders (some groups submit folders instead of files)
            {
                find "$folder_path" -maxdepth 1 -name "${year}-*.drawio" -type f 2>/dev/null
                find "$folder_path" -maxdepth 1 -type d -name "${year}-*" 2>/dev/null
            } | sort -u
            ;;
        slides)
            # Find .tex files AND folders (some groups submit folders instead of files)
            {
                find "$folder_path" -maxdepth 1 -name "${year}-*.tex" -type f 2>/dev/null
                find "$folder_path" -maxdepth 1 -type d -name "${year}-*" 2>/dev/null
            } | sort -u
            ;;
        video)
            find "$folder_path" -maxdepth 1 -name "${year}-*.txt" -type f 2>/dev/null | sort
            ;;
    esac
}

# Count all files/folders matching year pattern for a submission type
# Returns total count regardless of naming format (for verification)
count_all_submissions() {
    local submission_type="$1"
    local year="$2"
    local folder="${FOLDER_MAP[$submission_type]}"
    local folder_path="$BASE_DIR/$folder"
    local count=0

    [[ ! -d "$folder_path" ]] && echo "0" && return

    case "$submission_type" in
        ssh-key)
            count=$(find "$folder_path" -maxdepth 1 -name "${year}-*.pub" -type f 2>/dev/null | wc -l)
            ;;
        case-brief|report)
            count=$(find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | wc -l)
            ;;
        case-brief-group)
            count=$(find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | wc -l)
            ;;
        data|project-code)
            count=$(find "$folder_path" -maxdepth 1 -type d -name "${year}-*" 2>/dev/null | wc -l)
            ;;
        tests|reflection)
            count=$(find "$folder_path" -maxdepth 1 -name "${year}-*.md" -type f 2>/dev/null | wc -l)
            ;;
        system-design)
            count=$(find "$folder_path" -maxdepth 1 -name "${year}-*.drawio" -type f 2>/dev/null | wc -l)
            ;;
        slides)
            count=$(find "$folder_path" -maxdepth 1 -name "${year}-*.tex" -type f 2>/dev/null | wc -l)
            ;;
        video)
            count=$(find "$folder_path" -maxdepth 1 -name "${year}-*.txt" -type f 2>/dev/null | wc -l)
            ;;
    esac

    echo "$((count))"  # Trim whitespace
}

# ============================================================================
# CSV OPERATIONS
# ============================================================================

# Initialize CSV with headers
initialize_group_csv() {
    local csvfile="$1"

    local header="Group ID,Group Members"
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

# Store previous CSV data for score comparison (loaded at start, before new evaluation)
# Used to warn when scores are lowered compared to previous run
declare -A PREVIOUS_CSV_DATA

# Store student to group membership mapping
# Format: STUDENT_GROUP_MEMBERSHIP[normalized_family_name] = "group1,group2,..." (comma-separated list)
declare -A STUDENT_GROUP_MEMBERSHIP

# Store full name to group mapping (more precise than family name)
# Format: STUDENT_FULL_NAME_TO_GROUP[normalized_full_name] = "Group ID" (e.g., "2026-Chen-Chen-Liu")
declare -A STUDENT_FULL_NAME_TO_GROUP

# Store group full member names
# Format: GROUP_FULL_MEMBERS[group_id] = "Name1 & Name2 & Name3"
declare -A GROUP_FULL_MEMBERS

# Store group ID for each student (individual)
# Format: STUDENT_GROUP_ID[normalized_full_name] = "Group ID"
declare -A STUDENT_GROUP_ID

# Track students assigned during group loading (to prevent duplicates)
# Format: ASSIGNED_STUDENTS[normalized_name] = "group_id"
declare -A ASSIGNED_STUDENTS

# Normalize a name for comparison: lowercase, remove hyphens/commas, collapse spaces
normalize_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d ',-' | tr -s ' '
}

# Normalize a group key to Group ID format: YYYY-Family1-Family2-...
# group_key: space-separated family names (e.g., "Chen Chen Liu")
# year: the year (e.g., "2026")
normalize_group_id() {
    local group_key="$1"
    local year="$2"
    # Replace spaces with dashes and ensure proper capitalization
    local normalized="${group_key// /-}"
    echo "${year}-${normalized}"
}

# Extract first name from a full name (everything after the first space)
extract_first_name() {
    local full_name="$1"
    echo "${full_name#* }"  # Remove up to first space
}

# Fuzzy match two strings with tolerance up to max_distance characters different
# Returns 0 if match, 1 if no match
fuzzy_match() {
    local str1="$1"
    local str2="$2"
    local max_distance="${3:-2}"

    # Normalize both strings: lowercase
    local s1="${(L)str1}"
    local s2="${(L)str2}"

    # Exact match first
    [[ "$s1" == "$s2" ]] && return 0

    # Use levenshtein_distance for fuzzy match
    local dist=$(levenshtein_distance "$s1" "$s2")
    [[ $dist -le $max_distance ]] && return 0

    return 1
}

# Find a group by ID with fuzzy matching
# Returns the canonical group ID if found, empty if not
find_group_fuzzy() {
    local search_id="$1"
    local year="$2"

    # Normalize search term
    local search_norm="${(L)search_id}"
    search_norm="${search_norm//-/ }"  # Convert dashes to spaces for comparison

    # First try exact match against STUDENT_GROUP_MEMBERSHIP keys (which are family names)
    # Check all registered groups
    local -a all_groups
    all_groups=()
    local family group_list
    for family in ${(k)STUDENT_GROUP_MEMBERSHIP}; do
        local IFS=','
        for group in ${(s:,:)STUDENT_GROUP_MEMBERSHIP[$family]}; do
            # Add to array if not already present
            if [[ ! " ${all_groups[*]} " == *" $group "* ]]; then
                all_groups+=("$group")
            fi
        done
    done

    # Check each group for match
    local group group_norm group_id
    for group in "${all_groups[@]}"; do
        group_norm="${(L)group}"
        group_id=$(normalize_group_id "$group" "$year")

        # Exact match
        if [[ "$search_norm" == "$group_norm" ]] || [[ "${(L)search_id}" == "${(L)group_id}" ]]; then
            echo "$group_id"
            return 0
        fi
    done

    # Fuzzy match (up to 2 char difference)
    for group in "${all_groups[@]}"; do
        group_norm="${(L)group}"
        if fuzzy_match "$search_norm" "$group_norm" 2; then
            echo "$(normalize_group_id "$group" "$year")"
            return 0
        fi
    done

    return 1
}

# Register all members of a group for later lookup
# group_members_str: space-separated family names (e.g., "Chen Liu Wang")
register_group_membership() {
    local group_members_str="$1"
    local -a members
    members=(${(s: :)group_members_str})

    for member in "${members[@]}"; do
        # Skip if it's a known tag
        if is_known_tag "$member"; then
            continue
        fi
        # Normalize to lowercase for consistent lookup
        local normalized=$(echo "$member" | tr '[:upper:]' '[:lower:]')
        # Append to list of groups (comma-separated) instead of overwriting
        if [[ -n "${STUDENT_GROUP_MEMBERSHIP[$normalized]:-}" ]]; then
            # Check if this group is already in the list to avoid duplicates
            if [[ ",${STUDENT_GROUP_MEMBERSHIP[$normalized]}," != *",$group_members_str,"* ]]; then
                STUDENT_GROUP_MEMBERSHIP[$normalized]="${STUDENT_GROUP_MEMBERSHIP[$normalized]},$group_members_str"
            fi
        else
            STUDENT_GROUP_MEMBERSHIP[$normalized]="$group_members_str"
        fi
    done
}

# Parse author info from a file (README.md or markdown file)
# Returns extracted full names or empty if not found
parse_author_from_file() {
    local filepath="$1"

    [[ ! -f "$filepath" ]] && return

    # Look for Author/Authors/Members lines in first 30 lines
    local author_line
    author_line=$(head -30 "$filepath" | grep -iE "^\*?\*?(Author|Authors|Members)\*?\*?:" | head -1 || true)
    [[ -z "$author_line" ]] && return

    # Extract the part after the colon
    local members_part="${author_line#*:}"
    # Remove markdown formatting
    members_part="${members_part//\*\*/}"
    members_part="${members_part//\*/}"
    # Remove 2026- prefix
    members_part="${members_part//2026-/}"
    # Remove parenthetical notes
    members_part=$(echo "$members_part" | sed 's/([^)]*)//g')
    # Trim whitespace
    members_part="${members_part#"${members_part%%[![:space:]]*}"}"
    members_part="${members_part%"${members_part##*[![:space:]]}"}"

    echo "$members_part"
}

# Load full names for a specific group from all submission types
# group_key: space-separated family names (e.g., "Chen Chen Liu")
# year: the year (e.g., "2026")
# base_dir: base directory
load_group_full_names() {
    local group_key="$1"
    local year="$2"
    local base_dir="$3"

    local group_id=$(normalize_group_id "$group_key" "$year")
    local group_dashed="${group_key// /-}"
    local members_found=""
    local -a full_names
    full_names=()

    # List of submission types and their directories/patterns
    # Format: "dir_name:pattern:is_folder"
    local -a search_locations
    search_locations=(
        "case-brief-individual:${year}-${group_dashed}*.md:file"
        "data-group:${year}-${group_dashed}*:folder"
        "project-code-group:${year}-${group_dashed}*:folder"
        "tests-group:${year}-${group_dashed}*.md:file"
        "reflection-group:${year}-${group_dashed}*.md:file"
    )

    local location dir pattern type filepath author_info
    for location in "${search_locations[@]}"; do
        dir="${location%%:*}"
        local rest="${location#*:}"
        pattern="${rest%%:*}"
        type="${rest##*:}"

        local search_dir="$base_dir/$dir"
        [[ ! -d "$search_dir" ]] && continue

        [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "      Searching $dir with pattern $pattern"
        # Find matching files/folders (N: null glob - no error if no matches)
        for filepath in "$search_dir"/$~pattern(N); do
            [[ ! -e "$filepath" ]] && continue

            [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "        Found: $filepath"

            # Strip tags from the path to verify it's the right group
            local basename_clean=$(basename "$filepath")
            basename_clean="${basename_clean%.*}"  # Remove extension
            basename_clean="${basename_clean#${year}-}"  # Remove year prefix
            basename_clean=$(strip_submission_suffixes "$basename_clean")

            # Fuzzy match to verify it's the right group
            if ! fuzzy_match "${basename_clean//-/ }" "$group_key" 2; then
                [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "        Skipped (fuzzy mismatch)"
                continue
            fi

            # Determine which file to parse
            local file_to_parse=""
            if [[ "$type" == "folder" ]]; then
                file_to_parse="$filepath/README.md"
            else
                file_to_parse="$filepath"
            fi

            [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "        Parsing: $file_to_parse"
            author_info=$(parse_author_from_file "$file_to_parse")
            [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "        Author info: ${author_info:-<none>}"

            # If we got author info with full names (contains spaces), use it
            if [[ -n "$author_info" && "$author_info" == *" "* ]]; then
                members_found="$author_info"
                break 2  # Exit both loops - we found good data
            fi
        done
    done
    [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "      Done searching group submissions"

    # If no full names found from group submissions, try to match from individual filenames
    if [[ -z "$members_found" || "$members_found" != *" "* ]]; then
        [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "      Falling back to individual filename matching"
        # Build full names from individual submission filenames that match group family names
        local -a group_families
        group_families=(${(s: :)group_key})

        local ind_dir="$base_dir/report-individual"
        [[ ! -d "$ind_dir" ]] && ind_dir="$base_dir/case-brief-individual"

        if [[ -d "$ind_dir" ]]; then
            local ind_file family ind_name
            for ind_file in "$ind_dir"/${year}-*.md(N); do
                [[ ! -f "$ind_file" ]] && continue

                local ind_basename=$(basename "$ind_file" .md)
                ind_basename="${ind_basename#${year}-}"

                # Strip known suffixes before checking dash count
                ind_basename="${ind_basename%-report}"
                ind_basename="${ind_basename%-brief}"

                # Skip group case briefs (those with multiple dashes after stripping suffixes)
                local dash_count="${ind_basename//[^-]/}"
                [[ ${#dash_count} -ge 2 ]] && continue

                # Extract family name (first part before dash)
                local ind_family="${ind_basename%%-*}"
                local ind_first="${ind_basename#*-}"
                ind_first="${ind_first//-/}"  # Remove any remaining dashes

                # Check if this family name is in the group
                # Use exact match for short names (<=3 chars) to avoid false positives like Lin/Liu
                for family in "${group_families[@]}"; do
                    local match=false
                    if [[ ${#ind_family} -le 3 || ${#family} -le 3 ]]; then
                        # Exact match for short names (case-insensitive)
                        [[ "${(L)ind_family}" == "${(L)family}" ]] && match=true
                    else
                        # Fuzzy match for longer names
                        fuzzy_match "$ind_family" "$family" 1 && match=true
                    fi

                    if $match; then
                        # Found a match - check if already assigned to another group
                        local full_name="${(C)ind_family} ${(C)ind_first}"
                        local norm_key=$(normalize_name "$full_name")

                        # Skip if already assigned to a different group
                        if [[ -n "${ASSIGNED_STUDENTS[$norm_key]:-}" && "${ASSIGNED_STUDENTS[$norm_key]}" != "$group_id" ]]; then
                            [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "        Skipping $full_name (already in ${ASSIGNED_STUDENTS[$norm_key]})"
                            break
                        fi

                        full_names+=("$full_name")
                        break
                    fi
                done
            done
        fi

        # Convert array to & separated string
        if [[ ${#full_names[@]} -gt 0 ]]; then
            members_found="${(j: & :)full_names}"
        fi
        [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "      Individual matching found: ${members_found:-<none>}"
    fi

    [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "      Final members: ${members_found:-<none>}"
    # Parse and register the full names
    if [[ -n "$members_found" ]]; then
        # Parse, reorder to Family-First format, and register
        # This will use group family names to properly detect and reorder names
        parse_case_brief_members_with_group_id "$members_found" "$group_key" "$group_id"

        # Show members found (after parsing/reordering)
        local final_members="${GROUP_FULL_MEMBERS[$group_id]:-$members_found}"
        echo "        Members: $final_members"
    else
        echo "        Members: (none found, using folder names)"
    fi
}

# Capitalize a hyphenated name properly (e.g., "cheng-yu" -> "Cheng-Yu")
capitalize_hyphenated() {
    local name="$1"
    local result=""
    local part
    local first=true

    # Handle names with hyphens (split and capitalize each part)
    if [[ "$name" == *-* ]]; then
        local -a parts
        parts=(${(s:-:)name})
        for part in "${parts[@]}"; do
            part="${(C)${(L)part}}"
            if $first; then
                result="$part"
                first=false
            else
                result="${result}-${part}"
            fi
        done
        echo "$result"
    else
        echo "${(C)${(L)name}}"
    fi
}

# Reorder a name to "Family Given" format using group family names as guidance
# Arguments:
#   $1: name - the full name to reorder (e.g., "Cheng-Yu Fan" or "Po Lin Lee")
#   $2: group_families - space-separated family names from group (e.g., "Fan Lee Liu")
# Returns: reordered name in "Family Given" format, preserving hyphens in given names
reorder_name_to_family_first() {
    local name="$1"
    local group_families="$2"

    # Split group families into array (lowercase for comparison)
    local -a family_list
    family_list=(${(s: :)group_families})

    # Handle hyphenated names: "Cheng-Yu Fan" -> parts are "Cheng-Yu" and "Fan"
    # Also handle space-separated: "Po Lin Lee" -> parts are "Po", "Lin", "Lee"
    local -a name_parts
    name_parts=(${(s: :)name})
    local num_parts=${#name_parts[@]}

    [[ $num_parts -eq 0 ]] && echo "$name" && return
    [[ $num_parts -eq 1 ]] && echo "$name" && return

    # Find which part is the family name by matching against group family names
    local found_family="" found_family_idx=0
    local i=0 part="" part_base="" part_lower="" fam="" fam_lower=""

    for ((i=1; i<=num_parts; i++)); do
        part="${name_parts[$i]}"
        # For hyphenated parts like "Cheng-Yu", use the whole part for family comparison
        # (some family names might be hyphenated)
        part_base="${part%%-*}"
        part_lower="${(L)part_base}"

        # Check if this part matches a family name
        for fam in "${family_list[@]}"; do
            fam_lower="${(L)fam}"
            if [[ "$part_lower" == "$fam_lower" ]]; then
                found_family="$part"
                found_family_idx=$i
                break 2
            fi
            # Fuzzy match (1 char difference)
            local dist=$(levenshtein_distance "$part_lower" "$fam_lower")
            if [[ $dist -le 1 ]]; then
                found_family="$part"
                found_family_idx=$i
                break 2
            fi
        done
    done

    local family_cap="" given_cap="" given_joined=""

    if [[ -n "$found_family" && $found_family_idx -gt 0 ]]; then
        # Build given name from all other parts, preserving hyphens
        given_joined=""
        for ((i=1; i<=num_parts; i++)); do
            if [[ $i -ne $found_family_idx ]]; then
                given_joined="${given_joined}${name_parts[$i]}"
            fi
        done

        # Normalize capitalization
        family_cap=$(capitalize_hyphenated "$found_family")
        given_cap=$(capitalize_hyphenated "$given_joined")
    else
        # No family match found - assume last part is family (Western convention in source)
        # or first part is family (East Asian convention) - we assume last for Western format input
        family_cap=$(capitalize_hyphenated "${name_parts[$num_parts]}")
        given_joined=""
        for ((i=1; i<num_parts; i++)); do
            given_joined="${given_joined}${name_parts[$i]}"
        done
        given_cap=$(capitalize_hyphenated "$given_joined")
    fi

    echo "$family_cap $given_cap"
}

# Parse member names and register with group ID
parse_case_brief_members_with_group_id() {
    local members_part="$1"
    local group_key="$2"
    local group_id="$3"

    # Normalize separators: handle ", " and " , " and ";" and " & "
    members_part="${members_part// , /, }"
    members_part="${members_part//;/, }"
    members_part="${members_part// & /, }"

    local -a member_parts
    member_parts=("${(@s:, :)members_part}")

    local -a collected_names
    collected_names=()

    local member="" normalized_member="" family="" first="" given="" before="" after=""

    for member in "${member_parts[@]}"; do
        # Trim whitespace
        member="${member#"${member%%[![:space:]]*}"}"
        member="${member%"${member##*[![:space:]]}"}"
        [[ -z "$member" ]] && continue

        normalized_member=""

        # Handle "LASTNAME,FIRSTNAME" format (e.g., "Fan,ChengYu")
        if [[ "$member" == *,* && "$member" != *" "* ]]; then
            family="${member%%,*}"
            first="${member#*,}"
            family=$(capitalize_hyphenated "$family")
            first=$(capitalize_hyphenated "$first")
            normalized_member="$family $first"
        # Handle space-separated format (e.g., "Cheng-Yu Fan" or "Po Lin Lee")
        elif [[ "$member" == *" "* ]]; then
            # Reorder using group family names as guidance
            normalized_member=$(reorder_name_to_family_first "$member" "$group_key")
        # Handle hyphenated format without spaces (e.g., "Fan-ChengYu")
        elif [[ "$member" == *-* ]]; then
            # First hyphen separates family from given
            family="${member%%-*}"
            given="${member#*-}"
            family=$(capitalize_hyphenated "$family")
            given=$(capitalize_hyphenated "$given")
            normalized_member="$family $given"
        fi

        if [[ -n "$normalized_member" && "$normalized_member" == *" "* ]]; then
            # Check if already assigned to a different group
            local norm_key=$(normalize_name "$normalized_member")
            if [[ -n "${ASSIGNED_STUDENTS[$norm_key]:-}" && "${ASSIGNED_STUDENTS[$norm_key]}" != "$group_id" ]]; then
                [[ -n "$VERBOSE" && "$VERBOSE" == "true" ]] && echo "        Skipping $normalized_member (already in ${ASSIGNED_STUDENTS[$norm_key]})"
                continue
            fi

            collected_names+=("$normalized_member")

            # Register mappings
            STUDENT_FULL_NAME_TO_GROUP[$norm_key]="$group_key"
            STUDENT_GROUP_ID[$norm_key]="$group_id"
            ASSIGNED_STUDENTS[$norm_key]="$group_id"
        fi
    done

    # Sort collected names alphabetically by the full name (family first ensures family-based sort)
    if [[ ${#collected_names[@]} -gt 0 ]]; then
        # Use a newline-based sort to preserve full names with spaces
        local sorted_str
        sorted_str=$(printf '%s\n' "${collected_names[@]}" | sort)
        # Read back into array, preserving lines
        local -a sorted_names
        sorted_names=("${(@f)sorted_str}")
        GROUP_FULL_MEMBERS[$group_id]="${(j: & :)sorted_names}"
    fi
}

# Load group membership from all sources (comprehensive)
# Iterates through all groups in STUDENT_GROUP_MEMBERSHIP and finds full names
# base_dir: base directory
# year: the year prefix (e.g., "2026")
load_all_group_memberships() {
    local base_dir="$1"
    local year="$2"

    # Get unique groups from STUDENT_GROUP_MEMBERSHIP
    local -a all_groups
    all_groups=()
    local family group g
    local found=0
    for family in ${(k)STUDENT_GROUP_MEMBERSHIP}; do
        for group in ${(s:,:)STUDENT_GROUP_MEMBERSHIP[$family]}; do
            # Add to array if not already present
            found=0
            for g in "${all_groups[@]}"; do
                [[ "$g" == "$group" ]] && { found=1; break; }
            done
            [[ $found -eq 0 ]] && all_groups+=("$group")
        done
    done

    echo "  Found ${#all_groups[@]} unique groups to process"

    # Load full names for each group
    for group in "${all_groups[@]}"; do
        echo "    Processing group: $group"
        load_group_full_names "$group" "$year" "$base_dir"
    done
}

# Check if a student is a member of a specific group
# student_full_name: the student's full canonical name (e.g., "Chen GuoZhu")
# group_members_str: the group (e.g., "Chen Chen Liu")
# Returns 0 if member, 1 if not
is_group_member() {
    local student_full_name="$1"
    local group_members_str="$2"

    # First, try exact full name match (most accurate)
    local normalized_full=$(normalize_name "$student_full_name")
    local stored_group="${STUDENT_FULL_NAME_TO_GROUP[$normalized_full]:-}"
    if [[ -n "$stored_group" ]]; then
        [[ "$stored_group" == "$group_members_str" ]] && return 0
        return 1
    fi

    # Fall back to family name matching
    local student_family="${student_full_name%% *}"
    local normalized=$(echo "$student_family" | tr '[:upper:]' '[:lower:]')
    local stored_groups="${STUDENT_GROUP_MEMBERSHIP[$normalized]:-}"

    # Check if this group is in the comma-separated list
    if [[ -n "$stored_groups" ]]; then
        local IFS=','
        local -a groups_array
        groups_array=(${(s:,:)stored_groups})
        for group in "${groups_array[@]}"; do
            if [[ "$group" == "$group_members_str" ]]; then
                return 0
            fi
        done
    fi

    # As last resort, check if family name appears as a word in the group
    local group_lower=$(echo "$group_members_str" | tr '[:upper:]' '[:lower:]')
    local -a group_words
    group_words=(${(s: :)group_lower})
    for word in "${group_words[@]}"; do
        if [[ "$word" == "$normalized" ]]; then
            return 0
        fi
    done

    return 1
}

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
        line_num=$((line_num + 1))
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

# Load previous CSV into PREVIOUS_CSV_DATA for score comparison
# This is called at script start to compare new scores against old ones
load_previous_csv() {
    local csvfile="$1"
    local header line_num line row_key i
    local -a values columns

    [[ ! -f "$csvfile" ]] && return 1

    # Read header
    IFS= read -r header < "$csvfile"
    columns=(${(s:,:)header})

    # Read data rows
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        [[ $line_num -eq 1 ]] && continue  # Skip header

        values=(${(s:,:)line})
        row_key="${values[1]}"
        # Convert spaces to underscores for consistent key format
        local storage_key="${row_key// /_}"

        for i in {1..${#columns[@]}}; do
            PREVIOUS_CSV_DATA[$storage_key,${columns[$i]}]=${values[$i]:-}
        done
    done < "$csvfile"

    return 0
}

# Update or add a value in CSV data
# Warns if new value is lower than what was in the PREVIOUS CSV file (from before this run)
# Note: row_key should use underscores instead of spaces for storage
update_csv_value() {
    local row_key="$1"
    local column="$2"
    local new_value="$3"

    # Convert spaces to underscores in key for storage
    local storage_key="${row_key// /_}"

    # Compare against PREVIOUS CSV data (from file before this run), not current run's data
    local previous="${PREVIOUS_CSV_DATA[$storage_key,$column]:-}"

    if [[ -n "$previous" && "$previous" =~ ^[0-9]+$ && "$new_value" =~ ^[0-9]+$ ]]; then
        if [[ "$new_value" -lt "$previous" ]]; then
            echo -e "${YELLOW}WARNING: Score lowered for '$row_key' in '$column': $previous -> $new_value${NC}"
        fi
    fi

    CSV_DATA[$storage_key,$column]=$new_value
}

# Write CSV data to file
write_csv() {
    local csvfile="$1"
    local header="$2"
    local key row_key row col display_name normalized
    local -a header_cols
    local -a unique_rows

    print -r -- "$header" > "$csvfile"

    # Get unique row keys and merge duplicates using normalized keys
    # This handles cases like "Fan_ChengYu" and "Fan_Cheng-Yu" being the same person
    typeset -A row_keys_map      # storage_key → 1
    typeset -A normalized_to_display  # normalized_key → display_name (first seen)
    typeset -A normalized_to_storage  # normalized_key → storage_key (first seen)

    for key in ${(k)CSV_DATA}; do
        row_key="${key%%,*}"
        if [[ -z "${row_keys_map[$row_key]:-}" ]]; then
            row_keys_map[$row_key]=1
            # Convert storage key back to display name
            display_name="${row_key//_/ }"
            # Normalize for deduplication
            normalized=$(echo "$display_name" | sed 's/[-_ ,;:]//g' | tr '[:upper:]' '[:lower:]')
            if [[ -z "${normalized_to_display[$normalized]:-}" ]]; then
                normalized_to_display[$normalized]="$display_name"
                normalized_to_storage[$normalized]="$row_key"
            fi
        fi
    done

    # Write each unique row (merged by normalized key)
    header_cols=(${(s:,:)header})
    for normalized in ${(k)normalized_to_display}; do
        display_name="${normalized_to_display[$normalized]}"
        row="$display_name"

        for col in ${header_cols[@]:1}; do  # Skip first column (row key)
            # Find best value from all storage keys that normalize to this key
            local best_val="0"
            for storage_key in ${(k)row_keys_map}; do
                local sk_display="${storage_key//_/ }"
                local sk_normalized=$(echo "$sk_display" | sed 's/[-_ ,;:]//g' | tr '[:upper:]' '[:lower:]')
                if [[ "$sk_normalized" == "$normalized" ]]; then
                    local val="${CSV_DATA[$storage_key,$col]:-}"
                    # Prefer non-zero numeric values, or non-empty strings
                    if [[ -n "$val" && "$val" != "0" ]]; then
                        if [[ "$val" =~ ^[0-9]+$ && "$best_val" =~ ^[0-9]+$ ]]; then
                            # For numeric values, take the higher score
                            if [[ "$val" -gt "$best_val" ]]; then
                                best_val="$val"
                            fi
                        elif [[ "$best_val" == "0" || "$best_val" == "No submission" || "$best_val" == "No group submission" ]]; then
                            best_val="$val"
                        fi
                    fi
                fi
            done
            row="$row,$best_val"
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

    # Load previous CSV for score comparison (before clearing current data)
    PREVIOUS_CSV_DATA=()
    if [[ -f "$csvfile" ]]; then
        load_previous_csv "$csvfile"
    fi

    # Clear any existing CSV data (start fresh each run)
    CSV_DATA=()

    # Clear group membership data
    STUDENT_GROUP_MEMBERSHIP=()

    # Build header
    local header="Group ID,Group Members"
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
    local filename_names_spaces validation_warnings
    local processed_count total_count
    for submission_type in "${GROUP_SUBMISSIONS[@]}"; do
        echo "Checking $submission_type submissions..."

        submissions=$(find_group_submissions "$submission_type" "$year")
        processed_count=0

        if [[ -z "$submissions" ]]; then
            echo "  No submissions found"
            # Still check if there are files that weren't found due to pattern issues
            total_count=$(count_all_submissions "$submission_type" "$year")
            if [[ "$total_count" -gt 0 ]]; then
                echo -e "    ${YELLOW}WARNING: Submission count mismatch! Files in folder: $total_count, Processed: 0${NC}"
                echo "    Some files may have naming errors preventing discovery."
            fi
            continue
        fi

        # Use zsh array splitting to iterate (avoids here-string temp files)
        for filepath in ${(f)submissions}; do
            [[ -z "$filepath" ]] && continue

            filename=$(basename "$filepath")
            processed_count=$((processed_count + 1))

            if [[ -d "$filepath" ]]; then
                group_key=$(basename "$filepath")
            else
                group_key="${filename%.*}"
            fi
            group_key="${group_key#${year}-}"
            # Strip ALL known submission type suffixes from group key
            # This prevents "Khan-Liu-Peng-tests" from being treated as 4 names
            group_key=$(strip_submission_suffixes "$group_key")

            echo "  Found: $filename"

            # Validate group names and output warnings
            filename_names_spaces=$(echo "$group_key" | tr '-' ' ')
            validation_warnings=$(validate_group_names "$filepath" "$filename_names_spaces" "$submission_type")
            if [[ -n "$validation_warnings" ]]; then
                echo -e "$validation_warnings"
            fi

            result=$(evaluate_submission "$submission_type" "$filepath" "$year")
            score="${result%%|*}"
            notes="${result#*|}"

            # Convert group key to display format (space-separated)
            display_key=$(echo "$group_key" | tr '-' ' ')

            # Generate Group ID
            local group_id=$(normalize_group_id "$display_key" "$year")

            # Register all group members for later lookup (when copying scores to individuals)
            register_group_membership "$display_key"

            # Store with group_id as the key for the CSV (dashes, not underscores)
            local storage_key_for_group="${group_id}"
            found_groups[$storage_key_for_group]=1

            # Store Group ID column (the key itself)
            update_csv_value "$group_id" "Group ID" "$group_id"
            update_csv_value "$group_id" "$submission_type" "$score"
            update_csv_value "$group_id" "${submission_type}_notes" "$notes"
        done

        # Verify submission count matches
        total_count=$(count_all_submissions "$submission_type" "$year")
        if [[ "$processed_count" -ne "$total_count" ]]; then
            echo -e "    ${YELLOW}WARNING: Submission count mismatch! Files in folder: $total_count, Processed: $processed_count${NC}"
            echo "    Some files may have naming errors preventing discovery."
        fi

        echo ""
    done

    # Load full names for all groups from all submission types
    echo ""
    echo "Loading group member full names..."
    load_all_group_memberships "$BASE_DIR" "$year"
    echo "  Loaded full names for ${#GROUP_FULL_MEMBERS[@]} groups"

    # Set score 0 for groups with no submission for a type
    # Also count how many submission types each group has (to detect misplaced individuals)
    # found_groups keys are now Group IDs (like "2026-Chen-Chen-Liu")
    local group_id="" group_display="" group_key=""
    local -A group_submission_counts
    local total_group_types=${#GROUP_SUBMISSIONS[@]}

    for group_id in ${(k)found_groups}; do
        # Convert Group ID to display format (space-separated, no year)
        group_key="${group_id#*-}"  # Remove year prefix
        group_display="${group_key//-/ }"

        local submission_count=0
        for submission_type in "${GROUP_SUBMISSIONS[@]}"; do
            if [[ -z "${CSV_DATA[$group_id,$submission_type]:-}" ]]; then
                update_csv_value "$group_id" "$submission_type" "0"
                update_csv_value "$group_id" "${submission_type}_notes" "No submission"
            else
                # Count non-zero submissions
                local score_val="${CSV_DATA[$group_id,$submission_type]}"
                if [[ "$score_val" != "0" ]]; then
                    submission_count=$((submission_count + 1))
                fi
            fi
        done
        group_submission_counts[$group_id]=$submission_count

        # Store Group Members (with full names using & separator)
        local full_members="${GROUP_FULL_MEMBERS[$group_id]:-$group_display}"
        # Quote the full members list
        update_csv_value "$group_id" "Group Members" "\"$full_members\""
    done

    # Warn about potential misplaced individual submissions
    # If a "group" only has submissions for ≤2 types (missing from ≥6), likely an individual
    echo ""
    echo "Checking for potential misplaced individual submissions..."
    local misplaced_count=0
    for group_id in ${(k)found_groups}; do
        group_key="${group_id#*-}"
        group_display="${group_key//-/ }"
        local count=${group_submission_counts[$group_id]:-0}
        local missing_count=$((total_group_types - count))

        if [[ $missing_count -ge 6 ]]; then
            echo -e "    ${YELLOW}WARNING: '$group_display' only has $count of $total_group_types group submissions.${NC}"
            echo "    This may be an INDIVIDUAL submission misplaced in group folder."
            misplaced_count=$((misplaced_count + 1))
        fi
    done

    if [[ $misplaced_count -eq 0 ]]; then
        echo "  No misplaced submissions detected."
    fi

    # Write CSV
    echo ""
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

    # Load previous CSV for score comparison (before clearing current data)
    PREVIOUS_CSV_DATA=()
    if [[ -f "$csvfile" ]]; then
        load_previous_csv "$csvfile"
    fi

    # Clear any existing CSV data (start fresh each run)
    CSV_DATA=()

    # If STUDENT_GROUP_MEMBERSHIP is empty (e.g., running -i only), load from group CSV
    if [[ ${#STUDENT_GROUP_MEMBERSHIP[@]} -eq 0 && -f "$group_csvfile" ]]; then
        echo "Loading group membership from $group_csvfile..."
        # New format: Group ID is first column (YYYY-Family1-Family2-...)
        while IFS=',' read -r group_id group_members rest; do
            [[ "$group_id" == "Group ID" ]] && continue
            # Extract group key from Group ID (remove year prefix)
            local group_key="${group_id#*-}"
            group_key="${group_key//-/ }"
            register_group_membership "$group_key"
        done < "$group_csvfile"
        echo ""
    fi

    # Load full name mappings from all submission types (for accurate member matching)
    if [[ ${#STUDENT_FULL_NAME_TO_GROUP[@]} -eq 0 ]]; then
        echo "Loading full name mappings from submissions..."
        load_all_group_memberships "$BASE_DIR" "$year"
        echo "  Loaded ${#STUDENT_FULL_NAME_TO_GROUP[@]} full name mappings"
        echo ""
    fi

    # Build header - add Inconsistent_name column after Student Name
    local header="Name,Group ID,Inconsistent_name"
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

    # Track students using normalized keys for deduplication
    declare -A found_students          # normalized_key → 1
    declare -A student_canonical_name  # normalized_key → canonical display name
    declare -A student_groups          # canonical_name → group key
    declare -A inconsistent_names      # normalized_key → 1 if multiple spellings found

    # Declare loop variables (all at start to avoid zsh output issues)
    local submissions filepath filename result score notes base name_part family_name first_name student_key
    local group_members rest idx sub student student_family notes_idx
    local processed_count total_count
    local normalized_key canonical_name
    local -a values

    # Evaluate individual submissions
    for submission_type in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
        echo "Checking $submission_type submissions..."

        submissions=$(find_individual_submissions "$submission_type" "$year")
        processed_count=0

        if [[ -z "$submissions" ]]; then
            echo "  No submissions found"
            # Still check if there are files that weren't found due to pattern issues
            total_count=$(count_all_submissions "$submission_type" "$year")
            if [[ "$total_count" -gt 0 ]]; then
                echo -e "    ${YELLOW}WARNING: Submission count mismatch! Files in folder: $total_count, Processed: 0${NC}"
                echo "    Some files may have naming errors preventing discovery."
            fi
            continue
        fi

        # Use zsh array splitting to iterate (avoids here-string temp files)
        for filepath in ${(f)submissions}; do
            [[ -z "$filepath" ]] && continue

            filename=$(basename "$filepath")
            processed_count=$((processed_count + 1))
            echo "  Found: $filename"

            result=$(evaluate_submission "$submission_type" "$filepath" "$year")
            score="${result%%|*}"
            notes="${result#*|}"

            # Extract student name (strip submission suffixes like -report)
            base="${filename%.*}"
            name_part="${base#${year}-}"
            # Strip submission type suffixes before extracting names
            name_part=$(strip_submission_suffixes "$name_part")
            family_name="${name_part%%-*}"
            first_name="${name_part#*-}"
            student_key="$family_name $first_name"

            # Normalize for duplicate detection (removes all separators)
            normalized_key=$(normalize_student_key "$student_key")

            # Check if we've seen this student with different name spelling
            if [[ -n "${student_canonical_name[$normalized_key]:-}" ]]; then
                # Use the existing canonical name
                canonical_name="${student_canonical_name[$normalized_key]}"
                if [[ "$student_key" != "$canonical_name" ]]; then
                    echo "    (Merging with existing entry: $canonical_name)"
                    # Mark this student as having inconsistent name spellings
                    inconsistent_names[$normalized_key]=1
                fi
            else
                # First time seeing this student - use this as canonical name
                canonical_name="$student_key"
                student_canonical_name[$normalized_key]="$canonical_name"
            fi

            found_students[$normalized_key]=1
            update_csv_value "$canonical_name" "$submission_type" "$score"
            update_csv_value "$canonical_name" "${submission_type}_notes" "$notes"
        done

        # Verify submission count matches
        total_count=$(count_all_submissions "$submission_type" "$year")
        if [[ "$processed_count" -ne "$total_count" ]]; then
            echo -e "    ${YELLOW}WARNING: Submission count mismatch! Files in folder: $total_count, Processed: $processed_count${NC}"
            echo "    Some files may have naming errors preventing discovery."
        fi

        echo ""
    done

    # Load group CSV to copy group scores
    # Copy group scores to individual students based on actual group membership
    # Uses STUDENT_FULL_NAME_TO_GROUP which was populated from submissions
    if [[ -f "$group_csvfile" ]]; then
        echo "Copying group scores to individual students..."
        echo ""

        while IFS=',' read -r group_id group_members_quoted rest; do
            [[ "$group_id" == "Group ID" ]] && continue

            # Extract group key from Group ID (remove year prefix, convert dashes to spaces)
            local group_key="${group_id#*-}"
            group_key="${group_key//-/ }"

            # Remove quotes from group_members
            local group_members="${group_members_quoted//\"/}"

            # Use zsh array splitting (skip first 2 columns: Group ID, Group Members)
            values=(${(s:,:):-${group_id},${group_members_quoted},${rest}})

            # Parse the CSV line properly - scores start at column 3
            idx=0
            for sub in "${GROUP_SUBMISSIONS[@]}"; do
                idx=$((idx + 1))
                score="${values[$((idx+2))]:-0}"  # +2 because Group ID and Group Members are columns 1 and 2

                # Find notes column
                notes_idx=$((idx + 2 + ${#GROUP_SUBMISSIONS[@]}))
                notes="${values[$notes_idx]:-}"

                # Assign only to students who are actual members of this group
                for norm_key in ${(k)found_students}; do
                    canonical_name="${student_canonical_name[$norm_key]}"

                    # Use is_group_member with full name for accurate matching
                    if is_group_member "$canonical_name" "$group_key"; then
                        update_csv_value "$canonical_name" "$sub" "$score"
                        update_csv_value "$canonical_name" "${sub}_notes" "$notes"
                        student_groups[$canonical_name]=$group_key
                        # Store Group ID for this student
                        update_csv_value "$canonical_name" "Group ID" "$group_id"
                    fi
                done
            done
        done < "$group_csvfile"
    fi

    # Set score 0 for students with no submission and set Inconsistent_name flag
    local storage_key
    for norm_key in ${(k)found_students}; do
        canonical_name="${student_canonical_name[$norm_key]}"
        storage_key="${canonical_name// /_}"

        # Set Inconsistent_name flag (true if multiple spellings were found)
        if [[ -n "${inconsistent_names[$norm_key]:-}" ]]; then
            update_csv_value "$canonical_name" "Inconsistent_name" "true"
        else
            update_csv_value "$canonical_name" "Inconsistent_name" "0"
        fi

        for submission_type in "${INDIVIDUAL_SUBMISSIONS[@]}"; do
            if [[ -z "${CSV_DATA[$storage_key,$submission_type]:-}" ]]; then
                update_csv_value "$canonical_name" "$submission_type" "0"
                update_csv_value "$canonical_name" "${submission_type}_notes" "No submission"
            fi
        done
        for submission_type in "${GROUP_SUBMISSIONS[@]}"; do
            if [[ -z "${CSV_DATA[$storage_key,$submission_type]:-}" ]]; then
                update_csv_value "$canonical_name" "$submission_type" "0"
                update_csv_value "$canonical_name" "${submission_type}_notes" "No group submission"
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
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --cookies-from-browser)
                COOKIES_FROM_BROWSER="$2"
                shift 2
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

    # Check for jq (needed for parsing video metadata JSON)
    if ! command -v jq &>/dev/null; then
        echo -e "${RED}ERROR: jq not found. Required for video metadata parsing.${NC}"
        echo "      Install jq:"
        echo "        macOS:  brew install jq"
        echo "        Linux:  sudo apt install jq"
        echo ""
        exit 1
    fi

    # Check for yt-dlp (needed for video metadata checks)
    if ! command -v yt-dlp &>/dev/null; then
        echo -e "${YELLOW}NOTE: yt-dlp not found. Video checks (duration, resolution, subtitles) will be skipped.${NC}"
        echo "      Install yt-dlp for full video evaluation:"
        echo "        macOS:  brew install yt-dlp"
        echo "        Linux:  pip install yt-dlp  OR  sudo apt install yt-dlp"
        echo ""
    else
        # Check for PO token provider (speeds up YouTube API access significantly)
        if ! is_bgutil_pot_provider_available; then
            echo -e "${YELLOW}NOTE: bgutil-ytdlp-pot-provider not running. YouTube checks may be slow.${NC}"
            echo "      Setup PO token provider (one-time):"
            echo "        curl -fsSL https://github.com/Brainicism/bgutil-ytdlp-pot-provider/releases/download/1.2.2/bgutil-ytdlp-pot-provider.zip -o ~/.config/yt-dlp/plugins/bgutil-ytdlp-pot-provider.zip"
            echo "        docker pull brainicism/bgutil-ytdlp-pot-provider"
            echo "      Start server before running:"
            echo "        docker run --name bgutil-provider -d -p 4416:4416 --init brainicism/bgutil-ytdlp-pot-provider"
            echo ""
        fi
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
        cleanup_tmp
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

    # Clean up temp directory on successful completion
    cleanup_tmp
}

main "$@"
