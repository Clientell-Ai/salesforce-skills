#!/usr/bin/env bash
# static-checks.sh — Regex-based Salesforce code quality checks
#
# Scans Apex code for common Salesforce anti-patterns without needing an LLM.
# Returns a score and details.
#
# Usage:
#   bash static-checks.sh <file.cls>           # Check a single file
#   bash static-checks.sh <directory>           # Check all .cls files in directory
#   bash static-checks.sh --format json <file>  # JSON output
#   bash static-checks.sh --help
#
# Exit codes:
#   0 — All checks passed
#   1 — Some checks failed
#   2 — Usage error

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FORMAT="text"
CHECK_DETAIL=""

usage() {
    echo "Usage: bash static-checks.sh [--format text|json] <file.cls|directory>"
    echo ""
    echo "Checks Apex code for Salesforce anti-patterns:"
    echo "  1. SOQL inside loops"
    echo "  2. DML inside loops"
    echo "  3. Missing 'with sharing'"
    echo "  4. Missing WITH USER_MODE"
    echo "  5. Missing Security.stripInaccessible"
    echo "  6. Hardcoded Salesforce IDs"
    echo "  7. Direct SOQL string concatenation (injection risk)"
    echo "  8. Trigger with business logic (no handler)"
    echo "  9. Debug statements with sensitive fields"
    echo " 10. Missing null checks on SOQL results"
    exit 0
}

# Check functions — each returns 0 (pass) or 1 (fail)
# and sets CHECK_DETAIL with finding details

