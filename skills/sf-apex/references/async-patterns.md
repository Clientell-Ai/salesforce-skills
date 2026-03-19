# Async Apex Patterns Reference

## 1. @future Method

The simplest async pattern. Runs in a separate transaction with higher governor limits.

### Basic @future
```apex
public class FutureExample {

    @future
    public static void processRecordsAsync(Set<Id> recordIds) {
        List<Account> accounts = [
            SELECT Id, Name, Description
            FROM Account
            WHERE Id IN :recordIds
            WITH USER_MODE
        ];
        for (Account acc : accounts) {
            acc.Description = 'Processed at ' + System.now();
        }
        update accounts;
    }
}
```

### @future with Callout
```apex
public class FutureCalloutExample {

    @future(callout=true)
    public static void syncToExternalSystem(Set<Id> accountIds) {
        List<Account> accounts = [
            SELECT Id, Name, BillingCity
            FROM Account
            WHERE Id IN :accountIds
        ];

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.example.com/accounts');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(accounts));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            System.debug(LoggingLevel.ERROR, 'Callout failed: ' + res.getBody());
        }
    }
}
```

### Limitations
- Must be `static void` — cannot return a value.
- Parameters must be primitive types or collections of primitives only (no sObjects or complex types).
- Cannot call another @future method from a @future context.
- Cannot be used in Visualforce getMethodName() calls.
- Max 50 @future calls per transaction.
- No job ID returned — cannot monitor execution.

---

## 2. Queueable Apex

More flexible than @future: supports complex parameters, job chaining, and monitoring.

### Basic Queueable
```apex
public class AccountEnrichmentJob implements System.Queueable {

    private List<Account> accounts;

    public AccountEnrichmentJob(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext context) {
        for (Account acc : accounts) {
            acc.Description = 'Enriched by job ' + context.getJobId();
        }
        Database.update(accounts, false);
    }
}

// Enqueue the job:
// Id jobId = System.enqueueJob(new AccountEnrichmentJob(accountList));
```

### Queueable with Callouts
```apex
public class ExternalSyncJob implements System.Queueable, Database.AllowsCallouts {

    private List<Account> accounts;

    public ExternalSyncJob(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext context) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:My_Named_Credential/api/sync');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(accounts));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            // Process success
        }
    }
}
```

### Chaining Queueable Jobs
```apex
public class ChainedJob implements System.Queueable {

    private List<Id> recordIds;
    private Integer batchIndex;
    private static final Integer CHUNK_SIZE = 200;

    public ChainedJob(List<Id> recordIds, Integer batchIndex) {
        this.recordIds = recordIds;
        this.batchIndex = batchIndex;
    }

    public void execute(QueueableContext context) {
        Integer startIdx = batchIndex * CHUNK_SIZE;
        Integer endIdx = Math.min(startIdx + CHUNK_SIZE, recordIds.size());

        List<Id> chunk = new List<Id>();
        for (Integer i = startIdx; i < endIdx; i++) {
            chunk.add(recordIds[i]);
        }

        // Process chunk...
        processChunk(chunk);

        // Chain next batch if more records remain
        if (endIdx < recordIds.size()) {
            System.enqueueJob(new ChainedJob(recordIds, batchIndex + 1));
        }
    }

    private void processChunk(List<Id> chunk) {
        // Processing logic
    }
}
```

### Transaction Finalizers
```apex
public class RobustJob implements System.Queueable {

    public void execute(QueueableContext context) {
        // Attach a finalizer to handle success or failure
        System.attachFinalizer(new JobFinalizer());

        // Main processing logic
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 100];
        for (Account acc : accounts) {
            acc.Description = 'Updated';
        }
        update accounts;
    }
}

public class JobFinalizer implements System.Finalizer {

    public void execute(System.FinalizerContext context) {
        Id parentJobId = context.getAsyncApexJobId();
        System.ParentJobResult result = context.getResult();

        if (result == System.ParentJobResult.SUCCESS) {
            System.debug('Job ' + parentJobId + ' completed successfully.');
        } else if (result == System.ParentJobResult.UNHANDLED_EXCEPTION) {
            String errorMessage = context.getException().getMessage();
            System.debug(LoggingLevel.ERROR,
                'Job ' + parentJobId + ' failed: ' + errorMessage);

            // Optionally re-enqueue or log failure
            // System.enqueueJob(new RobustJob());
        }
    }
}
```

### Limitations
- Stack depth limit: max 5 chained Queueable jobs in Developer/Trial orgs; no hard limit in Enterprise but subject to async Apex limits.
- Max 50 enqueueJob calls per transaction.

---

## 3. Schedulable Apex

