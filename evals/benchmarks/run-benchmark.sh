#!/usr/bin/env bash
# run-benchmark.sh — Evaluate Salesforce skills quality with LLM-as-judge
#
# Compares AI-generated code WITH vs WITHOUT skill context.
# Uses Claude API to generate code and score it.
#
# Usage:
#   export ANTHROPIC_API_KEY="sk-ant-..."
#   bash run-benchmark.sh                    # Run all tasks
#   bash run-benchmark.sh --task apex-trigger-bulk  # Run single task
#   bash run-benchmark.sh --dry-run          # Show what would run (no API calls)
#   bash run-benchmark.sh --judge-only       # Re-score existing outputs
#   bash run-benchmark.sh --help
#
# Requirements:
#   - curl, jq
#   - ANTHROPIC_API_KEY environment variable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TASKS_FILE="$SCRIPT_DIR/tasks.json"
JUDGE_PROMPT_FILE="$SCRIPT_DIR/judge-prompt.md"
RESULTS_DIR="$SCRIPT_DIR/results"
MODEL="${BENCHMARK_MODEL:-claude-sonnet-4-20250514}"
JUDGE_MODEL="${JUDGE_MODEL:-claude-sonnet-4-20250514}"
MAX_TOKENS=4096

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: bash run-benchmark.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --task <id>      Run a single task by ID"
    echo "  --dry-run        Show tasks without making API calls"
    echo "  --judge-only     Re-score existing outputs (skip generation)"
    echo "  --model <name>   Model for code generation (default: $MODEL)"
    echo "  --help           Show this help"
    echo ""
    echo "Environment:"
    echo "  ANTHROPIC_API_KEY    Required. Your Anthropic API key."
    echo "  BENCHMARK_MODEL     Optional. Override generation model."
    echo "  JUDGE_MODEL         Optional. Override judge model."
    exit 0
}

check_deps() {
    for cmd in curl jq; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}Error: '$cmd' is required but not installed.${NC}"
            exit 1
        fi
    done
    if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
        echo -e "${RED}Error: ANTHROPIC_API_KEY environment variable is not set.${NC}"
        echo "  export ANTHROPIC_API_KEY=\"sk-ant-...\""
        exit 1
    fi
}

# Call Claude API
# Args: $1 = system prompt (or empty), $2 = user prompt, $3 = output file
call_claude() {
    local system_prompt="$1"
    local user_prompt="$2"
    local output_file="$3"
    local model="${4:-$MODEL}"

    local payload
    if [ -n "$system_prompt" ]; then
        payload=$(jq -n \
            --arg model "$model" \
            --argjson max_tokens "$MAX_TOKENS" \
            --arg system "$system_prompt" \
            --arg user "$user_prompt" \
            '{
                model: $model,
                max_tokens: $max_tokens,
                system: $system,
                messages: [{ role: "user", content: $user }]
            }')
    else
        payload=$(jq -n \
            --arg model "$model" \
            --argjson max_tokens "$MAX_TOKENS" \
            --arg user "$user_prompt" \
            '{
                model: $model,
                max_tokens: $max_tokens,
                messages: [{ role: "user", content: $user }]
            }')
    fi

    local response
    response=$(curl -s -w "\n%{http_code}" \
        https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "$payload")

    local http_code
    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" != "200" ]; then
        echo -e "${RED}API error (HTTP $http_code):${NC}"
        echo "$body" | jq -r '.error.message // .' 2>/dev/null || echo "$body"
        return 1
    fi

    # Extract text content
    echo "$body" | jq -r '.content[0].text' > "$output_file"
}

# Load skill context for a given skill name
get_skill_context() {
    local skill="$1"
    local skill_file="$REPO_ROOT/skills/$skill/SKILL.md"
    if [ -f "$skill_file" ]; then
        cat "$skill_file"
    else
        echo ""
    fi
}

