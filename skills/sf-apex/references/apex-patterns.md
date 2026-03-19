# Apex Design Patterns Reference

## Trigger Handler Framework

### Base Handler
```apex
public virtual class TriggerHandler {
    @TestVisible
    private static Set<String> bypassedHandlers = new Set<String>();

    public void run() {
        if (bypassedHandlers.contains(getHandlerName())) return;

        if (Trigger.isBefore) {
            if (Trigger.isInsert) beforeInsert();
            if (Trigger.isUpdate) beforeUpdate();
            if (Trigger.isDelete) beforeDelete();
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) afterInsert();
            if (Trigger.isUpdate) afterUpdate();
            if (Trigger.isDelete) afterDelete();
            if (Trigger.isUndelete) afterUndelete();
        }
    }

    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    private String getHandlerName() {
        return String.valueOf(this).split(':')[0];
    }

    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}
}
```

### Handler Implementation
```apex
public with sharing class AccountTriggerHandler extends TriggerHandler {
    private List<Account> newRecords;
    private Map<Id, Account> oldMap;

    public AccountTriggerHandler() {
        this.newRecords = (List<Account>) Trigger.new;
        this.oldMap = (Map<Id, Account>) Trigger.oldMap;
    }

    protected override void beforeInsert() {
        AccountService.setDefaults(newRecords);
    }

    protected override void afterUpdate() {
        List<Account> nameChanged = new List<Account>();
        for (Account acc : newRecords) {
            if (acc.Name != oldMap.get(acc.Id).Name) {
                nameChanged.add(acc);
            }
        }
        if (!nameChanged.isEmpty()) {
            AccountService.syncContactAddresses(nameChanged);
        }
    }
}
```

## Service Layer Pattern
```apex
public with sharing class AccountService {

    public static void setDefaults(List<Account> accounts) {
        for (Account acc : accounts) {
            if (acc.Industry == null) {
                acc.Industry = 'Other';
            }
        }
    }

    public static void syncContactAddresses(List<Account> accounts) {
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
        List<Contact> contacts = [
            SELECT Id, AccountId, MailingStreet
            FROM Contact
            WHERE AccountId IN :accountIds
            WITH USER_MODE
        ];
        // Update logic...
    }
}
```

## Selector Pattern
```apex
public with sharing class AccountSelector {

    public static List<Account> getByIds(Set<Id> ids) {
        return [
            SELECT Id, Name, Industry, BillingStreet
            FROM Account
            WHERE Id IN :ids
            WITH USER_MODE
        ];
    }

    public static List<Account> getByIndustry(String industry) {
        return [
            SELECT Id, Name, Industry
            FROM Account
            WHERE Industry = :industry
            WITH USER_MODE
            LIMIT 200
        ];
    }

    public static List<Account> getWithContacts(Set<Id> ids) {
        return [
            SELECT Id, Name,
                (SELECT Id, FirstName, LastName, Email FROM Contacts)
            FROM Account
            WHERE Id IN :ids
            WITH USER_MODE
        ];
    }
}
```

## Batch Apex Pattern
```apex
public with sharing class AccountCleanupBatch implements
    Database.Batchable<SObject>, Database.Stateful {

    private Integer processedCount = 0;
    private List<String> errors = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, LastActivityDate
            FROM Account
            WHERE LastActivityDate < LAST_N_YEARS:2
            WITH USER_MODE
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account acc : scope) {
            acc.Status__c = 'Inactive';
        }
        List<Database.SaveResult> results = Database.update(scope, false);
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                processedCount++;
            } else {
                errors.add(sr.getErrors()[0].getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Processed: ' + processedCount + ', Errors: ' + errors.size());
    }
}
```

## Queueable Pattern
```apex
public with sharing class AccountProcessingJob implements Queueable, Database.AllowsCallouts {

    private List<Id> accountIds;

    public AccountProcessingJob(List<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        List<Account> accounts = AccountSelector.getByIds(new Set<Id>(accountIds));
        // Process accounts
        // Chain another job if needed
        if (!remainingIds.isEmpty()) {
            System.enqueueJob(new AccountProcessingJob(remainingIds));
        }
    }
}
```

## Platform Event Pattern
```apex
// Publisher
public with sharing class OrderEventPublisher {
    public static void publishOrderCreated(List<Order> orders) {
        List<Order_Event__e> events = new List<Order_Event__e>();
        for (Order ord : orders) {
            events.add(new Order_Event__e(
                Order_Id__c = ord.Id,
                Action__c = 'Created'
            ));
        }
        EventBus.publish(events);
    }
}

// Subscriber (Trigger)
trigger OrderEventTrigger on Order_Event__e (after insert) {
    OrderEventHandler.handleEvents(Trigger.new);
}
```

