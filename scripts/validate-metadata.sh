#!/bin/bash
# Validate Salesforce metadata structure and conventions
#
# Usage: ./scripts/validate-metadata.sh [options] [source-dir]
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

declare -a FINDINGS=()

add_finding() {
    local severity="$1" category="$2" file="$3" message="$4"
    FINDINGS+=("${severity}|${category}|${file}|${message}")
}

echo "Validating: $SOURCE_DIR" >&2

# Check Apex classes have meta.xml companions
for cls in $(find "$SOURCE_DIR" -name "*.cls" 2>/dev/null); do
    meta="${cls}-meta.xml"
    if [ ! -f "$meta" ]; then
        add_finding "ERROR" "missing-meta" "$cls" "Missing companion ${meta##*/}"
    fi
done

# Check LWC bundles have js-meta.xml
for js in $(find "$SOURCE_DIR/lwc" -maxdepth 2 -name "*.js" ! -name "*.test.js" ! -path "*__tests__*" 2>/dev/null); do
    dir=$(dirname "$js")
    component=$(basename "$dir")
    meta="$dir/${component}.js-meta.xml"
    if [ ! -f "$meta" ]; then
        add_finding "ERROR" "missing-lwc-meta" "$js" "Missing LWC metadata ${component}.js-meta.xml"
    fi
done

# Check for hardcoded IDs in Apex
while IFS=: read -r file line content; do
    add_finding "WARNING" "hardcoded-id" "$file:$line" "Possible hardcoded Salesforce ID"
done < <(grep -rn "['\"][0-9a-zA-Z]\{15,18\}['\"]" "$SOURCE_DIR" --include="*.cls" 2>/dev/null | head -50 || true)

# Check API version consistency
versions=$(grep -rh "<apiVersion>" "$SOURCE_DIR" --include="*-meta.xml" 2>/dev/null | sort -u || true)
version_count=$(echo "$versions" | grep -c "apiVersion" || true)
if [ "$version_count" -gt 1 ]; then
    add_finding "WARNING" "api-version-mismatch" "$SOURCE_DIR" "Multiple API versions: $(echo $versions | tr '\n' ' ')"
fi

# Count
ERRORS=0 WARNINGS=0
for f in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
    case "${f%%|*}" in
        ERROR) ERRORS=$((ERRORS + 1)) ;;
        WARNING) WARNINGS=$((WARNINGS + 1)) ;;
    esac
done
TOTAL=${#FINDINGS[@]}

# Output
if [ "$FORMAT" = "json" ]; then
    echo "{"
    echo "  \"source\": \"$SOURCE_DIR\","
    echo "  \"total\": $TOTAL,"
    echo "  \"errors\": $ERRORS,"
    echo "  \"warnings\": $WARNINGS,"
    echo "  \"pass\": $([ $ERRORS -eq 0 ] && echo "true" || echo "false"),"
    echo "  \"findings\": ["
    first=true
    for f in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
        IFS='|' read -r severity category file message <<< "$f"
        [ "$first" = true ] && first=false || echo ","
        printf '    {"severity": "%s", "category": "%s", "file": "%s", "message": "%s"}' \
            "$severity" "$category" "$file" "$message"
    done
    echo ""
    echo "  ]"
    echo "}"
else
    echo ""
    echo "Metadata Validation: $SOURCE_DIR"
    echo "================================================"
    for f in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
        IFS='|' read -r severity category file message <<< "$f"
        echo "[$severity] $file — $message"
    done
    echo ""
    echo "================================================"
    echo "Errors: $ERRORS | Warnings: $WARNINGS | Total: $TOTAL"
    if [ $ERRORS -eq 0 ]; then
        echo "Result: PASS"
    else
        echo "Result: FAIL (fix errors before deployment)"
    fi
fi

[ $ERRORS -gt 0 ] && exit 1 || exit 0