# Run a single benchmark task
run_task() {
    local task_id="$1"
    local task_json="$2"

    local prompt skill
    prompt=$(echo "$task_json" | jq -r '.prompt')
    skill=$(echo "$task_json" | jq -r '.skill')

    local task_dir="$RESULTS_DIR/$task_id"
    mkdir -p "$task_dir"

    echo -e "${BLUE}━━━ Task: $task_id (skill: $skill) ━━━${NC}"

    # Step 1: Generate baseline (no skill context)
    if [ "$JUDGE_ONLY" = false ]; then
        echo -e "  ${YELLOW}[1/3]${NC} Generating baseline (no skills)..."
        call_claude "" "$prompt" "$task_dir/baseline.txt"
        echo -e "  ${GREEN}  ✓${NC} Saved baseline.txt"

        # Step 2: Generate with skill context
        echo -e "  ${YELLOW}[2/3]${NC} Generating with skill context..."
        local skill_context
        skill_context=$(get_skill_context "$skill")
        local system_with_skill="You are a Salesforce development expert. Follow ALL instructions in the skill context below precisely.

--- SKILL CONTEXT ---
$skill_context
--- END SKILL CONTEXT ---"
        call_claude "$system_with_skill" "$prompt" "$task_dir/with-skill.txt"
        echo -e "  ${GREEN}  ✓${NC} Saved with-skill.txt"
    else
        echo -e "  ${YELLOW}[skip]${NC} Using existing outputs (--judge-only)"
        if [ ! -f "$task_dir/baseline.txt" ] || [ ! -f "$task_dir/with-skill.txt" ]; then
            echo -e "  ${RED}  ✗ Missing output files, cannot judge${NC}"
            return 1
        fi
    fi

    # Step 3: Judge both outputs
    echo -e "  ${YELLOW}[3/3]${NC} Scoring with LLM judge..."
    local baseline_code with_skill_code judge_system judge_user
    baseline_code=$(cat "$task_dir/baseline.txt")
    with_skill_code=$(cat "$task_dir/with-skill.txt")

    # Extract judge system prompt from the markdown file (between ``` fences)
    judge_system=$(sed -n '/^```$/,/^```$/p' "$JUDGE_PROMPT_FILE" | sed '1d;$d')

    judge_user="## TASK
$prompt

## CODE SAMPLE A (baseline — no skill context)
$baseline_code

## CODE SAMPLE B (with-skill — Salesforce skill context provided)
$with_skill_code"

    call_claude "$judge_system" "$judge_user" "$task_dir/scores.json" "$JUDGE_MODEL"

    # Validate JSON
    if jq empty "$task_dir/scores.json" 2>/dev/null; then
        local score_a score_b improvement
        score_a=$(jq -r '.sample_a.total' "$task_dir/scores.json")
        score_b=$(jq -r '.sample_b.total' "$task_dir/scores.json")
        improvement=$((score_b - score_a))
        echo -e "  ${GREEN}  ✓${NC} Baseline: ${RED}$score_a/25${NC} | With Skills: ${GREEN}$score_b/25${NC} | Δ: ${BLUE}+$improvement${NC}"
    else
        echo -e "  ${RED}  ✗ Judge returned invalid JSON, saved raw output${NC}"
    fi

    echo ""
}

