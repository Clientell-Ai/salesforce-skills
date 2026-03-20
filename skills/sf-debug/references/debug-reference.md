# Debug Reference

Deep reference for Salesforce debugging — Limits class API, log parsing, Execute Anonymous patterns, error handling, performance profiling, and Tooling API trace flag management.

---

## Complete Limits Class Method Reference

All methods follow the pattern: `Limits.getX()` returns current usage, `Limits.getLimitX()` returns the maximum.

| Method Pair | Sync Limit | Async Limit | Description |
|-------------|-----------|-------------|-------------|
| `getQueries()` / `getLimitQueries()` | 100 | 200 | SOQL queries issued |
| `getDmlStatements()` / `getLimitDmlStatements()` | 150 | 150 | DML statements executed |
| `getDmlRows()` / `getLimitDmlRows()` | 10,000 | 10,000 | Total rows processed by DML |
| `getQueryRows()` / `getLimitQueryRows()` | 50,000 | 50,000 | Total rows retrieved by SOQL |
| `getCpuTime()` / `getLimitCpuTime()` | 10,000 ms | 60,000 ms | CPU time consumed |
| `getHeapSize()` / `getLimitHeapSize()` | 6,291,456 | 12,582,912 | Heap memory in bytes |
| `getCallouts()` / `getLimitCallouts()` | 100 | 100 | HTTP/SOAP callouts |
| `getFutureCalls()` / `getLimitFutureCalls()` | 50 | 0 | @future method invocations |
| `getQueueableJobs()` / `getLimitQueueableJobs()` | 50 | 1 | Queueable jobs enqueued |
| `getAggregateQueries()` / `getLimitAggregateQueries()` | 300 | 300 | Aggregate SOQL queries |
| `getSoslQueries()` / `getLimitSoslQueries()` | 20 | 20 | SOSL queries |
| `getPublishImmediateDML()` / `getLimitPublishImmediateDML()` | 150 | 150 | Platform Event publishes |
| `getEmailInvocations()` / `getLimitEmailInvocations()` | 10 | 10 | Emails sent via Apex |
| `getMobilePushApexCalls()` / `getLimitMobilePushApexCalls()` | 10 | 10 | Mobile push notifications |
| `getSavepoints()` / `getLimitSavepoints()` | 150 (shared w/ DML) | 150 | Database savepoints |
| `getSavepointRollbacks()` / `getLimitSavepointRollbacks()` | 150 (shared w/ DML) | 150 | Savepoint rollbacks |
| `getFieldsDescribes()` / `getLimitFieldsDescribes()` | 100 | 100 | Schema describe calls |
| `getPicklistDescribes()` / `getLimitPicklistDescribes()` | 100 | 100 | Picklist describe calls |

### Limits Snapshot Utility

```apex
// Log all key limits at a named checkpoint
public with sharing class LimitsLogger {
    public static void logAll(String context) {
        System.debug(LoggingLevel.INFO, '=== Limits [' + context + '] === '
            + 'SOQL:' + Limits.getQueries() + '/' + Limits.getLimitQueries()
            + ' DML:' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements()
            + ' CPU:' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime()
            + ' Heap:' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
    }
}
```

---

## Debug Log Format — Parsing Patterns

Each debug log line follows this structure:
```
HH:MM:SS.sss (nanoseconds)|EVENT_TYPE|[line,col]|details
```

### Regex Patterns for Common Log Events

```
# SOQL queries with line numbers and statements
SOQL_EXECUTE_BEGIN\|\[(\d+)\]\|.*?\|(SELECT .+)
SOQL_EXECUTE_END\|\[(\d+)\]\|Rows:(\d+)

# DML operations
DML_BEGIN\|\[(\d+)\]\|Op:(Insert|Update|Delete|Upsert|Undelete)\|Type:(\w+)\|Rows:(\d+)

# Exceptions and fatal errors
EXCEPTION_THROWN\|\[(\d+)\]\|(.+?):\s*(.+)
FATAL_ERROR\|(.+)

# Governor limit summary
Number of SOQL queries: (\d+) out of (\d+)
Number of DML statements: (\d+) out of (\d+)
Maximum CPU time: (\d+) out of (\d+)
Maximum heap size: (\d+) out of (\d+)

# Heap, callouts, debug output
HEAP_ALLOCATE\|\[(\d+)\]\|Bytes:(\d+)
CALLOUT_REQUEST\|\[(\d+)\]\|(.+)
USER_DEBUG\|\[(\d+)\]\|(\w+)\|(.+)
CODE_UNIT_STARTED\|\[EXTERNAL\]\|(.+)
FLOW_START_INTERVIEWS_BEGIN\|(.+)

# Log truncation detection
\*\*\* Skipped (\d+) bytes of detailed log
```

