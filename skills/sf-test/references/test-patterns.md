# Apex Test Patterns Reference

Complete, compilable code examples for every major Apex test pattern.

---

## 1. Testing @future Methods

`@future` methods execute asynchronously. In tests, they run synchronously between `Test.startTest()` and `Test.stopTest()`.

```apex
public class AccountProcessor {
    @future
    public static void updateAccountRating(Set<Id> accountIds) {
        List<Account> accounts = [SELECT Id, Rating FROM Account WHERE Id IN :accountIds];
        for (Account a : accounts) {
            a.Rating = 'Hot';
        }
        update accounts;
    }
}

@IsTest
private class AccountProcessorTest {
    @IsTest
    static void testUpdateAccountRating() {
        Account acc = new Account(Name = 'Test Account', Rating = 'Cold');
        insert acc;

        Test.startTest();
        AccountProcessor.updateAccountRating(new Set<Id>{ acc.Id });
        Test.stopTest();
        // @future method has now completed

        Account updated = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Hot', updated.Rating, 'Rating should be updated to Hot');
    }
}
```

---

## 2. Testing Batch Apex

Batch jobs run between `Test.startTest()` and `Test.stopTest()`. In test context, `execute()` receives at most 200 records regardless of scope size. Only one `Database.executeBatch` call is allowed per test method.

```apex
public class AccountCleanupBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Description FROM Account WHERE Description = null');
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account a : scope) {
            a.Description = 'Cleaned by batch';
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ 'admin@example.com' });
        mail.setSubject('Batch Complete');
        mail.setPlainTextBody('Account cleanup finished.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
    }
}

@IsTest
private class AccountCleanupBatchTest {
    @TestSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            accounts.add(new Account(Name = 'Test ' + i));
        }
        insert accounts;
    }

    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        Id batchId = Database.executeBatch(new AccountCleanupBatch(), 200);
        Test.stopTest();
        // Batch has completed — start, execute, finish all ran

        List<Account> updated = [SELECT Description FROM Account];
        for (Account a : updated) {
            Assert.areEqual('Cleaned by batch', a.Description, 'Description should be set by batch');
        }

        // Verify the batch job completed
        AsyncApexJob job = [
            SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :batchId
        ];
        Assert.areEqual('Completed', job.Status);
        Assert.areEqual(0, job.NumberOfErrors);
    }
}
```

---

## 3. Testing Queueable Apex

Queueable jobs execute synchronously between `Test.startTest()` and `Test.stopTest()`. In test context, chaining is limited to depth 1 (a queueable can enqueue at most one additional queueable).

```apex
public class AccountEnrichmentQueueable implements Queueable {
    private List<Id> accountIds;

    public AccountEnrichmentQueueable(List<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        List<Account> accounts = [SELECT Id, Industry FROM Account WHERE Id IN :accountIds];
        for (Account a : accounts) {
            a.Industry = 'Technology';
        }
        update accounts;

        // Chaining — allowed to depth 1 in test
        if (!Test.isRunningTest()) {
            // Enqueue follow-up work in production only
            // System.enqueueJob(new FollowUpQueueable());
        }
    }
}

@IsTest
private class AccountEnrichmentQueueableTest {
    @IsTest
    static void testQueueableExecution() {
        Account acc = new Account(Name = 'Queueable Test');
        insert acc;

        Test.startTest();
        System.enqueueJob(new AccountEnrichmentQueueable(new List<Id>{ acc.Id }));
        Test.stopTest();

        Account updated = [SELECT Industry FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Technology', updated.Industry, 'Industry should be set by queueable');
    }

    @IsTest
    static void testQueueableChaining() {
        // In test context, you can verify chain depth 1
        Account acc = new Account(Name = 'Chain Test');
        insert acc;

        Test.startTest();
        Id jobId = System.enqueueJob(new AccountEnrichmentQueueable(new List<Id>{ acc.Id }));
        Test.stopTest();

        // Verify job was created
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        Assert.areEqual('Completed', job.Status);
    }
}
```

---

## 4. Testing Schedulable Apex

Schedule jobs in test context and verify the CronTrigger was created. The scheduled class executes synchronously between `Test.startTest()` and `Test.stopTest()`.