# Generate aggregate report
generate_report() {
    echo -e "${BLUE}━━━ Generating Report ━━━${NC}"

    local report="$RESULTS_DIR/report.md"
    local total_baseline=0 total_skill=0 task_count=0

    cat > "$report" << 'HEADER'
# Salesforce Skills Benchmark Report

Comparison of AI-generated Salesforce code **with** vs **without** skill context.

| Task | Skill | Baseline (no skills) | With Skills | Improvement |
|------|-------|---------------------|-------------|-------------|
HEADER

    for task_dir in "$RESULTS_DIR"/*/; do
        local task_id scores_file
        task_id=$(basename "$task_dir")
        scores_file="$task_dir/scores.json"

        [ "$task_id" = "results" ] && continue
        [ ! -f "$scores_file" ] && continue
        ! jq empty "$scores_file" 2>/dev/null && continue

        local score_a score_b improvement skill summary
        score_a=$(jq -r '.sample_a.total' "$scores_file")
        score_b=$(jq -r '.sample_b.total' "$scores_file")
        improvement=$((score_b - score_a))

        # Get skill from tasks.json
        skill=$(jq -r --arg id "$task_id" '.[] | select(.id == $id) | .skill' "$TASKS_FILE" 2>/dev/null || echo "?")

        local pct=""
        if [ "$score_a" -gt 0 ]; then
            pct=$(( (improvement * 100) / score_a ))
            pct=" (+${pct}%)"
        fi

        echo "| \`$task_id\` | $skill | $score_a/25 | $score_b/25 | +$improvement$pct |" >> "$report"

        total_baseline=$((total_baseline + score_a))
        total_skill=$((total_skill + score_b))
        task_count=$((task_count + 1))
    done

    if [ "$task_count" -gt 0 ]; then
        local avg_baseline avg_skill avg_improvement avg_pct
        avg_baseline=$((total_baseline / task_count))
        avg_skill=$((total_skill / task_count))
        avg_improvement=$((avg_skill - avg_baseline))
        if [ "$avg_baseline" -gt 0 ]; then
            avg_pct=$(( (avg_improvement * 100) / avg_baseline ))
        else
            avg_pct=0
        fi

        cat >> "$report" << EOF
| **Average** | | **$avg_baseline/25** | **$avg_skill/25** | **+$avg_improvement (+${avg_pct}%)** |

## Summary

- **Tasks evaluated**: $task_count
- **Average baseline score**: $avg_baseline/25 ($((avg_baseline * 100 / 25))%)
- **Average with-skills score**: $avg_skill/25 ($((avg_skill * 100 / 25))%)
- **Average improvement**: +$avg_improvement points (+${avg_pct}%)
- **Model**: $MODEL (generation), $JUDGE_MODEL (judge)
- **Date**: $(date -u +"%Y-%m-%d %H:%M UTC")

## Category Breakdown

See individual \`results/<task-id>/scores.json\` files for per-category scores.
EOF
    fi

    echo -e "${GREEN}Report saved to: $report${NC}"
}

# ─── Main ───

DRY_RUN=false
JUDGE_ONLY=false
SINGLE_TASK=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) usage ;;
        --dry-run) DRY_RUN=true; shift ;;
        --judge-only) JUDGE_ONLY=true; shift ;;
        --task) SINGLE_TASK="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Salesforce Skills Quality Benchmark     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "  Model:  $MODEL"
echo "  Judge:  $JUDGE_MODEL"
echo "  Tasks:  $TASKS_FILE"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN — no API calls will be made${NC}"
    echo ""
    jq -r '.[] | "  [\(.id)] \(.skill): \(.prompt[:80])..."' "$TASKS_FILE"
    echo ""
    echo "Total tasks: $(jq length "$TASKS_FILE")"
    exit 0
fi

check_deps
mkdir -p "$RESULTS_DIR"

# Run tasks
if [ -n "$SINGLE_TASK" ]; then
    task_json=$(jq -r --arg id "$SINGLE_TASK" '.[] | select(.id == $id)' "$TASKS_FILE")
    if [ -z "$task_json" ]; then
        echo -e "${RED}Task '$SINGLE_TASK' not found in tasks.json${NC}"
        exit 1
    fi
    run_task "$SINGLE_TASK" "$task_json"
else
    task_count=$(jq length "$TASKS_FILE")
    current=0
    for task_id in $(jq -r '.[].id' "$TASKS_FILE"); do
        current=$((current + 1))
        task_json=$(jq -r --arg id "$task_id" '.[] | select(.id == $id)' "$TASKS_FILE")
        echo -e "${YELLOW}[$current/$task_count]${NC}"
        run_task "$task_id" "$task_json"
    done
fi

generate_report

echo -e "${GREEN}Done!${NC} Results in: $RESULTS_DIR/"