Run Apex at specific times or intervals using CRON expressions.

### Schedulable Implementation
```apex
public class DailyAccountCleanup implements System.Schedulable {

    public void execute(SchedulableContext sc) {
        // Launch a batch job from the scheduler
        Database.executeBatch(new AccountCleanupBatch(), 200);
    }
}

// Schedule the job:
// String jobId = System.schedule(
//     'Daily Account Cleanup',
//     '0 0 2 * * ?',   // Every day at 2:00 AM
//     new DailyAccountCleanup()
// );
```

### CRON Expression Format
```
Seconds  Minutes  Hours  Day_of_month  Month  Day_of_week  Optional_year

Field           Values          Special Characters
-----           ------          ------------------
Seconds         0-59            , - * /
Minutes         0-59            , - * /
Hours           0-23            , - * /
Day_of_month    1-31            , - * ? / L W
Month           1-12 or JAN-DEC , - * /
Day_of_week     1-7 or SUN-SAT  , - * ? / L #
Year (optional) null or 1970-2099 , - * /
```

### Common CRON Expressions
```
'0 0 0 * * ?'       — Midnight every day
'0 0 8 * * ?'       — 8:00 AM every day
'0 0 */4 * * ?'     — Every 4 hours
'0 30 9 ? * MON-FRI' — 9:30 AM weekdays
'0 0 0 1 * ?'       — First day of every month at midnight
'0 0 12 ? * 2L'     — Last Monday of every month at noon
```

### Managing Scheduled Jobs
```apex
public class SchedulerManager {

    public static String scheduleJob() {
        return System.schedule(
            'Weekly Report',
            '0 0 6 ? * MON',
            new DailyAccountCleanup()
        );
    }

    public static void abortJob(String jobName) {
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, State, NextFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];
        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
    }

    public static List<CronTrigger> getScheduledJobs() {
        return [
            SELECT Id, CronJobDetail.Name, State, NextFireTime,
                   CronExpression, TimesTriggered
            FROM CronTrigger
            WHERE CronJobDetail.JobType = '7'
            ORDER BY NextFireTime
        ];
    }
}
```

---

## 4. Batch Apex

Process large data volumes in chunks. Supports up to 50 million records.

### Full Batch with QueryLocator
```apex
public class LeadDeduplicationBatch implements
    Database.Batchable<SObject>,
    Database.Stateful,
    Database.AllowsCallouts,
    Database.RaisesPlatformEvents {

    private Integer totalProcessed = 0;
    private Integer totalErrors = 0;
    private List<String> errorMessages = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Email, Name, Company, Status, CreatedDate
            FROM Lead
            WHERE IsConverted = false
            AND CreatedDate = LAST_N_DAYS:30
            ORDER BY CreatedDate
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Lead> leadsToUpdate = new List<Lead>();

        for (Lead ld : scope) {
            ld.Status = 'Reviewed';
            leadsToUpdate.add(ld);
        }

        List<Database.SaveResult> results = Database.update(leadsToUpdate, false);

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                totalProcessed++;
            } else {
                totalErrors++;
                for (Database.Error err : results[i].getErrors()) {
                    errorMessages.add(
                        'Lead ' + leadsToUpdate[i].Id + ': ' + err.getMessage()
                    );
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors,
                   JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ 'admin@example.com' });
        mail.setSubject('Lead Dedup Batch Complete: ' + job.Status);
        mail.setPlainTextBody(
            'Processed: ' + totalProcessed + '\n' +
            'Errors: ' + totalErrors + '\n' +
            'Details:\n' + String.join(errorMessages, '\n')
        );
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}

// Execute:
// Id batchId = Database.executeBatch(new LeadDeduplicationBatch(), 200);
```

### Batch with Iterable (for non-SOQL data sources)
```apex
public class ExternalDataBatch implements Database.Batchable<String> {

    private List<String> externalIds;

    public ExternalDataBatch(List<String> externalIds) {
        this.externalIds = externalIds;
    }

    public Iterable<String> start(Database.BatchableContext bc) {
        return externalIds;
    }

    public void execute(Database.BatchableContext bc, List<String> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        for (String extId : scope) {
            accountsToUpdate.add(new Account(
                External_Id__c = extId,
                Last_Synced__c = System.now()
            ));
        }
        upsert accountsToUpdate External_Id__c;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('External data batch complete.');
    }
}
```