```apex
public class WeeklyAccountReview implements Schedulable {
    public void execute(SchedulableContext sc) {
        List<Account> staleAccounts = [
            SELECT Id, Description
            FROM Account
            WHERE LastModifiedDate < LAST_N_DAYS:90
            LIMIT 200
        ];
        for (Account a : staleAccounts) {
            a.Description = 'Reviewed on ' + Date.today().format();
        }
        if (!staleAccounts.isEmpty()) {
            update staleAccounts;
        }
    }
}

@IsTest
private class WeeklyAccountReviewTest {
    @IsTest
    static void testSchedulableExecution() {
        Account acc = new Account(Name = 'Stale Account');
        insert acc;
        // Backdate LastModifiedDate is not possible directly; test the execute method instead

        Test.startTest();
        // CRON: Every Sunday at midnight
        String cronExp = '0 0 0 ? * SUN';
        String jobId = System.schedule('Weekly Account Review', cronExp, new WeeklyAccountReview());
        Test.stopTest();

        // Verify the CronTrigger was created
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        Assert.areEqual(cronExp, ct.CronExpression, 'Cron expression should match');
        Assert.isNotNull(ct.NextFireTime, 'Next fire time should be set');
    }

    @IsTest
    static void testExecuteDirectly() {
        // Directly invoke execute for unit testing logic
        Account acc = new Account(Name = 'Direct Test');
        insert acc;

        Test.startTest();
        WeeklyAccountReview reviewer = new WeeklyAccountReview();
        reviewer.execute(null);
        Test.stopTest();
    }
}
```

---

## 5. Platform Event Testing

Use `EventBus.publish()` to publish events and `Test.getEventBus().deliver()` to force synchronous delivery to subscribers in test context.

```apex
// Platform Event: Order_Event__e with fields: Order_Id__c (Text), Status__c (Text)

public class OrderEventPublisher {
    public static void publishOrderEvent(String orderId, String status) {
        Order_Event__e evt = new Order_Event__e(
            Order_Id__c = orderId,
            Status__c = status
        );
        Database.SaveResult sr = EventBus.publish(evt);
        if (!sr.isSuccess()) {
            for (Database.Error err : sr.getErrors()) {
                System.debug('Error publishing event: ' + err.getMessage());
            }
        }
    }
}

// Trigger subscriber
trigger OrderEventTrigger on Order_Event__e (after insert) {
    List<Task> tasks = new List<Task>();
    for (Order_Event__e evt : Trigger.New) {
        tasks.add(new Task(
            Subject = 'Order ' + evt.Order_Id__c + ' - ' + evt.Status__c,
            Status = 'Open',
            Priority = 'High'
        ));
    }
    insert tasks;
}

@IsTest
private class OrderEventPublisherTest {
    @IsTest
    static void testPlatformEventPublishAndSubscribe() {
        Test.startTest();
        OrderEventPublisher.publishOrderEvent('ORD-001', 'Shipped');

        // Deliver the event to subscribers synchronously
        Test.getEventBus().deliver();
        Test.stopTest();

        // Assert subscriber (trigger) created a Task
        List<Task> tasks = [SELECT Subject FROM Task WHERE Subject LIKE 'Order ORD-001%'];
        Assert.areEqual(1, tasks.size(), 'One task should be created by event subscriber');
        Assert.isTrue(tasks[0].Subject.contains('Shipped'), 'Task subject should contain status');
    }
}
```

---

## 6. Change Data Capture Testing

Enable CDC in tests with `Test.enableChangeDataCapture()`, then deliver events with `Test.getEventBus().deliver()`.

```apex
// CDC trigger on AccountChangeEvent
trigger AccountChangeTrigger on AccountChangeEvent (after insert) {
    for (AccountChangeEvent evt : Trigger.New) {
        EventBus.ChangeEventHeader header = evt.ChangeEventHeader;
        if (header.getChangeType() == 'UPDATE') {
            List<String> changedFields = header.getChangedFields();
            // Log changes to a custom object
            for (String recordId : header.getRecordIds()) {
                Change_Log__c log = new Change_Log__c(
                    Record_Id__c = recordId,
                    Changed_Fields__c = String.join(changedFields, ', '),
                    Change_Type__c = 'UPDATE'
                );
                insert log;
            }
        }
    }
}

@IsTest
private class AccountChangeTriggerTest {
    @IsTest
    static void testCDCTrigger() {
        // Enable CDC for Account in this test
        Test.enableChangeDataCapture();

        Account acc = new Account(Name = 'CDC Test');
        insert acc;

        // Deliver the INSERT CDC event
        Test.getEventBus().deliver();

        // Now update to generate an UPDATE CDC event
        acc.Phone = '555-1234';
        update acc;

        // Deliver the UPDATE CDC event to the trigger
        Test.getEventBus().deliver();

        // Assert the CDC trigger created a change log
        List<Change_Log__c> logs = [
            SELECT Record_Id__c, Change_Type__c
            FROM Change_Log__c
            WHERE Record_Id__c = :acc.Id AND Change_Type__c = 'UPDATE'
        ];
        Assert.areEqual(1, logs.size(), 'CDC trigger should have logged the update');
    }
}
```