## Custom Exception Pattern
```apex
public class AccountServiceException extends Exception {

    private String errorCode;
    private Id recordId;

    public AccountServiceException(String message, String errorCode, Id recordId) {
        this(message);
        this.errorCode = errorCode;
        this.recordId = recordId;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public Id getRecordId() {
        return recordId;
    }
}

// Usage:
// throw new AccountServiceException(
//     'Account not found in external system',
//     'EXT_NOT_FOUND',
//     accountId
// );

// Catching:
// try {
//     AccountService.syncExternal(accountId);
// } catch (AccountServiceException e) {
//     System.debug('Error ' + e.getErrorCode() + ' for record ' + e.getRecordId());
//     System.debug(e.getMessage());
//     System.debug(e.getStackTraceString());
// }
```

## JSON Serialization/Deserialization
```apex
public class JsonPatterns {

    // --- Typed Serialization ---
    public class AccountDTO {
        public String name;
        public String industry;
        public transient String internalNote; // excluded from serialization
        public List<ContactDTO> contacts;
    }

    public class ContactDTO {
        public String firstName;
        public String lastName;
        public String email;
    }

    public static String serializeAccounts(List<Account> accounts) {
        List<AccountDTO> dtos = new List<AccountDTO>();
        for (Account acc : accounts) {
            AccountDTO dto = new AccountDTO();
            dto.name = acc.Name;
            dto.industry = acc.Industry;
            dto.internalNote = 'This will not serialize';
            dto.contacts = new List<ContactDTO>();
            dtos.add(dto);
        }
        // JSON.serialize() converts Apex objects to JSON strings
        return JSON.serialize(dtos);
    }

    // --- Typed Deserialization ---
    public static List<AccountDTO> deserializeAccounts(String jsonString) {
        // JSON.deserialize() converts JSON to typed Apex objects
        return (List<AccountDTO>) JSON.deserialize(
            jsonString, List<AccountDTO>.class
        );
    }

    // --- Untyped Deserialization (for dynamic/unknown JSON) ---
    public static void processUntypedJson(String jsonString) {
        Map<String, Object> root =
            (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        String name = (String) root.get('name');
        Integer count = (Integer) root.get('count');
        List<Object> items = (List<Object>) root.get('items');

        for (Object item : items) {
            Map<String, Object> itemMap = (Map<String, Object>) item;
            System.debug('Item: ' + itemMap.get('label'));
        }
    }

    // --- Pretty Print ---
    public static String serializePretty(Object obj) {
        return JSON.serializePretty(obj);
    }

    // --- Suppress Nulls ---
    public static String serializeNoNulls(Object obj) {
        return JSON.serialize(obj, true); // suppressApexObjectNulls = true
    }
}
```

## Dynamic Apex
```apex
public class DynamicApexPatterns {

    // --- Dynamic Class Instantiation ---
    public static Object createInstance(String className) {
        Type t = Type.forName(className);
        if (t == null) {
            throw new TypeException('Class not found: ' + className);
        }
        return t.newInstance();
    }

    // Example: dynamically instantiate a handler
    public static void runHandler(String handlerClassName) {
        Type handlerType = Type.forName(handlerClassName);
        TriggerHandler handler = (TriggerHandler) handlerType.newInstance();
        handler.run();
    }

    // --- Schema Describe for Runtime Metadata ---
    public static Map<String, Schema.SObjectType> getAllObjects() {
        return Schema.getGlobalDescribe();
    }

    public static List<String> getFieldNames(String objectName) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            throw new TypeException('Object not found: ' + objectName);
        }

        Map<String, Schema.SObjectField> fieldMap =
            objType.getDescribe().fields.getMap();

        List<String> fieldNames = new List<String>();
        for (String fieldName : fieldMap.keySet()) {
            fieldNames.add(fieldName);
        }
        fieldNames.sort();
        return fieldNames;
    }

    public static Schema.DescribeFieldResult getFieldDescribe(
        String objectName,
        String fieldName
    ) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.SObjectField field = objType.getDescribe().fields.getMap().get(fieldName);
        return field.getDescribe();
    }

    // --- Dynamic SOQL ---
    public static List<SObject> dynamicQuery(
        String objectName,
        List<String> fields,
        String whereClause,
        Integer limitRows
    ) {
        String query = 'SELECT ' + String.join(fields, ', ') +
            ' FROM ' + objectName;
        if (String.isNotBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        query += ' LIMIT ' + limitRows;
        return Database.query(query);
    }
}
```

