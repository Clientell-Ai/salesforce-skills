# Salesforce Security Patterns Reference

## CRUD/FLS Enforcement

### SOQL — User Mode
```apex
// Enforces both CRUD and FLS automatically
List<Account> accounts = [
    SELECT Id, Name, Industry
    FROM Account
    WHERE Industry = :filter
    WITH USER_MODE
];

// Dynamic SOQL with user mode
List<Account> accounts = Database.query(
    'SELECT Id, Name FROM Account',
    AccessLevel.USER_MODE
);
```

### DML — stripInaccessible
```apex
// Before INSERT
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.CREATABLE, records
);
insert decision.getRecords();

// Before UPDATE
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.UPDATABLE, records
);
update decision.getRecords();

// Before returning data to user
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.READABLE, records
);
return decision.getRecords();

// Check which fields were stripped
Set<String> strippedFields = decision.getRemovedFields().get('Account');
```

### Database Operations with AccessLevel
```apex
// Insert with user mode
Database.insert(records, AccessLevel.USER_MODE);

// Update with user mode
Database.update(records, AccessLevel.USER_MODE);

// Upsert with user mode
Database.upsert(records, ExternalId__c, AccessLevel.USER_MODE);
```

## Sharing Model

### Class Declarations
```apex
// DEFAULT — always use this
public with sharing class MyService { }

// Only when system-level access is explicitly needed
public without sharing class SystemDataService { }

// Inherits from caller
public inherited sharing class UtilityClass { }
```

### When to Use Without Sharing
- Aggregate reporting queries that span ownership
- System-level operations in batch jobs
- Platform event handlers that need cross-user access
- **Always document the reason in a comment**

## SOQL Injection Prevention

### Bind Variables (Preferred)
```apex
String nameFilter = userInput;
List<Account> results = [
    SELECT Id, Name FROM Account
    WHERE Name = :nameFilter
    WITH USER_MODE
];
```

### escapeSingleQuotes (Dynamic SOQL)
```apex
String safeName = String.escapeSingleQuotes(userInput);
String query = 'SELECT Id FROM Account WHERE Name = \'' + safeName + '\'';
```

### Never Do This
```apex
// VULNERABLE — direct concatenation
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';
```

## Visualforce XSS Prevention

### Output Encoding
```html
<!-- Auto-escaped (safe) -->
<apex:outputText value="{!accountName}"/>

<!-- Manual encoding when needed -->
<script>
    var name = '{!JSENCODE(accountName)}';
    var url = '{!URLENCODE(accountName)}';
</script>

<!-- DANGEROUS — never use -->
<apex:outputText value="{!accountName}" escape="false"/>
```

## Named Credentials (No Hardcoded Secrets)
```apex
// GOOD — uses Named Credential
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:My_Named_Credential/api/resource');
req.setMethod('GET');

// BAD — hardcoded
req.setEndpoint('https://api.example.com/resource');
req.setHeader('Authorization', 'Bearer ' + hardcodedToken);
```

---

## Schema Describe FLS Checks

### isAccessible Pattern (Read Check)
```apex
public class SecureQueryService {

    public static List<Account> getAccounts(Set<Id> ids) {
        // Object-level read check
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('Insufficient access to Account');
        }

        // Field-level read checks
        Map<String, Schema.SObjectField> fieldMap =
            Schema.sObjectType.Account.fields.getMap();

        List<String> queryFields = new List<String>{'Id'};
        for (String fieldName : new List<String>{'Name', 'Industry', 'AnnualRevenue', 'Phone'}) {
            if (fieldMap.get(fieldName).getDescribe().isAccessible()) {
                queryFields.add(fieldName);
            }
        }

        String soql = 'SELECT ' + String.join(queryFields, ', ') +
            ' FROM Account WHERE Id IN :ids';
        return Database.query(soql);
    }
}
```

### isCreateable Pattern (Insert Check)
```apex
public class SecureInsertService {

    public static Id createAccount(String name, String industry, Decimal revenue) {
        // Object-level create check
        if (!Schema.sObjectType.Account.isCreateable()) {
            throw new AuraHandledException('Cannot create Account records');
        }

        Account acct = new Account();

        // Field-level create checks
        if (Schema.sObjectType.Account.fields.Name.getDescribe().isCreateable()) {
            acct.Name = name;
        }
        if (Schema.sObjectType.Account.fields.Industry.getDescribe().isCreateable()) {
            acct.Industry = industry;
        }
        if (Schema.sObjectType.Account.fields.AnnualRevenue.getDescribe().isCreateable()) {
            acct.AnnualRevenue = revenue;
        }

        insert acct;
        return acct.Id;
    }
}
```

### isUpdateable / isDeletable Checks
```apex
// Update check
if (Schema.sObjectType.Account.isUpdateable() &&
    Schema.sObjectType.Account.fields.Industry.getDescribe().isUpdateable()) {
    acct.Industry = 'Technology';
    update acct;
}

// Delete check
if (Schema.sObjectType.Account.isDeletable()) {
    delete acct;
}
```

---

## Apex Managed Sharing Example