---

## 7. Stub API (System.StubProvider)

Use `System.StubProvider` for mocking dependencies. Combine with dependency injection for testable architecture.

```apex
// Interface for the dependency
public interface IAccountService {
    List<Account> getAccountsByIndustry(String industry);
    Boolean updateAccountRating(Id accountId, String rating);
}

// Production implementation
public class AccountService implements IAccountService {
    public List<Account> getAccountsByIndustry(String industry) {
        return [SELECT Id, Name, Rating FROM Account WHERE Industry = :industry];
    }

    public Boolean updateAccountRating(Id accountId, String rating) {
        Account acc = new Account(Id = accountId, Rating = rating);
        update acc;
        return true;
    }
}

// Class under test that depends on IAccountService
public class AccountAnalyzer {
    private IAccountService service;

    public AccountAnalyzer(IAccountService service) {
        this.service = service;
    }

    public Integer countHotAccounts(String industry) {
        List<Account> accounts = service.getAccountsByIndustry(industry);
        Integer count = 0;
        for (Account a : accounts) {
            if (a.Rating == 'Hot') {
                count++;
            }
        }
        return count;
    }
}

// StubProvider implementation
@IsTest
private class AccountServiceStub implements System.StubProvider {
    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        if (stubbedMethodName == 'getAccountsByIndustry') {
            // Return mock data — no DML or SOQL needed
            return new List<Account>{
                new Account(Name = 'Mock Account 1', Rating = 'Hot'),
                new Account(Name = 'Mock Account 2', Rating = 'Cold'),
                new Account(Name = 'Mock Account 3', Rating = 'Hot')
            };
        }
        if (stubbedMethodName == 'updateAccountRating') {
            return true;
        }
        return null;
    }
}

@IsTest
private class AccountAnalyzerTest {
    @IsTest
    static void testCountHotAccountsWithStub() {
        // Create the stub
        AccountServiceStub stubProvider = new AccountServiceStub();
        IAccountService mockService = (IAccountService) Test.createStub(
            IAccountService.class,
            stubProvider
        );

        // Inject the mock
        AccountAnalyzer analyzer = new AccountAnalyzer(mockService);

        Test.startTest();
        Integer hotCount = analyzer.countHotAccounts('Technology');
        Test.stopTest();

        Assert.areEqual(2, hotCount, 'Should count 2 hot accounts from mock data');
    }
}
```

---

## 8. Test.loadData()

Load test data from a CSV file stored as a Static Resource. The CSV must have column headers matching API field names. The Id column should be present but left blank.

```apex
/*
 * Static Resource: TestAccounts (MIME type: text/csv)
 * CSV contents:
 *
 * Name,Industry,Rating,Phone
 * Acme Corp,Technology,Hot,555-0001
 * Globex Inc,Finance,Warm,555-0002
 * Initech,Technology,Cold,555-0003
 */

@IsTest
private class DataLoadTest {
    @IsTest
    static void testLoadDataFromStaticResource() {
        // Load Account records from static resource CSV
        List<SObject> accounts = Test.loadData(Account.SObjectType, 'TestAccounts');

        Assert.areEqual(3, accounts.size(), 'Should load 3 accounts from CSV');

        // Records are inserted and have Ids
        for (SObject acc : accounts) {
            Assert.isNotNull(acc.Id, 'Each record should have an Id after load');
        }

        // Verify data was inserted into the database
        List<Account> queriedAccounts = [SELECT Name, Industry FROM Account ORDER BY Name];
        Assert.areEqual(3, queriedAccounts.size());
        Assert.areEqual('Acme Corp', queriedAccounts[0].Name);
    }

    @IsTest
    static void testLoadRelatedData() {
        /*
         * Static Resource: TestContacts (MIME type: text/csv)
         * CSV contents:
         *
         * LastName,Email,AccountId
         * Smith,smith@test.com,
         * Jones,jones@test.com,
         *
         * Note: AccountId is left blank. You must associate records manually
         * or load the parent first and reference by external ID.
         */
        List<SObject> accounts = Test.loadData(Account.SObjectType, 'TestAccounts');
        List<SObject> contacts = Test.loadData(Contact.SObjectType, 'TestContacts');

        // Associate contacts to accounts manually
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Integer i = 0; i < contacts.size() && i < accounts.size(); i++) {
            Contact c = (Contact) contacts[i];
            c.AccountId = accounts[i].Id;
            contactsToUpdate.add(c);
        }
        update contactsToUpdate;
    }
}
```