### Error Collection Pattern
```apex
public class ErrorCollectingBatch implements
    Database.Batchable<SObject>, Database.Stateful {

    public class BatchError {
        public Id recordId;
        public String errorMessage;
        public String fieldName;
        public BatchError(Id recId, String msg, String field) {
            this.recordId = recId;
            this.errorMessage = msg;
            this.fieldName = field;
        }
    }

    private List<BatchError> allErrors = new List<BatchError>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Email FROM Contact
            WHERE Email = null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        for (Contact c : scope) {
            c.Email = c.Name.replaceAll('\\s+', '.').toLowerCase() + '@placeholder.com';
        }
        List<Database.SaveResult> results = Database.update(scope, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    allErrors.add(new BatchError(
                        scope[i].Id,
                        err.getMessage(),
                        String.join(err.getFields(), ', ')
                    ));
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!allErrors.isEmpty()) {
            List<Error_Log__c> logs = new List<Error_Log__c>();
            for (BatchError be : allErrors) {
                logs.add(new Error_Log__c(
                    Record_Id__c = be.recordId,
                    Message__c = be.errorMessage,
                    Field__c = be.fieldName
                ));
            }
            insert logs;
        }
    }
}
```

### Batch Size Tuning
- Default batch size: 200.
- For callout-heavy batches: use smaller sizes (e.g., 1-10) since each callout counts.
- For simple field updates: use larger sizes (up to 2000) for throughput.
- QueryLocator can process up to 50 million records; Iterable is limited to 50,000.
- Max 5 active batch jobs simultaneously (100 in Flex Queue).

---

## 5. Continuation Pattern

For long-running HTTP callouts in Visualforce or Lightning (up to 120 seconds). Does not consume an application server thread while waiting.

### Single Continuation Request
```apex
public class ContinuationController {

    @AuraEnabled(continuation=true cacheable=false)
    public static Object startLongRunningCallout() {
        Continuation con = new Continuation(120);
        con.continuationMethod = 'handleResponse';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:LongRunningService/api/process');
        req.setMethod('GET');

        con.addHttpRequest(req);
        return con;
    }

    @AuraEnabled(cacheable=false)
    public static Object handleResponse(List<String> labels, Object state) {
        HttpResponse response = Continuation.getResponse(labels[0]);
        Integer statusCode = response.getStatusCode();

        if (statusCode == 200) {
            return response.getBody();
        } else {
            throw new AuraHandledException(
                'Callout failed with status ' + statusCode
            );
        }
    }
}
```

### Multiple Continuation Requests (up to 3)
```apex
public class MultiContinuationController {

    @AuraEnabled(continuation=true cacheable=false)
    public static Object startParallelCallouts() {
        Continuation con = new Continuation(120);
        con.continuationMethod = 'handleMultiResponse';

        HttpRequest req1 = new HttpRequest();
        req1.setEndpoint('callout:ServiceA/api/data');
        req1.setMethod('GET');

        HttpRequest req2 = new HttpRequest();
        req2.setEndpoint('callout:ServiceB/api/data');
        req2.setMethod('GET');

        HttpRequest req3 = new HttpRequest();
        req3.setEndpoint('callout:ServiceC/api/data');
        req3.setMethod('GET');

        con.addHttpRequest(req1);
        con.addHttpRequest(req2);
        con.addHttpRequest(req3);

        return con;
    }

    @AuraEnabled(cacheable=false)
    public static Object handleMultiResponse(List<String> labels, Object state) {
        Map<String, Object> results = new Map<String, Object>();

        for (Integer i = 0; i < labels.size(); i++) {
            HttpResponse res = Continuation.getResponse(labels[i]);
            results.put('service' + (i + 1), res.getBody());
        }

        return JSON.serialize(results);
    }
}
```

### Limitations
- No DML operations in continuation callback methods.
- Maximum 3 callouts per continuation.
- Maximum timeout: 120 seconds.
- Supported in Visualforce (VF pages) and Lightning (Aura/LWC).

---

## 6. Platform Events

Publish-subscribe messaging for event-driven architecture. Supports cross-org and external system integration.

### Defining and Publishing Events
```apex
public class OrderEventService {

    public static void publishOrderEvents(List<Order> orders, String action) {
        List<Order_Event__e> events = new List<Order_Event__e>();

        for (Order ord : orders) {
            events.add(new Order_Event__e(
                Order_Id__c = ord.Id,
                Action__c = action,
                Amount__c = ord.TotalAmount,
                Processed_At__c = System.now()
            ));
        }

        List<Database.SaveResult> results = EventBus.publish(events);

        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'Event publish error: ' + err.getMessage());
                }
            }
        }
    }
}
```