### AccountShare — Grant Edit Access to a User
```apex
public class AccountSharingService {

    /**
     * Share an Account record with a specific user.
     * Requires the Account OWD to be Private or Public Read Only.
     */
    public static void shareAccountWithUser(Id accountId, Id userId, String accessLevel) {
        AccountShare share = new AccountShare();
        share.AccountId = accountId;
        share.UserOrGroupId = userId;
        share.AccountAccessLevel = accessLevel;      // 'Read' or 'Edit'
        share.OpportunityAccessLevel = 'Read';        // Required for AccountShare
        share.RowCause = Schema.AccountShare.RowCause.Manual;

        Database.SaveResult sr = Database.insert(share, false);
        if (!sr.isSuccess()) {
            for (Database.Error err : sr.getErrors()) {
                System.debug(LoggingLevel.ERROR, 'AccountShare error: ' + err.getMessage());
            }
        }
    }

    /**
     * Revoke manually shared access for a user on an Account.
     */
    public static void revokeAccountShare(Id accountId, Id userId) {
        List<AccountShare> shares = [
            SELECT Id FROM AccountShare
            WHERE AccountId = :accountId
            AND UserOrGroupId = :userId
            AND RowCause = :Schema.AccountShare.RowCause.Manual
        ];
        if (!shares.isEmpty()) {
            delete shares;
        }
    }

    /**
     * Bulk share accounts with a public group.
     */
    public static void shareAccountsWithGroup(List<Id> accountIds, Id groupId) {
        List<AccountShare> shares = new List<AccountShare>();
        for (Id acctId : accountIds) {
            AccountShare share = new AccountShare();
            share.AccountId = acctId;
            share.UserOrGroupId = groupId;
            share.AccountAccessLevel = 'Read';
            share.OpportunityAccessLevel = 'None';
            share.RowCause = Schema.AccountShare.RowCause.Manual;
            shares.add(share);
        }

        List<Database.SaveResult> results = Database.insert(shares, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug('Failed to share account: ' + accountIds[i]);
            }
        }
    }
}
```

---

## FeatureManagement.checkPermission() Example

### Custom Permission Check in Apex
```apex
public class FeatureGateService {

    /**
     * Check if the running user has a specific custom permission.
     * Custom Permissions are defined in Setup and assigned via Permission Sets.
     */
    public static Boolean hasFeatureAccess(String customPermissionApiName) {
        return FeatureManagement.checkPermission(customPermissionApiName);
    }

    /**
     * Guard a sensitive operation behind a custom permission.
     */
    public static void executeSensitiveOperation() {
        if (!FeatureManagement.checkPermission('Allow_Mass_Delete')) {
            throw new AuraHandledException(
                'You do not have the Allow_Mass_Delete permission.'
            );
        }

        // Proceed with mass delete logic
        performMassDelete();
    }

    /**
     * Use custom permissions for feature toggling.
     */
    public static Map<String, Object> getFeatureFlags() {
        return new Map<String, Object>{
            'betaDashboard' => FeatureManagement.checkPermission('Beta_Dashboard_Access'),
            'advancedReporting' => FeatureManagement.checkPermission('Advanced_Reporting'),
            'bulkOperations' => FeatureManagement.checkPermission('Bulk_Operations_Access')
        };
    }

    private static void performMassDelete() {
        // Implementation
    }
}
```

### In LWC (via Apex or Custom Permission Import)
```javascript
import hasAdvancedReporting from '@salesforce/customPermission/Advanced_Reporting';

export default class MyComponent extends LightningElement {
    get showAdvancedTab() {
        return hasAdvancedReporting;
    }
}
```

### In Flow
```
Decision Element:
  Condition: $Permission.Advanced_Reporting = true
  True Path: Show advanced features
  False Path: Show standard features
```

---

## Transaction Security Policy Pattern

### Overview
Transaction Security evaluates events in real time and takes automated actions (block, alert, require MFA, end session).

### Policy Configuration via Setup
```
Setup > Transaction Security Policies > New:
1. Select Event Type:
   - ApiEvent (API calls)
   - LoginEvent (logins)
   - ReportEvent (report runs/exports)
   - ListViewEvent (list view access)
   - BulkApiResultEvent (bulk data downloads)

2. Define Conditions (Condition Builder or Apex):
   - Field-based: e.g., QueriedEntities CONTAINS 'Account'
   - Threshold-based: e.g., RowsProcessed > 10000
   - User-based: e.g., User.Profile != 'System Administrator'

3. Select Action:
   - Block: Prevent the operation entirely
   - Multi-Factor Authentication: Require MFA challenge
   - Notify: Send email notification to admin
   - Notify + Block: Alert and prevent

4. Notification Recipients:
   - Specific users or groups
   - Email template for notification
```

### Apex Policy Implementation
```apex
global class LargeDataExportPolicy implements TxnSecurity.PolicyCondition {

    /**
     * Evaluate whether a report event should be blocked.
     * Returns true to trigger the configured action (block/notify).
     */
    public boolean evaluate(TxnSecurity.Event e) {
        // Get event attributes
        Integer rowCount = (Integer) e.getAttribute('NumberOfRecords');
        String userId = (String) e.getAttribute('UserId');

        // Allow system administrators
        User u = [SELECT Profile.Name FROM User WHERE Id = :userId];
        if (u.Profile.Name == 'System Administrator') {
            return false; // Do not trigger action
        }

        // Block exports with more than 10,000 rows
        if (rowCount != null && rowCount > 10000) {
            return true; // Trigger the action
        }

        return false;
    }
}
```

### Common Policy Patterns

| Event Type        | Condition                                | Action        |
|-------------------|------------------------------------------|---------------|
| LoginEvent        | Login from unknown IP / country          | Block + Notify|
| LoginEvent        | Login outside business hours             | Require MFA   |
| ReportEvent       | Export > 10,000 rows                     | Block + Notify|
| ApiEvent          | Bulk query on sensitive objects          | Notify        |
| BulkApiResultEvent| Download results > 50,000 records       | Block + Notify|
| ListViewEvent     | Access to sensitive object list views    | Notify        |