---

## 9. REST Endpoint Testing

Test `@RestResource` classes by setting `RestContext.request` and `RestContext.response` manually.

```apex
@RestResource(urlMapping='/accounts/*')
global class AccountRestService {
    @HttpGet
    global static Account getAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        return [SELECT Id, Name, Industry FROM Account WHERE Id = :accountId LIMIT 1];
    }

    @HttpPost
    global static Account createAccount(String name, String industry) {
        Account acc = new Account(Name = name, Industry = industry);
        insert acc;
        return acc;
    }

    @HttpPut
    global static Account upsertAccount(String name, String industry, String externalId) {
        Account acc = new Account(Name = name, Industry = industry);
        // Upsert by external ID field
        upsert acc;
        return acc;
    }

    @HttpDelete
    global static void deleteAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
        delete acc;
    }
}

@IsTest
private class AccountRestServiceTest {
    @IsTest
    static void testGetAccount() {
        Account acc = new Account(Name = 'REST Test');
        insert acc;

        // Set up the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/accounts/' + acc.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        Account result = AccountRestService.getAccount();
        Test.stopTest();

        Assert.areEqual('REST Test', result.Name);
    }

    @IsTest
    static void testCreateAccount() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/accounts/';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"name":"New REST Account","industry":"Technology"}');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        Account result = AccountRestService.createAccount('New REST Account', 'Technology');
        Test.stopTest();

        Assert.isNotNull(result.Id, 'Account should be inserted with an Id');
        Assert.areEqual('New REST Account', result.Name);
    }

    @IsTest
    static void testDeleteAccount() {
        Account acc = new Account(Name = 'Delete Me');
        insert acc;

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/accounts/' + acc.Id;
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        AccountRestService.deleteAccount();
        Test.stopTest();

        List<Account> remaining = [SELECT Id FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(0, remaining.size(), 'Account should be deleted');
    }
}
```

---

## 10. Mixed DML Workaround

Setup objects (User, Profile, PermissionSet, Group) and non-setup objects (Account, Contact) cannot be DML'd in the same transaction. Use `System.runAs()` to create a separate execution context.

```apex
@IsTest
private class MixedDMLTest {
    @IsTest
    static void testMixedDMLWithRunAs() {
        // Step 1: Create setup object (User) in the main context
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'mixdml',
            Email = 'mixeddml@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'MixedDML',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'mixeddml' + DateTime.now().getTime() + '@test.com'
        );
        insert testUser;

        // Step 2: Use System.runAs() to create non-setup objects
        // This creates a separate transaction context, avoiding mixed DML
        System.runAs(testUser) {
            Account acc = new Account(Name = 'Mixed DML Account');
            insert acc;

            Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id
            );
            insert con;

            Assert.isNotNull(acc.Id, 'Account should be inserted');
            Assert.isNotNull(con.Id, 'Contact should be inserted');
        }
    }

    @IsTest
    static void testAssignPermissionSetAndCreateData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'prmset',
            Email = 'permset@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'PermSet',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'permset' + DateTime.now().getTime() + '@test.com'
        );
        insert testUser;

        // Assign permission set (setup DML)
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'My_Custom_Permission_Set' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;

        // Non-setup DML in runAs
        System.runAs(testUser) {
            Account acc = new Account(Name = 'PermSet Test Account');
            insert acc;
            Assert.isNotNull(acc.Id);
        }
    }
}
```

---

## 11. Product/PricebookEntry Testing

Use `Test.getStandardPricebookId()` to get the Standard Pricebook Id in test context. Create Product2, then PricebookEntry records.

