# Salesforce Code Quality Rubric

Scoring rubric for evaluating AI-generated Salesforce code. Each category is scored 0-5.

**Total: 25 points per task**

---

## 1. Security (0-5)

| Score | Criteria |
|-------|----------|
| **5** | All of: `WITH USER_MODE` on SOQL, `Security.stripInaccessible()` on DML, `with sharing` on class, no hardcoded credentials, no SOQL injection, no PII in debug logs |
| **4** | Has USER_MODE + stripInaccessible + with sharing, minor gap (e.g., missing on one query) |
| **3** | Has at least two security mechanisms (e.g., with sharing + USER_MODE) |
| **2** | Has one security mechanism only (e.g., just `with sharing`) |
| **1** | Mentions security in comments but doesn't implement it, or uses legacy pattern (SECURITY_ENFORCED) |
| **0** | No security enforcement at all — no sharing, no FLS, raw DML/SOQL |

### What to look for:
- `WITH USER_MODE` in SOQL queries (preferred over `WITH SECURITY_ENFORCED`)
- `Security.stripInaccessible(AccessType.CREATABLE/UPDATABLE/READABLE, records)` before DML
- `with sharing` keyword on class declaration
- Bind variables (`:variableName`) in dynamic SOQL instead of string concatenation
- `String.escapeSingleQuotes()` when bind variables aren't possible
- No `System.debug()` of sensitive fields (SSN, passwords, tokens)
- Named Credentials for external callouts (not hardcoded URLs/keys)

---

## 2. Governor Limits (0-5)

| Score | Criteria |
|-------|----------|
| **5** | Zero SOQL/DML in loops, uses collections (Map/Set/List) for lookups, queries before loops, single DML after loop, aware of limits (mentions or monitors) |
| **4** | No SOQL/DML in loops, uses collections, minor optimization miss (e.g., could use Map instead of nested loop) |
| **3** | No SOQL/DML in loops but suboptimal pattern (e.g., unnecessary queries, could consolidate DML) |
| **2** | Has SOQL or DML in a loop but the loop is bounded/small, or acknowledges the issue |
| **1** | SOQL or DML in loop with no acknowledgment, but code might work for small data |
| **0** | Multiple SOQL and DML inside loops, would fail with real data volumes |

### What to look for:
- No `[SELECT ...]` or `Database.query()` inside `for`/`while` loops
- No `insert`/`update`/`delete` inside loops — collect in List, DML once
- Uses `Map<Id, SObject>` for efficient lookups instead of nested queries
- Uses `Set<Id>` to collect IDs before querying related records
- Queries use `LIMIT` where appropriate
- For Batch Apex: appropriate scope size, `Database.Stateful` only when needed

---

## 3. Bulkification (0-5)

| Score | Criteria |
|-------|----------|
| **5** | Explicitly handles 200+ records, uses collections throughout, works correctly with `Trigger.new` containing 200 records |
| **4** | Handles bulk data correctly but doesn't explicitly mention/test for 200 records |
| **3** | Works for bulk but has minor inefficiency (e.g., could use Map but uses filter loop) |
| **2** | Works for small batches but would struggle with 200 records (e.g., multiple queries per record) |
| **1** | Only handles single records (e.g., `Trigger.new[0]`), would partially fail in bulk |
| **0** | Hardcoded for single record, uses `Trigger.new[0]`, or no collection handling |

### What to look for:
- Trigger code processes `Trigger.new` as a collection, never `Trigger.new[0]`
- Uses `Map<Id, SObject>` from `Trigger.newMap` / `Trigger.oldMap` for field change detection
- Batch/Queueable properly chunks work
- Test classes create 200+ records for bulk scenarios
- No assumptions about single-record execution

---

## 4. Patterns & Architecture (0-5)

| Score | Criteria |
|-------|----------|
| **5** | Follows Salesforce patterns perfectly: trigger handler framework, service/selector layers, correct naming conventions (PascalCase classes, camelCase methods), proper separation of concerns |
| **4** | Good patterns with minor deviation (e.g., correct handler but missing selector class) |
| **3** | Has a handler pattern but incomplete (e.g., some logic still in trigger, or naming inconsistent) |
| **2** | Basic structure present but significant pattern violations |
| **1** | Minimal structure, most logic in wrong place |
| **0** | All logic in trigger body, no patterns, poor naming |

### What to look for:
- **Triggers**: One trigger per object, delegates to handler class, no logic in trigger
- **Naming**: `AccountTriggerHandler`, `AccountService`, `AccountSelector`, `AccountServiceTest`
- **Test classes**: `@IsTest`, `@TestSetup`, Arrange-Act-Assert pattern, descriptive method names
- **Async**: Correct choice of @future vs Queueable vs Batch vs Schedulable
- **Error handling**: Custom exceptions, `Database.SaveResult` parsing, try/catch around callouts
- **Flow XML**: Bypass decision at entry, fault connectors on DML/callout elements

---

## 5. Completeness (0-5)

| Score | Criteria |
|-------|----------|
| **5** | All requirements met, handles edge cases (null, empty list, errors), includes error handling, production-ready |
| **4** | All requirements met, most edge cases handled, minor gaps |
| **3** | Core requirements met, some edge cases missed, basically functional |
| **2** | Partial implementation, missing significant requirements |
| **1** | Minimal implementation, addresses only the simplest case |
| **0** | Does not address the stated requirements |

### What to look for:
- Does the code do what was asked?
- Are null checks present where needed?
- Is error handling included (try/catch, Database.SaveResult)?
- Are edge cases considered (empty lists, missing fields, permissions)?
- Is the code deployable as-is (no syntax errors, proper metadata format)?

---

## Scoring Summary

```
Task: [task name]
Condition: [baseline | with-skill]

Security:        _/5  [reason]
Governor Limits: _/5  [reason]
Bulkification:   _/5  [reason]
Patterns:        _/5  [reason]
Completeness:    _/5  [reason]
─────────────────────
Total:           _/25
```