## Custom Metadata Retrieval
```apex
public class CustomMetadataService {

    // --- getInstance() — retrieve a single record by DeveloperName ---
    public static Discount_Tier__mdt getDiscountTier(String tierName) {
        Discount_Tier__mdt tier = Discount_Tier__mdt.getInstance(tierName);
        if (tier == null) {
            throw new QueryException('Discount tier not found: ' + tierName);
        }
        return tier;
    }

    // --- getAll() — retrieve all records (cached, no SOQL cost) ---
    public static Map<String, Discount_Tier__mdt> getAllDiscountTiers() {
        return Discount_Tier__mdt.getAll();
    }

    // --- SOQL-based access (counts toward SOQL limit but supports filtering) ---
    public static List<Discount_Tier__mdt> getActiveTiers() {
        return [
            SELECT DeveloperName, MasterLabel, Discount_Percent__c,
                   Min_Amount__c, Is_Active__c
            FROM Discount_Tier__mdt
            WHERE Is_Active__c = true
            ORDER BY Min_Amount__c
        ];
    }

    // --- Practical usage: config-driven logic ---
    public static Decimal getDiscountRate(Decimal amount) {
        Map<String, Discount_Tier__mdt> allTiers = Discount_Tier__mdt.getAll();
        Decimal bestRate = 0;
        for (Discount_Tier__mdt tier : allTiers.values()) {
            if (tier.Is_Active__c && amount >= tier.Min_Amount__c) {
                if (tier.Discount_Percent__c > bestRate) {
                    bestRate = tier.Discount_Percent__c;
                }
            }
        }
        return bestRate;
    }
}

// Caching behavior:
// - getInstance() and getAll() use the metadata cache (no SOQL query consumed).
// - Results are cached for the transaction; changes deployed mid-transaction are NOT reflected.
// - SOQL queries against __mdt DO count toward SOQL limits but always reflect current metadata.
```

## Custom Settings (Hierarchy)
```apex
public class CustomSettingsService {

    // --- Org defaults ---
    public static App_Config__c getOrgDefaults() {
        App_Config__c config = App_Config__c.getOrgDefaults();
        return config;
    }

    // --- Current user's effective value (hierarchy resolution) ---
    public static App_Config__c getCurrentUserConfig() {
        // Resolves: User -> Profile -> Org Defaults (most specific wins)
        App_Config__c config = App_Config__c.getInstance();
        return config;
    }

    // --- Specific user's value ---
    public static App_Config__c getUserConfig(Id userId) {
        App_Config__c config = App_Config__c.getInstance(userId);
        return config;
    }

    // --- Specific profile's value ---
    public static App_Config__c getProfileConfig(Id profileId) {
        App_Config__c config = App_Config__c.getValues(profileId);
        return config;
    }

    // --- Practical usage ---
    public static Boolean isFeatureEnabled(String featureName) {
        App_Config__c config = App_Config__c.getInstance();
        if (config == null) return false;

        // Access fields dynamically or use known fields
        if (featureName == 'EnableSync') {
            return config.Enable_Sync__c;
        } else if (featureName == 'EnableNotifications') {
            return config.Enable_Notifications__c;
        }
        return false;
    }

    // --- Creating/updating org defaults programmatically ---
    public static void setOrgDefaults(Boolean enableSync, Integer batchSize) {
        App_Config__c config = App_Config__c.getOrgDefaults();
        if (config.Id == null) {
            config = new App_Config__c(SetupOwnerId = UserInfo.getOrganizationId());
        }
        config.Enable_Sync__c = enableSync;
        config.Batch_Size__c = batchSize;
        upsert config;
    }
}
```

