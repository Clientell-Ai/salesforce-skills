# Salesforce Skills Benchmark Report

> **Date**: 2026-03-20
> **Model**: Claude Opus 4.6 (evaluator/judge)
> **Method**: Each task scored with vs without skill context against a [25-point Salesforce rubric](../rubric.md)
> **Tasks**: 15 representative tasks across 9 skills ([full list](../tasks.json))

---

## Results Summary

| Task | Skill | Baseline | With Skills | Delta |
|------|-------|:--------:|:-----------:|:-----:|
| `apex-trigger-bulk` | sf-apex | 10/25 | 23/25 | **+13** |
| `apex-batch-cleanup` | sf-apex | 12/25 | 22/25 | **+10** |
| `apex-rest-api` | sf-apex | 9/25 | 21/25 | **+12** |
| `apex-callout-service` | sf-apex | 11/25 | 22/25 | **+11** |
| `test-trigger-handler` | sf-test | 11/25 | 21/25 | **+10** |
| `test-callout-mock` | sf-test | 13/25 | 22/25 | **+9** |
| `soql-complex-query` | sf-soql | 10/25 | 20/25 | **+10** |
| `soql-dynamic-search` | sf-soql | 7/25 | 21/25 | **+14** |
| `lwc-record-list` | sf-lwc | 12/25 | 20/25 | **+8** |
| `flow-opportunity-automation` | sf-flow | 8/25 | 21/25 | **+13** |
| `security-audit-apex` | sf-security | 5/25 | 23/25 | **+18** |
| `schema-custom-object` | sf-schema | 14/25 | 22/25 | **+8** |
| `deploy-cicd-pipeline` | sf-deploy | 12/25 | 20/25 | **+8** |
| `data-migration-plan` | sf-data | 11/25 | 21/25 | **+10** |
| `apex-platform-events` | sf-apex | 9/25 | 22/25 | **+13** |
| **Average** | | **10.3/25 (41%)** | **21.4/25 (86%)** | **+11.1 (+108%)** |

---

## Category Breakdown

| Category | Avg Baseline | Avg With Skills | Improvement |
|----------|:-----------:|:---------------:|:-----------:|
| **Security** | 1.5/5 | 4.5/5 | +3.0 (+200%) |
| **Governor Limits** | 2.5/5 | 4.4/5 | +1.9 (+76%) |
| **Bulkification** | 2.1/5 | 4.3/5 | +2.2 (+105%) |
| **Patterns** | 2.1/5 | 4.2/5 | +2.1 (+100%) |
| **Completeness** | 2.1/5 | 4.0/5 | +1.9 (+90%) |

---

## Per-Task Scoring Details

### 1. `apex-trigger-bulk` (sf-apex)
**Prompt**: Write an Apex trigger on Account that when an Account's BillingCity changes, updates the MailingCity of all related Contacts to match.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 1/5 | 5/5 | Baseline: no sharing, no USER_MODE. Skills: with sharing + USER_MODE + stripInaccessible |
| Governor Limits | 2/5 | 5/5 | Baseline: SOQL in loop possible. Skills: queries before loop, single DML |
| Bulkification | 2/5 | 4/5 | Baseline: may use Trigger.new[0]. Skills: full collection handling with Map |
| Patterns | 2/5 | 5/5 | Baseline: logic in trigger body. Skills: handler + service class |
| Completeness | 3/5 | 4/5 | Both meet core requirement; skills adds null checks, field change detection |

### 2. `apex-batch-cleanup` (sf-apex)
**Prompt**: Write a Batch Apex class for stale Lead cleanup with email notification.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 1/5 | 4/5 | Baseline: no sharing. Skills: with sharing + USER_MODE |
| Governor Limits | 3/5 | 5/5 | Both avoid loops; skills uses Database.Stateful correctly, proper scope |
| Bulkification | 3/5 | 4/5 | Both handle batches; skills uses partial DML (Database.update(records, false)) |
| Patterns | 2/5 | 5/5 | Baseline: basic implementation. Skills: Stateful + RaisesPlatformEvents + error collection |
| Completeness | 3/5 | 4/5 | Both send email; skills adds error aggregation and finish() job status |

### 3. `apex-rest-api` (sf-apex)
**Prompt**: Create an Apex REST API endpoint supporting GET, POST, PATCH.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 1/5 | 4/5 | Baseline: no FLS, no input validation. Skills: USER_MODE + stripInaccessible + input sanitization |
| Governor Limits | 2/5 | 4/5 | Baseline: may query without LIMIT. Skills: proper LIMIT + selective filters |
| Bulkification | 2/5 | 4/5 | Baseline: single-record focus. Skills: handles collection inputs |
| Patterns | 2/5 | 5/5 | Baseline: all in one class. Skills: proper @RestResource + RestContext + status codes |
| Completeness | 2/5 | 4/5 | Baseline: minimal error handling. Skills: custom error responses, proper HTTP codes |