```apex
@IsTest
private class ProductPricebookTest {
    @IsTest
    static void testCreateProductWithPricebookEntry() {
        // Get the standard pricebook ID (works in test context)
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create product
        Product2 prod = new Product2(
            Name = 'Test Widget',
            ProductCode = 'WIDGET-001',
            IsActive = true,
            Family = 'Hardware'
        );
        insert prod;

        // Create standard price book entry (required before custom)
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPbe;

        // Create custom pricebook
        Pricebook2 customPb = new Pricebook2(
            Name = 'Partner Pricebook',
            IsActive = true
        );
        insert customPb;

        // Create custom pricebook entry
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 80.00,
            IsActive = true
        );
        insert customPbe;

        // Verify
        List<PricebookEntry> entries = [
            SELECT UnitPrice, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :prod.Id
        ];
        Assert.areEqual(2, entries.size(), 'Should have standard and custom PBE');
    }

    @IsTest
    static void testCreateOpportunityWithProducts() {
        Id standardPricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(Name = 'Enterprise License', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 5000.00,
            IsActive = true
        );
        insert pbe;

        Account acc = new Account(Name = 'Opp Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Big Deal',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = standardPricebookId
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 5000.00
        );
        insert oli;

        Opportunity result = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual(50000.00, result.Amount, 'Amount should be quantity * unit price');
    }
}
```

---

## 12. Email Service Testing

Test outbound emails with `Messaging.sendEmail()`. In test context, emails are not actually sent but the method returns success. Use `Limits.getEmailInvocations()` to verify.

```apex
public class WelcomeEmailService {
    public static void sendWelcomeEmail(List<Contact> contacts) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Contact c : contacts) {
            if (String.isNotBlank(c.Email)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{ c.Email });
                mail.setSubject('Welcome, ' + c.FirstName + '!');
                mail.setPlainTextBody('Thank you for joining us, ' + c.FirstName + ' ' + c.LastName + '.');
                mail.setSaveAsActivity(false);
                emails.add(mail);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    public static void sendEmailWithTemplate(Id contactId, Id templateId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(contactId);
        mail.setTemplateId(templateId);
        mail.setSaveAsActivity(true);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
    }
}

@IsTest
private class WelcomeEmailServiceTest {
    @IsTest
    static void testSendWelcomeEmail() {
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Alice', LastName = 'Smith', Email = 'alice@test.com'),
            new Contact(FirstName = 'Bob', LastName = 'Jones', Email = 'bob@test.com'),
            new Contact(FirstName = 'NoEmail', LastName = 'User') // no email, should be skipped
        };
        insert contacts;

        // Re-query to get inserted contacts with emails
        contacts = [SELECT FirstName, LastName, Email FROM Contact WHERE Id IN :contacts];

        Test.startTest();
        WelcomeEmailService.sendWelcomeEmail(contacts);
        Test.stopTest();

        // Verify emails were invoked (not actually sent in test)
        Assert.areEqual(1, Limits.getEmailInvocations(), 'sendEmail should be called once');
    }

    @IsTest
    static void testSendEmailReturnsResults() {
        Contact c = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@example.com');
        insert c;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ 'test@example.com' });
        mail.setSubject('Test');
        mail.setPlainTextBody('Body');

        Test.startTest();
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
            new Messaging.SingleEmailMessage[]{ mail }
        );
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess(), 'Email send should succeed in test context');
    }
}
```

---

## 13. Flow Test Coverage

Query `FlowTestCoverage` to assert flow test coverage. Flow tests are defined in metadata and executed alongside Apex tests.

```apex
@IsTest
private class FlowTestCoverageTest {
    @IsTest
    static void testFlowCoverage() {
        // Create data that triggers a record-triggered flow
        // Example: a flow that fires on Account insert and sets Description
        Account acc = new Account(
            Name = 'Flow Test Account',
            Industry = 'Technology'
        );

        Test.startTest();
        insert acc;
        Test.stopTest();

        // Query the account to verify flow executed
        Account result = [SELECT Description FROM Account WHERE Id = :acc.Id];
        // Assert based on what the flow does
        // Assert.isNotNull(result.Description, 'Flow should have set Description');
    }

    @IsTest
    static void verifyFlowTestCoverage() {
        // Query FlowTestCoverage to check coverage of a specific flow
        // This is available after deploying flow tests via metadata
        /*
        List<FlowTestCoverage> coverage = [
            SELECT FlowVersionId, NumElementsCovered, NumElementsNotCovered,
                   TestMethodName, FlowVersion.FlowDefinitionView.ApiName
            FROM FlowTestCoverage
        ];

        for (FlowTestCoverage ftc : coverage) {
            Integer total = ftc.NumElementsCovered + ftc.NumElementsNotCovered;
            if (total > 0) {
                Decimal pct = (Decimal) ftc.NumElementsCovered / total * 100;
                System.debug(ftc.FlowVersion.FlowDefinitionView.ApiName + ': ' + pct + '% covered');
                Assert.isTrue(pct >= 75, 'Flow coverage should be at least 75%');
            }
        }
        */
    }
}
```