---

## Execute Anonymous Debugging Patterns

### Reproduce a Specific Record Issue

```apex
Id recordId = '001xxxxxxxxxxxx';
Account acc = [SELECT Id, Name, Industry, OwnerId,
               (SELECT Id, Amount FROM Opportunities)
               FROM Account WHERE Id = :recordId];
System.debug('Record: ' + JSON.serializePretty(acc));

try {
    acc.Industry = 'Technology';
    update acc;
    System.debug('Update succeeded');
} catch (DmlException e) {
    System.debug('DML Error: ' + e.getDmlType(0) + ' - ' + e.getDmlMessage(0));
    System.debug('Fields: ' + e.getDmlFieldNames(0));
} catch (Exception e) {
    System.debug(e.getTypeName() + ': ' + e.getMessage());
    System.debug('Stack: ' + e.getStackTraceString());
}
```

### Test Record Access / Sharing

```apex
UserRecordAccess access = [
    SELECT HasReadAccess, HasEditAccess, HasDeleteAccess, MaxAccessLevel
    FROM UserRecordAccess
    WHERE UserId = :UserInfo.getUserId() AND RecordId = '001xxxxxxxxxxxx'
];
System.debug('Access: ' + JSON.serializePretty(access));
```

### Profile a SOQL Query

```apex
Long cpuBefore = Limits.getCpuTime();
List<Account> results = [SELECT Id, Name FROM Account WHERE Industry = 'Technology'];
System.debug('Rows: ' + results.size() + ', CPU: ' + (Limits.getCpuTime() - cpuBefore) + 'ms');
```

---

## Governor Limit Troubleshooting Decision Tree

### SOQL Limit (100/200 queries)

```
Is SOQL in a loop?
├── YES → Move query before loop, use Map<Id, SObject> for lookups
└── NO
    ├── Triggers on related objects firing queries?
    │   ├── YES → Optimize cross-object triggers, combine queries
    │   └── NO → Check flows/process builders and managed packages (LIMIT_USAGE_FOR_NS)
    └── Consider async (Batch/Queueable) for 200-query limit
```

### CPU Time (10s/60s)

```
Nested loop (O(n^2))?
├── YES → Refactor to Map-based lookup (O(n))
└── NO
    ├── Repeated Schema.getGlobalDescribe()?
    │   ├── YES → Cache in static variable
    │   └── NO → Profile with Limits.getCpuTime() to isolate hotspot
    └── Move to async for 60s CPU limit
```

### Heap Size (6MB/12MB)

```
Large query loading all results into memory?
├── YES → Use SOQL for-loop: for (Account a : [SELECT ...]) { }
└── NO
    ├── Collection growing in a loop?
    │   ├── YES → Process and clear in batches, or use Database.Batchable
    │   └── NO → Use JSON.createParser() for streaming large payloads
    └── Move to async for 12MB heap limit
```

---

## Error Handling Patterns

### DML Error Handler with Partial Success

```apex
public with sharing class DmlErrorHandler {
    public static List<Database.SaveResult> safeSave(List<SObject> records, String op) {
        List<Database.SaveResult> results = (op == 'insert')
            ? Database.insert(records, false)
            : Database.update(records, false);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Record ' + i + ': '
                        + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
        return results;
    }
}
```

### Record Lock Retry

Catch `StatusCode.UNABLE_TO_LOCK_ROW` in a DmlException, retry up to 3 times. In production, use a Queueable for actual delay between retries rather than a synchronous loop.