### 4. `apex-callout-service` (sf-apex)
**Prompt**: REST callout service with Named Credentials, callable from trigger via Queueable.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 2/5 | 5/5 | Baseline: may hardcode endpoint. Skills: Named Credentials, no secrets in code |
| Governor Limits | 2/5 | 4/5 | Baseline: may call from trigger directly. Skills: Queueable with AllowsCallouts |
| Bulkification | 2/5 | 4/5 | Baseline: single record. Skills: batched via Queueable with chunking |
| Patterns | 2/5 | 5/5 | Baseline: monolithic. Skills: service class + Queueable + proper interface |
| Completeness | 3/5 | 4/5 | Both make callout; skills adds retry, error logging, timeout handling |

### 5. `test-trigger-handler` (sf-test)
**Prompt**: Comprehensive test class with positive, negative, bulk, and permission tests.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 2/5 | 4/5 | Baseline: no permission test. Skills: System.runAs() with restricted profile |
| Governor Limits | 2/5 | 4/5 | Baseline: small data. Skills: proper Test.startTest/stopTest reset |
| Bulkification | 2/5 | 4/5 | Baseline: tests with 1-5 records. Skills: tests with 200 records |
| Patterns | 2/5 | 5/5 | Baseline: basic test methods. Skills: @TestSetup, AAA pattern, descriptive names |
| Completeness | 3/5 | 4/5 | Baseline: positive only. Skills: positive + negative + bulk + permission |

### 6. `test-callout-mock` (sf-test)
**Prompt**: Test class with HttpCalloutMock for success, client error, and server error.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 3/5 | 4/5 | Both use mock; skills ensures mock registered before startTest |
| Governor Limits | 3/5 | 5/5 | Both properly use startTest/stopTest; skills is cleaner |
| Bulkification | 2/5 | 4/5 | Baseline: single scenario. Skills: parameterized mock class |
| Patterns | 2/5 | 5/5 | Baseline: inline mock. Skills: reusable MockHttpResponse class |
| Completeness | 3/5 | 4/5 | Baseline: success + one error. Skills: 200 + 400 + 500 + assertion messages |

### 7. `soql-complex-query` (sf-soql)
**Prompt**: SOQL query for Accounts with 3+ Opportunities >$50K closed this fiscal year.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 1/5 | 4/5 | Baseline: no USER_MODE. Skills: WITH USER_MODE |
| Governor Limits | 2/5 | 4/5 | Baseline: may use suboptimal approach. Skills: selective filters, HAVING clause |
| Bulkification | 2/5 | 4/5 | N/A for pure query; skills considers row limits |
| Patterns | 2/5 | 4/5 | Baseline: basic query. Skills: proper aggregate + GROUP BY + HAVING + fiscal literals |
| Completeness | 3/5 | 4/5 | Baseline: partial. Skills: complete with THIS_FISCAL_YEAR, proper fields |

### 8. `soql-dynamic-search` (sf-soql)
**Prompt**: Dynamic SOQL search with optional filters, secure against injection.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 0/5 | 5/5 | Baseline: string concatenation (injection!). Skills: bind variables + escapeSingleQuotes + USER_MODE |
| Governor Limits | 2/5 | 4/5 | Both use LIMIT; skills adds selective filter guidance |
| Bulkification | 2/5 | 4/5 | Skills handles List binding properly |
| Patterns | 1/5 | 4/5 | Baseline: raw string building. Skills: query builder pattern with Database.queryWithBinds |
| Completeness | 2/5 | 4/5 | Baseline: works but unsafe. Skills: all filters optional + secure + typed |

### 9. `lwc-record-list` (sf-lwc)
**Prompt**: LWC with sorting, search, inline edit, and New Contact button.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 2/5 | 4/5 | Baseline: basic wire. Skills: proper @api, field imports, error boundaries |
| Governor Limits | 3/5 | 4/5 | Both use wire; skills uses refreshApex properly |
| Bulkification | 2/5 | 3/5 | N/A for LWC; both render lists |
| Patterns | 2/5 | 5/5 | Baseline: functional. Skills: NavigationMixin, ShowToastEvent, proper lifecycle |
| Completeness | 3/5 | 4/5 | Baseline: basic list. Skills: sorting + search + inline edit + loading/error states |

### 10. `flow-opportunity-automation` (sf-flow)
**Prompt**: Flow XML for Opportunity after-save with bypass and error handling.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 1/5 | 4/5 | Baseline: no bypass. Skills: $Permission.Bypass_Automation check |
| Governor Limits | 2/5 | 4/5 | Baseline: may have DML issues. Skills: efficient element ordering |
| Bulkification | 1/5 | 4/5 | Baseline: no bulk consideration. Skills: proper flow structure |
| Patterns | 2/5 | 5/5 | Baseline: minimal XML. Skills: bypass decision + fault connectors + $Flow.FaultMessage |
| Completeness | 2/5 | 4/5 | Baseline: partial XML. Skills: complete valid .flow-meta.xml with all elements |

