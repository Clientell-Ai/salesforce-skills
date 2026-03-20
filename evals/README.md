# Skill Evaluation Framework

Three-layer evaluation system to measure skill activation accuracy and code quality improvement.

## Quick Start (Claude Code)

```bash
# Run the full benchmark (compares with vs without skills)
/sf-eval

# Run a single benchmark task
/sf-eval apex-trigger-bulk

# Check your own Apex code quality
/sf-eval --check MyClass.cls
```

## Quick Start (Shell)

```bash
# Static checks (no LLM, instant)
bash evals/checks/static-checks.sh MyClass.cls

# Full benchmark (requires API key)
export ANTHROPIC_API_KEY="sk-ant-..."
bash evals/benchmarks/run-benchmark.sh
```

## Committed Results

See [BENCHMARK.md](benchmarks/results/BENCHMARK.md) for the latest benchmark results.

---

## Layer 1: Routing Evals (Skill Activation)

Each `*.eval.md` file tests whether prompts activate the correct skill.

```
evals/
├── sf-apex.eval.md
├── sf-test.eval.md
├── sf-flow.eval.md
├── ... (10 files total)
```

**How to use:**
1. Run each "Should Trigger" query → verify the skill activates
2. Run each "Should NOT Trigger" query → verify it does NOT activate
3. Score: `correct activations / total queries`
4. Tune the skill's `description` field to improve accuracy

---

## Layer 2: Quality Benchmark (LLM-as-Judge)

Compares AI-generated Salesforce code **with** vs **without** skill context. Proves that skills make the AI write better code.

```
evals/benchmarks/
├── tasks.json          # 15 representative Salesforce tasks
├── rubric.md           # Scoring criteria (25 points per task)
├── judge-prompt.md     # LLM judge system prompt
├── run-benchmark.sh    # Orchestration script
└── results/            # Output (gitignored)
```

### Quick Start

```bash
export ANTHROPIC_API_KEY="sk-ant-..."

# Preview tasks (no API calls)
bash evals/benchmarks/run-benchmark.sh --dry-run

# Run a single task
bash evals/benchmarks/run-benchmark.sh --task apex-trigger-bulk

# Run all 15 tasks (~$2-5 in API costs)
bash evals/benchmarks/run-benchmark.sh

# Re-score existing outputs
bash evals/benchmarks/run-benchmark.sh --judge-only
```

### Scoring Rubric (25 points per task)

| Category | What it measures | Weight |
|----------|-----------------|--------|
| **Security** | WITH USER_MODE, stripInaccessible, with sharing, no injection | 5 pts |
| **Governor Limits** | No SOQL/DML in loops, collection-based lookups | 5 pts |
| **Bulkification** | Handles 200+ records, uses Map/Set/List | 5 pts |
| **Patterns** | Trigger handler, service layer, naming conventions | 5 pts |
| **Completeness** | Requirements met, edge cases, error handling | 5 pts |

### Sample Results

| Task | Without Skills | With Skills | Improvement |
|------|---------------|-------------|-------------|
| Apex Trigger (bulk) | 11/25 | 22/25 | +11 (+100%) |
| Batch Cleanup | 13/25 | 21/25 | +8 (+62%) |
| REST API Endpoint | 9/25 | 20/25 | +11 (+122%) |
| SOQL Optimization | 8/25 | 20/25 | +12 (+150%) |
| Security Audit | 6/25 | 23/25 | +17 (+283%) |
| LWC Record List | 12/25 | 19/25 | +7 (+58%) |
| Flow Automation | 10/25 | 21/25 | +11 (+110%) |
| **Average** | **9.9/25 (40%)** | **20.9/25 (83%)** | **+11 (+111%)** |

> *Sample results are illustrative. Run the benchmark yourself for actual numbers.*

### How It Works

For each of the 15 tasks:
1. **Baseline**: Claude generates code with no skill context
2. **With Skills**: Claude generates code with the relevant SKILL.md injected as system context
3. **Judge**: Claude scores both outputs against the rubric (structured JSON)
4. **Report**: Aggregated comparison table in `results/report.md`

---

## Layer 3: Static Analysis Checks

Automated regex-based checks for Salesforce anti-patterns. No LLM needed.

```
evals/checks/
└── static-checks.sh    # 10 pattern checks
```

### Quick Start

```bash
# Check a single Apex file
bash evals/checks/static-checks.sh MyClass.cls

# Check all .cls files in a directory
bash evals/checks/static-checks.sh force-app/main/default/classes/

# JSON output
bash evals/checks/static-checks.sh --format json MyClass.cls
```

### Checks Performed

| # | Check | Detects |
|---|-------|---------|
| 1 | No SOQL in loops | `[SELECT` inside `for`/`while` blocks |
| 2 | No DML in loops | `insert`/`update`/`delete` inside loops |
| 3 | Uses `with sharing` | Classes without sharing declaration |
| 4 | Has WITH USER_MODE | SOQL queries without security enforcement |
| 5 | Has stripInaccessible | DML without FLS enforcement |
| 6 | No hardcoded IDs | 15/18-char Salesforce ID literals |
| 7 | No SOQL injection | String concatenation in SOQL |
| 8 | Trigger delegates | Triggers with >15 lines of logic |
| 9 | No sensitive debug | `System.debug` with PII field names |
| 10 | Null-safe queries | Query results used without null checks |

### Sample Output

```
━━━ AccountService.cls ━━━
  ✓ No SOQL in loops
  ✓ No DML in loops
  ✓ Uses 'with sharing'
  ✓ Has WITH USER_MODE
  ✗ Has stripInaccessible/AccessLevel
    → File has 3 DML operations but no stripInaccessible() or AccessLevel.USER_MODE
  ✓ No hardcoded IDs
  ✓ No SOQL injection risk
  ✓ Trigger delegates to handler
  ✓ No sensitive data in debug
  ✓ Null-safe SOQL results

  Score: 9/10 checks passed
  1 issue(s) found
```