### Mixed DML Workaround

Move setup-object DML (User, Group, PermissionSet) to an `@future` method while keeping non-setup DML in the current transaction. In tests, wrap setup DML in `System.runAs()`.

### Safe Query Pattern

```apex
// BAD — throws QueryException if no rows:
Account acc = [SELECT Id FROM Account WHERE Name = 'Test'];

// GOOD — check list:
List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];
if (!accounts.isEmpty()) {
    Account acc = accounts[0];
}
```

---

## Performance Profiling Apex Patterns

### Method-Level Profiler

```apex
public with sharing class Profiler {
    private static Map<String, Long> timers = new Map<String, Long>();
    private static Map<String, Integer> soqlCounters = new Map<String, Integer>();

    public static void start(String label) {
        timers.put(label, Limits.getCpuTime());
        soqlCounters.put(label, Limits.getQueries());
    }

    public static void stop(String label) {
        System.debug(LoggingLevel.INFO, 'PROFILE [' + label + '] CPU: '
            + (Limits.getCpuTime() - timers.get(label)) + 'ms, SOQL: '
            + (Limits.getQueries() - soqlCounters.get(label)));
    }
}
// Usage: Profiler.start('myOp'); doWork(); Profiler.stop('myOp');
```

### Batch Profiling

In `Database.Batchable` with `Database.Stateful`, track cumulative CPU/SOQL across batches:
```apex
// In execute(): capture Limits.getCpuTime() before and after processing, accumulate in stateful vars
// In finish(): log totals and averages per batch
```

---

## Trace Flag Setup via Tooling API

### Create Debug Level

```bash
sf api request rest --method POST --target-org myOrg \
  --url "/services/data/v62.0/tooling/sobjects/DebugLevel" \
  --body '{"DeveloperName":"DetailedApexDebug","MasterLabel":"Detailed Apex Debug",
    "ApexCode":"FINE","ApexProfiling":"FINEST","Database":"FINE",
    "System":"DEBUG","Validation":"INFO","Workflow":"INFO","Callout":"INFO"}'
```

### Create Trace Flag

```bash
sf api request rest --method POST --target-org myOrg \
  --url "/services/data/v62.0/tooling/sobjects/TraceFlag" \
  --body '{"TracedEntityId":"005xxxxxxxxxxxx","DebugLevelId":"7dlxxxxxxxxxxxx",
    "LogType":"USER_DEBUG","StartDate":"2026-03-20T00:00:00.000+0000",
    "ExpirationDate":"2026-03-21T00:00:00.000+0000"}'
```

### Query / Extend / Delete

```bash
# List active:  GET /services/data/v62.0/tooling/query?q=SELECT+Id,TracedEntityId,LogType,ExpirationDate+FROM+TraceFlag+WHERE+ExpirationDate+>+TODAY
# Extend:       PATCH /services/data/v62.0/tooling/sobjects/TraceFlag/<Id> with {"ExpirationDate":"..."}
# Delete:       DELETE /services/data/v62.0/tooling/sobjects/TraceFlag/<Id>
```

---

## Debug Log Analysis Shell Commands

```bash
# Count SOQL queries (>10-20 is suspicious)
grep -c "SOQL_EXECUTE_BEGIN" debug.log

# Find repeated identical queries (SOQL in loop)
grep "SOQL_EXECUTE_BEGIN" debug.log | sort | uniq -c | sort -rn | head -10

# Count DML operations
grep -c "DML_BEGIN" debug.log

# Find all exceptions
grep "EXCEPTION_THROWN\|FATAL_ERROR" debug.log

# Extract cumulative limit usage
grep -A 30 "CUMULATIVE_LIMIT_USAGE" debug.log | head -35

# Find large heap allocations (>100KB)
grep "HEAP_ALLOCATE" debug.log | awk -F'Bytes:' '{if ($2 > 100000) print $0}'

# Check for log truncation
grep "Skipped.*bytes of detailed log" debug.log

# Find callout timing
grep "CALLOUT_REQUEST\|CALLOUT_RESPONSE" debug.log
```