---

## 14. Advanced Assertion Patterns

Use the `Assert` class (Winter '23+) for modern assertions. It replaces `System.assert()`, `System.assertEquals()`, and `System.assertNotEquals()`.

```apex
@IsTest
private class AdvancedAssertionTest {

    // --- Assert.areEqual / Assert.areNotEqual ---
    @IsTest
    static void testAreEqual() {
        String expected = 'Hello';
        String actual = 'Hello';
        Assert.areEqual(expected, actual, 'Strings should match');
        Assert.areNotEqual('Goodbye', actual, 'Should not be Goodbye');
    }

    // --- Assert.isTrue / Assert.isFalse ---
    @IsTest
    static void testBooleanAssertions() {
        Boolean isActive = true;
        Assert.isTrue(isActive, 'Should be active');
        Assert.isFalse(!isActive, 'Double negation should be true');
    }

    // --- Assert.isNull / Assert.isNotNull ---
    @IsTest
    static void testNullAssertions() {
        Account acc = new Account(Name = 'Null Test');
        insert acc;
        Assert.isNotNull(acc.Id, 'Id should be populated after insert');

        Account nullAcc = null;
        // Assert.isNull(nullAcc, 'Should be null');
    }

    // --- Assert.fail ---
    @IsTest
    static void testExpectedException() {
        try {
            // Code that should throw an exception
            Account acc = new Account(); // Name is required
            insert acc;
            Assert.fail('DmlException should have been thrown');
        } catch (DmlException e) {
            Assert.isTrue(
                e.getMessage().containsIgnoreCase('required'),
                'Error should mention required field: ' + e.getMessage()
            );
        }
    }

    // --- Assert.isInstanceOfType ---
    @IsTest
    static void testInstanceType() {
        Exception ex = new DmlException('test');
        Assert.isInstanceOfType(ex, DmlException.class, 'Should be a DmlException');
    }

    // --- Custom Assertion Helper ---
    static void assertAccountHasIndustry(Id accountId, String expectedIndustry) {
        Account acc = [SELECT Industry FROM Account WHERE Id = :accountId];
        Assert.areEqual(
            expectedIndustry,
            acc.Industry,
            'Account ' + accountId + ' should have industry ' + expectedIndustry
                + ' but had ' + acc.Industry
        );
    }

    @IsTest
    static void testCustomAssertionHelper() {
        Account acc = new Account(Name = 'Helper Test', Industry = 'Technology');
        insert acc;
        assertAccountHasIndustry(acc.Id, 'Technology');
    }

    // --- Bulk Assertion Pattern ---
    @IsTest
    static void testBulkAssertions() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Bulk Test ' + i, Industry = 'Technology'));
        }
        insert accounts;

        // Trigger or automation runs...

        // Assert every record in bulk
        List<Account> results = [SELECT Name, Industry FROM Account WHERE Name LIKE 'Bulk Test%'];
        Assert.areEqual(200, results.size(), 'All 200 accounts should exist');
        for (Account a : results) {
            Assert.areEqual('Technology', a.Industry, 'Industry should remain Technology for ' + a.Name);
        }
    }

    // --- Limits Assertion ---
    @IsTest
    static void testGovernorLimitsAssertion() {
        Test.startTest();

        // Perform operations
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            accounts.add(new Account(Name = 'Limits Test ' + i));
        }
        insert accounts;

        // Assert SOQL and DML usage is efficient
        Assert.isTrue(Limits.getQueries() <= 5, 'Should use 5 or fewer SOQL queries, used: ' + Limits.getQueries());
        Assert.isTrue(Limits.getDmlStatements() <= 3, 'Should use 3 or fewer DML statements, used: ' + Limits.getDmlStatements());

        Test.stopTest();
    }
}
```