check_soql_in_loop() {
    local file="$1"
    CHECK_DETAIL=""
    # Look for [SELECT inside for/while/do blocks
    # Simple heuristic: find lines with SELECT that are inside a loop context
    local findings
    findings=$(awk '
        /\b(for|while|do)\s*\(/ { in_loop++; loop_line=NR }
        /\bSELECT\b/ { if (in_loop > 0) print NR": "$0 }
        /\}/ { if (in_loop > 0) in_loop-- }
    ' "$file" 2>/dev/null || true)

    if [ -n "$findings" ]; then
        CHECK_DETAIL="SOQL query found inside loop:\n$findings"
        return 1
    fi
    return 0
}

check_dml_in_loop() {
    local file="$1"
    CHECK_DETAIL=""
    local findings
    findings=$(awk '
        /\b(for|while|do)\s*\(/ { in_loop++; loop_line=NR }
        /\b(insert|update|delete|upsert|undelete)\s+[a-zA-Z]/ {
            if (in_loop > 0 && !/Database\.(insert|update|delete|upsert)/) print NR": "$0
        }
        /\bDatabase\.(insert|update|delete|upsert)\b/ {
            if (in_loop > 0) print NR": "$0
        }
        /\}/ { if (in_loop > 0) in_loop-- }
    ' "$file" 2>/dev/null || true)

    if [ -n "$findings" ]; then
        CHECK_DETAIL="DML operation found inside loop:\n$findings"
        return 1
    fi
    return 0
}

check_with_sharing() {
    local file="$1"
    CHECK_DETAIL=""
    # Skip test classes and interfaces
    if grep -q "@IsTest\|@isTest" "$file" 2>/dev/null; then
        return 0
    fi
    if grep -q "\binterface\b" "$file" 2>/dev/null; then
        return 0
    fi
    # Check for class declaration without sharing keyword
    local classes_without
    classes_without=$(grep -n "public\s\+\(virtual\s\+\|abstract\s\+\|global\s\+\)\?class\b" "$file" 2>/dev/null | grep -v "with sharing\|without sharing\|inherited sharing" || true)

    if [ -n "$classes_without" ]; then
        CHECK_DETAIL="Class declared without sharing keyword:\n$classes_without"
        return 1
    fi
    return 0
}

check_user_mode() {
    local file="$1"
    CHECK_DETAIL=""
    # Check if file has SOQL queries
    local has_soql
    has_soql=$(grep -cE "\[SELECT|Database\.query" "$file" 2>/dev/null || true)
    has_soql="${has_soql:-0}"
    if [ "$has_soql" -eq 0 ]; then
        return 0  # No queries, nothing to check
    fi

    local has_user_mode
    has_user_mode=$(grep -cE "WITH USER_MODE|WITH SECURITY_ENFORCED|AccessLevel\.USER_MODE" "$file" 2>/dev/null || true)
    has_user_mode="${has_user_mode:-0}"

    if [ "$has_user_mode" -eq 0 ]; then
        CHECK_DETAIL="File has $has_soql SOQL queries but no WITH USER_MODE or AccessLevel.USER_MODE"
        return 1
    fi
    return 0
}

check_strip_inaccessible() {
    local file="$1"
    CHECK_DETAIL=""
    # Check if file has DML operations
    local has_dml
    has_dml=$(grep -cE "(insert|update|upsert)\s+[a-zA-Z]|Database\.(insert|update|upsert)" "$file" 2>/dev/null || true)
    has_dml="${has_dml:-0}"
    if [ "$has_dml" -eq 0 ]; then
        return 0
    fi

    local has_strip
    has_strip=$(grep -cE "stripInaccessible|AccessLevel\.USER_MODE|AccessLevel\.SYSTEM_MODE" "$file" 2>/dev/null || true)
    has_strip="${has_strip:-0}"

    if [ "$has_strip" -eq 0 ]; then
        CHECK_DETAIL="File has $has_dml DML operations but no stripInaccessible() or AccessLevel.USER_MODE"
        return 1
    fi
    return 0
}

check_hardcoded_ids() {
    local file="$1"
    CHECK_DETAIL=""
    # Match 15 or 18 character Salesforce IDs (start with 3-char prefix like 001, 005, etc.)
    local findings
    findings=$(grep -nE "'[0-9a-zA-Z]{15}'|'[0-9a-zA-Z]{18}'" "$file" 2>/dev/null | grep -E "'[0][0-9a-zA-Z]{14}'|'[0][0-9a-zA-Z]{17}'" || true)

    if [ -n "$findings" ]; then
        CHECK_DETAIL="Possible hardcoded Salesforce IDs:\n$findings"
        return 1
    fi
    return 0
}

check_soql_injection() {
    local file="$1"
    CHECK_DETAIL=""
    # Look for string concatenation in SOQL-like contexts
    local findings
    findings=$(grep -n "'SELECT.*'\s*+" "$file" 2>/dev/null || true)
    findings+=$(grep -n "+\s*'.*WHERE" "$file" 2>/dev/null || true)
    findings+=$(grep -n "'\s*+\s*[a-zA-Z]*\s*+\s*'" "$file" 2>/dev/null | grep -i "SELECT\|WHERE\|FROM\|AND\|OR" || true)

    if [ -n "$findings" ]; then
        CHECK_DETAIL="Possible SOQL injection (string concatenation in query):\n$findings"
        return 1
    fi
    return 0
}

check_trigger_logic() {
    local file="$1"
    CHECK_DETAIL=""
    # Check if this is a trigger file with business logic
    if ! grep -q "^trigger\b" "$file" 2>/dev/null; then
        return 0  # Not a trigger file
    fi

    # Count lines of code in trigger (excluding whitespace and comments)
    local code_lines
    code_lines=$(grep -v "^\s*$\|^\s*//\|^\s*\*" "$file" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$code_lines" -gt 15 ]; then
        CHECK_DETAIL="Trigger has $code_lines lines of code — should delegate to handler class"
        return 1
    fi
    return 0
}

check_sensitive_debug() {
    local file="$1"
    CHECK_DETAIL=""
    local findings
    findings=$(grep -niE "System\.debug.*\.(SSN|Password|Secret|Token|CardNumber|CreditCard|password|secret|token)" "$file" 2>/dev/null || true)

    if [ -n "$findings" ]; then
        CHECK_DETAIL="Debug statements may expose sensitive data:\n$findings"
        return 1
    fi
    return 0
}

check_null_safety() {
    local file="$1"
    CHECK_DETAIL=""
    # Look for SOQL query assigned to single record without null check or LIMIT
    local findings
    findings=$(grep -n "\] =" "$file" 2>/dev/null | grep "SELECT" | grep -v "List<\|new List\|LIMIT" || true)

    # This is a soft check — many patterns are valid
    if [ -n "$findings" ]; then
        local has_null_check
        has_null_check=$(grep -cE "!= null|\.isEmpty\(\)|\.size\(\)" "$file" 2>/dev/null || true)
        has_null_check="${has_null_check:-0}"
        if [ "$has_null_check" -eq 0 ]; then
            CHECK_DETAIL="Query results used without null/empty checks"
            return 1
        fi
    fi
    return 0
}

# Run all checks on a file
check_file() {
    local file="$1"
    local passed=0
    local failed=0
    local total=10
    local results=()

    local checks=(
        "check_soql_in_loop:No SOQL in loops"
        "check_dml_in_loop:No DML in loops"
        "check_with_sharing:Uses 'with sharing'"
        "check_user_mode:Has WITH USER_MODE"
        "check_strip_inaccessible:Has stripInaccessible/AccessLevel"
        "check_hardcoded_ids:No hardcoded IDs"
        "check_soql_injection:No SOQL injection risk"
        "check_trigger_logic:Trigger delegates to handler"
        "check_sensitive_debug:No sensitive data in debug"
        "check_null_safety:Null-safe SOQL results"
    )

    for check_entry in "${checks[@]}"; do
        local func="${check_entry%%:*}"
        local label="${check_entry#*:}"

        CHECK_DETAIL=""
        if $func "$file"; then
            passed=$((passed + 1))
            results+=("PASS|$label|")
        else
            failed=$((failed + 1))
            results+=("FAIL|$label|$CHECK_DETAIL")
        fi
    done

    if [ "$FORMAT" = "json" ]; then
        local json_results="["
        local first=true
        for r in "${results[@]}"; do
            local status="${r%%|*}"
            local rest="${r#*|}"
            local label="${rest%%|*}"
            local detail="${rest#*|}"
            if [ "$first" = true ]; then first=false; else json_results+=","; fi
            json_results+="{\"status\":\"$status\",\"check\":\"$label\",\"detail\":\"$(echo "$detail" | tr '\n' ' ' | sed 's/"/\\"/g')\"}"
        done
        json_results+="]"

        jq -n \
            --arg file "$(basename "$file")" \
            --argjson passed "$passed" \
            --argjson failed "$failed" \
            --argjson total "$total" \
            --argjson results "$json_results" \
            '{file: $file, passed: $passed, failed: $failed, total: $total, score: "\($passed)/\($total)", results: $results}'
    else
        echo -e "${BLUE}━━━ $(basename "$file") ━━━${NC}"
        for r in "${results[@]}"; do
            local status="${r%%|*}"
            local rest="${r#*|}"
            local label="${rest%%|*}"
            local detail="${rest#*|}"

            if [ "$status" = "PASS" ]; then
                echo -e "  ${GREEN}✓${NC} $label"
            else
                echo -e "  ${RED}✗${NC} $label"
                if [ -n "$detail" ]; then
                    echo -e "    ${YELLOW}→ $(echo -e "$detail" | head -1)${NC}"
                fi
            fi
        done
        echo -e "\n  Score: ${GREEN}$passed${NC}/${total} checks passed"
        if [ "$failed" -gt 0 ]; then
            echo -e "  ${RED}$failed issue(s) found${NC}"
        else
            echo -e "  ${GREEN}All checks passed!${NC}"
        fi
        echo ""
    fi

    return "$failed"
}

# ─── Main ───

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) usage ;;
        --format) FORMAT="$2"; shift 2 ;;
        *) break ;;
    esac
done

if [ $# -eq 0 ]; then
    echo "Error: No file or directory specified."
    echo ""
    usage
fi

TARGET="$1"
EXIT_CODE=0

if [ -d "$TARGET" ]; then
    # Check all .cls files in directory
    found=false
    for cls_file in "$TARGET"/*.cls; do
        [ -f "$cls_file" ] || continue
        found=true
        check_file "$cls_file" || EXIT_CODE=1
    done
    if [ "$found" = false ]; then
        echo "No .cls files found in $TARGET"
        exit 2
    fi
elif [ -f "$TARGET" ]; then
    check_file "$TARGET" || EXIT_CODE=1
else
    echo "Error: '$TARGET' is not a file or directory."
    exit 2
fi

exit "$EXIT_CODE"
