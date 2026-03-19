# Skill Evaluation Framework

Each eval file contains test queries to measure whether a skill triggers correctly.

## Format

```markdown
## Should Trigger
- Queries that SHOULD activate this skill

## Should NOT Trigger
- Queries that should activate a DIFFERENT skill or none at all
```

## How to Use

1. Run each "Should Trigger" query and verify the skill activates
2. Run each "Should NOT Trigger" query and verify it does NOT activate
3. Calculate trigger rate: correct activations / total queries
4. Tune the skill's `description` field to improve accuracy
5. Re-run and iterate (typically 3-5 iterations is sufficient)

## Guidelines

- Aim for 10+ queries per section
- Include edge cases and ambiguous phrasing
- "Should NOT Trigger" queries should be realistic near-misses
- Test across multiple agent platforms if possible