### Subscriber Trigger
```apex
trigger OrderEventTrigger on Order_Event__e (after insert) {
    List<Task> tasks = new List<Task>();

    for (Order_Event__e event : Trigger.new) {
        if (event.Action__c == 'Created') {
            tasks.add(new Task(
                Subject = 'Follow up on Order ' + event.Order_Id__c,
                WhatId = event.Order_Id__c,
                Status = 'Open',
                Priority = 'High'
            ));
        }
    }

    if (!tasks.isEmpty()) {
        insert tasks;
    }
}
```

### Subscriber with Replay ID and Error Handling
```apex
trigger OrderEventTrigger on Order_Event__e (after insert) {
    for (Order_Event__e event : Trigger.new) {
        try {
            processEvent(event);
        } catch (Exception e) {
            // Set replay ID to retry from this event on next trigger invocation
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(
                event.ReplayId
            );
            throw e;
        }
    }
}
```

### Key Behaviors
- **At-least-once delivery**: subscribers may receive the same event more than once; design for idempotency.
- **Publish after commit**: by default, events publish when the transaction commits. Use `EventBus.publish()` for immediate publish behavior. Use `Publish After Commit` setting on the event definition.
- **Replay ID**: each event gets a unique replay ID for tracking and resumption.
- **Governor limit**: 150,000 events published per hour (Standard Platform Events).
- **Retention**: events are retained for 72 hours (standard) or 24 hours (high-volume).

---

## 7. Change Data Capture (CDC)

Receive near-real-time notifications when Salesforce records change.

### CDC Trigger
```apex
trigger AccountChangeEventTrigger on AccountChangeEvent (after insert) {
    for (AccountChangeEvent event : Trigger.new) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;

        String changeType = header.getChangeType();
        List<String> changedFields = header.getChangedFields();
        String commitUser = header.getCommitUser();
        String transactionKey = header.getTransactionKey();
        Integer sequenceNumber = header.getSequenceNumber();

        if (changeType == 'UPDATE') {
            handleUpdate(event, changedFields, commitUser);
        } else if (changeType == 'CREATE') {
            handleCreate(event, commitUser);
        } else if (changeType == 'DELETE') {
            handleDelete(header.getRecordIds(), commitUser);
        } else if (changeType == 'UNDELETE') {
            handleUndelete(header.getRecordIds(), commitUser);
        }
    }
}
```

### CDC Handler Methods
```apex
public class AccountCDCHandler {

    public static void handleUpdate(
        AccountChangeEvent event,
        List<String> changedFields,
        String commitUser
    ) {
        // Only react to changes NOT made by integration user
        if (commitUser != getIntegrationUserId()) {
            if (changedFields.contains('BillingAddress')) {
                // Sync address to external system
                syncAddressExternally(event);
            }
        }
    }

    public static void handleCreate(AccountChangeEvent event, String commitUser) {
        // Provision in external system
        System.enqueueJob(new ExternalProvisionJob(event));
    }

    public static void handleDelete(List<String> recordIds, String commitUser) {
        // Archive or clean up in external system
        for (String recordId : recordIds) {
            System.enqueueJob(new ExternalCleanupJob(recordId));
        }
    }

    public static void handleUndelete(List<String> recordIds, String commitUser) {
        // Restore in external system
    }

    private static Id getIntegrationUserId() {
        return [SELECT Id FROM User WHERE Username = 'integration@example.com' LIMIT 1].Id;
    }

    private static void syncAddressExternally(AccountChangeEvent event) {
        // Callout logic
    }
}
```

### Testing CDC Triggers
```apex
@IsTest
private class AccountCDCTest {

    @IsTest
    static void testAccountChangeEvent() {
        // Enable CDC in test context
        Test.enableChangeDataCapture();

        Account acc = new Account(Name = 'Test CDC Account');
        insert acc;

        // Deliver the change event
        Test.getEventBus().deliver();

        // Verify the trigger processed the event
        // (assert on side effects like logs, tasks, etc.)
    }

    @IsTest
    static void testAccountUpdateCDC() {
        Test.enableChangeDataCapture();

        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Test.getEventBus().deliver();

        acc.Name = 'Updated Account';
        update acc;
        Test.getEventBus().deliver();

        // Assert on update side effects
    }
}
```

### ChangeEventHeader Fields
| Field              | Description                                      |
|--------------------|--------------------------------------------------|
| changeType         | CREATE, UPDATE, DELETE, UNDELETE, GAP_CREATE, etc. |
| changedFields      | List of field API names that changed              |
| commitUser         | User ID who made the change                      |
| commitTimestamp    | Timestamp of the commit                           |
| transactionKey     | Unique key for the transaction                    |
| sequenceNumber     | Order of the event within the transaction         |
| recordIds          | List of record IDs affected                       |
| changeOrigin       | Origin of the change (e.g., com/salesforce/api)   |
| entityName         | SObject type name                                 |
