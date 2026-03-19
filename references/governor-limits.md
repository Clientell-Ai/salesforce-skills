# Salesforce Governor Limits Reference (API v62.0)

## Per-Transaction Limits (Synchronous)

| Limit | Value |
|-------|-------|
| SOQL queries | 100 |
| SOQL query rows returned | 50,000 |
| SOQL relationship queries (child) | 20 |
| Subquery rows | 2,000 |
| DML statements | 150 |
| DML rows | 10,000 |
| Heap size | 6 MB |
| CPU time | 10,000 ms |
| Callouts | 100 |
| Callout timeout (single) | 120 seconds |
| Callout total timeout | 120 seconds |
| Future calls | 50 |
| Queueable jobs | 50 |
| Email invocations | 10 |
| Push notifications | 10 |
| Event publish (immediate) | 150 |

## Per-Transaction Limits (Asynchronous)

| Limit | Value |
|-------|-------|
| SOQL queries | 200 |
| SOQL query rows | 50,000 |
| DML statements | 150 |
| DML rows | 10,000 |
| Heap size | 12 MB |
| CPU time | 60,000 ms |
| Callouts | 100 |

## Batch Apex Limits

| Limit | Value |
|-------|-------|
| Batch size (default) | 200 |
| Batch size (max) | 2,000 |
| Active batch jobs | 5 |
| Flex queue | 100 |
| QueryLocator rows | 50,000,000 |

## SOQL Limits

| Limit | Value |
|-------|-------|
| WHERE clause length | 4,000 chars |
| SOSL query length | 10,000 chars |
| Long text fields in SOQL | Not searchable |
| OFFSET max | 2,000 |
| SOQL for loops batch | 200 records |

## Platform Event Limits

| Limit | Value |
|-------|-------|
| Event publish (per hour) | Based on edition |
| Event delivery | At-least-once |
| Replay window | 72 hours |

## Monitoring in Code
```apex
System.debug('SOQL queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
System.debug('DML statements: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
System.debug('CPU time: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());
System.debug('Heap size: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
```
