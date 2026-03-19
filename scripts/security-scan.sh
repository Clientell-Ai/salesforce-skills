#!/bin/bash
# Quick security scan for common Salesforce Apex vulnerabilities
#
# Usage: ./scripts/security-scan.sh [options] [source-dir]
#
# Options:
#   --help          Show this help message
#   --format TEXT   Output format: text (default) or json
#
# Exit codes:
#   0 — No issues found
#   1 — Issues found
#   2 — Invalid arguments

set -euo pipefail

FORMAT="text"
SOURCE_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            sed -n '2,11p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        --format)
            FORMAT="${2:-text}"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
        *)
            SOURCE_DIR="$1"
            shift
            ;;
    esac
done

SOURCE_DIR="${SOURCE_DIR:-force-app/main/default}"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Directory not found: $SOURCE_DIR" >&2
    exit 2
fi

# Collect findings
declare -a FINDINGS=()

add_finding() {
    local severity="$1" category="$2" file="$3" line="$4" message="$5"
    FINDINGS+=("${severity}|${category}|${file}|${line}|${message}")
}

echo "Scanning: $SOURCE_DIR" >&2

# Check for classes without 'with sharing'
while IFS= read -r file; do
    if ! grep -q "with sharing\|without sharing\|inherited sharing" "$file" 2>/dev/null; then
        add_finding "HIGH" "missing-sharing" "$file" "1" "Class without sharing declaration"
    fi
done < <(grep -rln "public class\|public virtual class\|public abstract class\|global class" "$SOURCE_DIR" --include="*.cls" 2>/dev/null || true)

# Check for SOQL without USER_MODE
while IFS=: read -r file line content; do
    add_finding "HIGH" "missing-user-mode" "$file" "$line" "SOQL query without WITH USER_MODE"
done < <(grep -rn "\[SELECT" "$SOURCE_DIR" --include="*.cls" 2>/dev/null | grep -v "USER_MODE" | grep -v "@IsTest\|Test" | head -50 || true)

# Check for string concatenation in SOQL
while IFS=: read -r file line content; do
    add_finding "CRITICAL" "soql-injection" "$file" "$line" "Potential SOQL injection via string concatenation"
done < <(grep -rn "'SELECT.*'" "$SOURCE_DIR" --include="*.cls" 2>/dev/null | grep "+" | head -50 || true)

# Check for DML without stripInaccessible
while IFS=: read -r file line content; do
    add_finding "CRITICAL" "missing-crud-fls" "$file" "$line" "DML without CRUD/FLS check"
done < <(grep -rn "^\s*insert \|^\s*update \|^\s*delete \|^\s*upsert " "$SOURCE_DIR" --include="*.cls" 2>/dev/null | grep -v "stripInaccessible\|Database\.\|Test\|@IsTest" | head -50 || true)

# Check for debug statements with sensitive fields
while IFS=: read -r file line content; do
    add_finding "MEDIUM" "pii-in-debug" "$file" "$line" "Debug statement may expose sensitive data"
done < <(grep -rn "System.debug.*\(.*Password\|SSN\|Secret\|Token\|CardNumber\|CreditCard\)" "$SOURCE_DIR" --include="*.cls" 2>/dev/null | head -20 || true)

# Check for hardcoded endpoints
while IFS=: read -r file line content; do
    add_finding "HIGH" "hardcoded-endpoint" "$file" "$line" "Hardcoded endpoint — use Named Credentials"
done < <(grep -rn "setEndpoint.*https\?://" "$SOURCE_DIR" --include="*.cls" 2>/dev/null | grep -v "callout:" | head -20 || true)

# Count by severity
CRITICAL=0 HIGH=0 MEDIUM=0
for f in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
    case "${f%%|*}" in
        CRITICAL) CRITICAL=$((CRITICAL + 1)) ;;
        HIGH) HIGH=$((HIGH + 1)) ;;
        MEDIUM) MEDIUM=$((MEDIUM + 1)) ;;
    esac
done
TOTAL=${#FINDINGS[@]}

# Output
if [ "$FORMAT" = "json" ]; then
    echo "{"
    echo "  \"source\": \"$SOURCE_DIR\","
    echo "  \"total\": $TOTAL,"
    echo "  \"critical\": $CRITICAL,"
    echo "  \"high\": $HIGH,"
    echo "  \"medium\": $MEDIUM,"
    echo "  \"pass\": $([ $CRITICAL -eq 0 ] && [ $HIGH -eq 0 ] && echo "true" || echo "false"),"
    echo "  \"findings\": ["
    first=true
    for f in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
        IFS='|' read -r severity category file line message <<< "$f"
        [ "$first" = true ] && first=false || echo ","
        printf '    {"severity": "%s", "category": "%s", "file": "%s", "line": "%s", "message": "%s"}' \
            "$severity" "$category" "$file" "$line" "$message"
    done
    echo ""
    echo "  ]"
    echo "}"
else
    echo ""
    echo "Security Scan Results: $SOURCE_DIR"
    echo "================================================"
    for f in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
        IFS='|' read -r severity category file line message <<< "$f"
        echo "[$severity] $file:$line — $message"
    done
    echo ""
    echo "================================================"
    echo "Critical: $CRITICAL | High: $HIGH | Medium: $MEDIUM | Total: $TOTAL"
    if [ $CRITICAL -eq 0 ] && [ $HIGH -eq 0 ]; then
        echo "Result: PASS (AppExchange review ready)"
    else
        echo "Result: FAIL (fix critical/high issues before review)"
    fi
fi

[ $TOTAL -gt 0 ] && exit 1 || exit 0