## Apex Managed Sharing
```apex
public class ManagedSharingService {

    // --- Share an Account with a user ---
    public static void shareAccountWithUser(
        Id accountId,
        Id userId,
        String accessLevel
    ) {
        AccountShare share = new AccountShare();
        share.AccountId = accountId;
        share.UserOrGroupId = userId;
        share.AccountAccessLevel = accessLevel;   // 'Read', 'Edit', 'All'
        share.OpportunityAccessLevel = 'Read';     // Required for AccountShare
        share.CaseAccessLevel = 'Read';            // Required for AccountShare
        share.RowCause = Schema.AccountShare.RowCause.Manual;
        insert share;
    }

    // --- Share an Opportunity ---
    public static void shareOpportunityWithUser(
        Id opportunityId,
        Id userId,
        String accessLevel
    ) {
        OpportunityShare share = new OpportunityShare();
        share.OpportunityId = opportunityId;
        share.UserOrGroupId = userId;
        share.OpportunityAccessLevel = accessLevel; // 'Read' or 'Edit'
        share.RowCause = Schema.OpportunityShare.RowCause.Manual;
        insert share;
    }

    // --- Share a custom object with Apex sharing reason ---
    public static void shareCustomObject(
        Id recordId,
        Id userId,
        String accessLevel
    ) {
        Project__Share share = new Project__Share();
        share.ParentId = recordId;
        share.UserOrGroupId = userId;
        share.AccessLevel = accessLevel;           // 'Read' or 'Edit'
        share.RowCause = Schema.Project__Share.RowCause.Team_Member__c;
        insert share;
    }

    // --- Bulk sharing ---
    public static void bulkShareRecords(
        List<Id> recordIds,
        List<Id> userIds,
        String accessLevel
    ) {
        List<Project__Share> shares = new List<Project__Share>();
        for (Id recordId : recordIds) {
            for (Id userId : userIds) {
                Project__Share share = new Project__Share();
                share.ParentId = recordId;
                share.UserOrGroupId = userId;
                share.AccessLevel = accessLevel;
                share.RowCause = Schema.Project__Share.RowCause.Team_Member__c;
                shares.add(share);
            }
        }
        Database.insert(shares, false);
    }

    // --- Remove sharing ---
    public static void removeSharing(Id recordId, Id userId) {
        List<Project__Share> shares = [
            SELECT Id
            FROM Project__Share
            WHERE ParentId = :recordId
            AND UserOrGroupId = :userId
            AND RowCause = :Schema.Project__Share.RowCause.Team_Member__c
        ];
        if (!shares.isEmpty()) {
            delete shares;
        }
    }
}

// Notes:
// - Apex sharing reasons (RowCause) are defined on the custom object under Sharing Reasons.
// - Only available for custom objects; standard objects use Manual row cause.
// - Sharing reasons prevent sharing records from being deleted when the owner changes.
// - The org must have a sharing model of Private or Public Read Only for sharing rules to take effect.
```

## Custom Iterator
```apex
// --- Iterator interface ---
public class AccountIterator implements Iterator<Account> {

    private List<Account> accounts;
    private Integer currentIndex;

    public AccountIterator(List<Account> accounts) {
        this.accounts = accounts;
        this.currentIndex = 0;
    }

    public Boolean hasNext() {
        return currentIndex < accounts.size();
    }

    public Account next() {
        if (!hasNext()) {
            throw new NoSuchElementException('No more elements');
        }
        return accounts[currentIndex++];
    }
}

// --- Iterable interface (used with Database.Batchable<T>) ---
public class AccountIterable implements Iterable<Account> {

    private List<Account> accounts;

    public AccountIterable(List<Account> accounts) {
        this.accounts = accounts;
    }

    public Iterator<Account> iterator() {
        return new AccountIterator(accounts);
    }
}

// --- Using with Batch Apex ---
public class CustomIteratorBatch implements Database.Batchable<Account> {

    private List<Account> sourceAccounts;

    public CustomIteratorBatch(List<Account> accounts) {
        this.sourceAccounts = accounts;
    }

    public Iterable<Account> start(Database.BatchableContext bc) {
        return new AccountIterable(sourceAccounts);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account acc : scope) {
            acc.Description = 'Batch processed';
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Custom iterator batch complete.');
    }
}

// --- Practical example: chunked iterator for large datasets ---
public class ChunkedIterator implements Iterator<List<SObject>>, Iterable<List<SObject>> {

    private List<SObject> records;
    private Integer chunkSize;
    private Integer currentIndex;

    public ChunkedIterator(List<SObject> records, Integer chunkSize) {
        this.records = records;
        this.chunkSize = chunkSize;
        this.currentIndex = 0;
    }

    public Boolean hasNext() {
        return currentIndex < records.size();
    }

    public List<SObject> next() {
        List<SObject> chunk = new List<SObject>();
        Integer endIndex = Math.min(currentIndex + chunkSize, records.size());
        for (Integer i = currentIndex; i < endIndex; i++) {
            chunk.add(records[i]);
        }
        currentIndex = endIndex;
        return chunk;
    }

    public Iterator<List<SObject>> iterator() {
        return this;
    }
}
```