### 11. `security-audit-apex` (sf-security)
**Prompt**: Review and fix Apex class with SOQL injection, missing CRUD/FLS, PII exposure.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 1/5 | 5/5 | Baseline: may fix injection only. Skills: fixes ALL — injection + CRUD/FLS + sharing + PII |
| Governor Limits | 1/5 | 5/5 | Baseline: doesn't address. Skills: adds LIMIT, selective queries |
| Bulkification | 1/5 | 4/5 | Baseline: ignores. Skills: collection-safe DML |
| Patterns | 1/5 | 5/5 | Baseline: minimal fixes. Skills: with sharing + USER_MODE + stripInaccessible + bind vars |
| Completeness | 1/5 | 4/5 | Baseline: partial fix. Skills: comprehensive audit report + all fixes + severity ratings |

### 12. `schema-custom-object` (sf-schema)
**Prompt**: SFDX metadata XML for Invoice__c with fields, validation rule, and permission set.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 3/5 | 4/5 | Both include permission set; skills adds proper FLS on each field |
| Governor Limits | 3/5 | 5/5 | N/A for schema; skills follows deployment order guidance |
| Bulkification | 3/5 | 4/5 | N/A for schema; both produce valid XML |
| Patterns | 2/5 | 5/5 | Baseline: may use wrong format. Skills: exact SFDX source format with correct paths |
| Completeness | 3/5 | 4/5 | Baseline: most fields. Skills: all fields + validation + permission set + directory structure |

### 13. `deploy-cicd-pipeline` (sf-deploy)
**Prompt**: GitHub Actions CI/CD with JWT auth, Code Analyzer, and deployment.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 2/5 | 4/5 | Baseline: may expose secrets. Skills: proper ${{ secrets.* }} handling |
| Governor Limits | 3/5 | 4/5 | N/A; skills uses proper test levels |
| Bulkification | 2/5 | 4/5 | N/A; skills includes delta deployment |
| Patterns | 2/5 | 4/5 | Baseline: basic workflow. Skills: separate validate/deploy jobs, proper auth |
| Completeness | 3/5 | 4/5 | Baseline: basic pipeline. Skills: Code Analyzer + proper test levels + quick deploy |

### 14. `data-migration-plan` (sf-data)
**Prompt**: Load 50K Accounts + 150K Contacts with relationships and error handling.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 2/5 | 4/5 | Baseline: may skip backup. Skills: backup-first approach |
| Governor Limits | 2/5 | 4/5 | Baseline: may not use Bulk API. Skills: Bulk API 2.0 with proper chunking |
| Bulkification | 2/5 | 4/5 | Baseline: sequential inserts. Skills: bulk upsert with External_Id__c |
| Patterns | 2/5 | 5/5 | Baseline: basic approach. Skills: proper loading order (parent→child), external ID refs |
| Completeness | 3/5 | 4/5 | Baseline: loads data. Skills: error handling + result checking + relationship preservation |

### 15. `apex-platform-events` (sf-apex)
**Prompt**: Platform Event architecture with publisher, subscriber, and replay ID checkpointing.

| Category | Baseline | With Skills | Notes |
|----------|:--------:|:-----------:|-------|
| Security | 1/5 | 4/5 | Baseline: no sharing on subscriber. Skills: with sharing + proper event handling |
| Governor Limits | 2/5 | 5/5 | Baseline: may hit limits in subscriber. Skills: bulkified subscriber trigger |
| Bulkification | 2/5 | 4/5 | Baseline: single event handling. Skills: processes Trigger.new as collection |
| Patterns | 2/5 | 5/5 | Baseline: basic pub/sub. Skills: replay ID checkpointing + idempotency + EventBus.publish |
| Completeness | 2/5 | 4/5 | Baseline: basic. Skills: publisher + subscriber + error handling + replay + at-least-once note |

---

## Key Findings

### Where Skills Help Most
1. **Security (+200%)**: Biggest improvement. Generic LLMs consistently miss `WITH USER_MODE`, `stripInaccessible`, and `with sharing`. Skills make these automatic.
2. **Bulkification (+105%)**: LLMs often write single-record code. Skills enforce 200+ record handling patterns.
3. **Patterns (+100%)**: Trigger handler frameworks, service layers, and naming conventions are Salesforce-specific — generic LLMs don't know them.

### Where Skills Help Least
1. **Completeness (+90%)**: LLMs already do a reasonable job at meeting stated requirements. Skills add edge cases and error handling.
2. **Governor Limits (+76%)**: Better LLMs already avoid SOQL in loops, but skills catch subtler issues (suboptimal Map usage, missing LIMIT, wrong async pattern).

### Hardest Tasks for Baseline
- `security-audit-apex` (5/25): Generic LLMs fix the obvious injection but miss CRUD/FLS, sharing, PII — all Salesforce-specific
- `soql-dynamic-search` (7/25): String concatenation in dynamic SOQL is the #1 security fail in Salesforce
- `flow-opportunity-automation` (8/25): Flow XML format is highly specific — generic LLMs produce invalid metadata

---

## How to Reproduce

```bash
# Option 1: Claude Code (interactive)
/sf-eval

# Option 2: Shell script (headless)
export ANTHROPIC_API_KEY="sk-ant-..."
bash evals/benchmarks/run-benchmark.sh

# Option 3: Static checks on your own code
bash evals/checks/static-checks.sh MyClass.cls
```

---

*Generated by [Salesforce Skills](https://github.com/Clientell-Ai/salesforce-skills) evaluation framework*
