# Salesforce Data Operations Reference

## 1. Bulk API 2.0 Job Lifecycle

### Step-by-Step Lifecycle
```
Create Job → Upload CSV → Close Job → Poll Status → Get Results → Get Failed Records
```

### CLI Commands
```bash
# 1. Create a bulk upsert job
sf data bulk upsert -o MyOrg -f data/accounts.csv -s Account -i External_Id__c -w 30

# 2. Create a bulk delete job
sf data bulk delete -o MyOrg -f data/delete-ids.csv -s Account -w 30

# For large imports, use Bulk API via REST:
```

### REST API Steps
```bash
# 1. Create Job
curl -X POST https://instance.salesforce.com/services/data/v60.0/jobs/ingest \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "object": "Account",
    "operation": "upsert",
    "externalIdFieldName": "External_Id__c",
    "contentType": "CSV",
    "lineEnding": "LF"
  }'
# Returns: jobId

# 2. Upload CSV Data
curl -X PUT https://instance.salesforce.com/services/data/v60.0/jobs/ingest/$JOB_ID/batches \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: text/csv" \
  --data-binary @data/accounts.csv

# 3. Close Job (signals upload complete)
curl -X PATCH https://instance.salesforce.com/services/data/v60.0/jobs/ingest/$JOB_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"state": "UploadComplete"}'

# 4. Check Status
curl https://instance.salesforce.com/services/data/v60.0/jobs/ingest/$JOB_ID \
  -H "Authorization: Bearer $TOKEN"
# Response includes: state, numberRecordsProcessed, numberRecordsFailed

# 5. Get Successful Results
curl https://instance.salesforce.com/services/data/v60.0/jobs/ingest/$JOB_ID/successfulResults \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: text/csv"

# 6. Get Failed Records
curl https://instance.salesforce.com/services/data/v60.0/jobs/ingest/$JOB_ID/failedResults \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: text/csv"
```

### Bulk API Limits
- Max CSV file size per upload: 150 MB
- Max record size: 10 MB
- Max records per batch: 10,000 (Bulk API 1.0) / unlimited per upload (Bulk API 2.0)
- Max concurrent jobs: 100 (Bulk API 2.0)
- Polling interval recommendation: start at 10s, increase to 30s

---

## 2. Composite API

### Composite Request Pattern
```json
POST /services/data/v60.0/composite

{
  "allOrNone": true,
  "compositeRequest": [
    {
      "method": "POST",
      "url": "/services/data/v60.0/sobjects/Account",
      "referenceId": "newAccount",
      "body": {
        "Name": "Acme Corp",
        "Industry": "Technology"
      }
    },
    {
      "method": "POST",
      "url": "/services/data/v60.0/sobjects/Contact",
      "referenceId": "newContact",
      "body": {
        "FirstName": "John",
        "LastName": "Doe",
        "AccountId": "@{newAccount.id}"
      }
    },
    {
      "method": "POST",
      "url": "/services/data/v60.0/sobjects/Opportunity",
      "referenceId": "newOpp",
      "body": {
        "Name": "Acme Deal",
        "StageName": "Prospecting",
        "CloseDate": "2026-12-31",
        "AccountId": "@{newAccount.id}"
      }
    },
    {
      "method": "GET",
      "url": "/services/data/v60.0/sobjects/Account/@{newAccount.id}?fields=Name,Id",
      "referenceId": "getAccount"
    }
  ]
}
```

### Key Features
- Up to 25 subrequests per composite call
- Reference IDs allow cross-referencing between subrequests: `@{referenceId.fieldName}`
- `allOrNone: true` rolls back all changes if any subrequest fails
- Subrequests execute sequentially in order
- Supports GET, POST, PATCH, DELETE methods

### Composite Graph API
```json
POST /services/data/v60.0/composite/graph

{
  "graphs": [
    {
      "graphId": "graph1",
      "compositeRequest": [
        {
          "method": "POST",
          "url": "/services/data/v60.0/sobjects/Account",
          "referenceId": "acct",
          "body": { "Name": "Graph Account" }
        },
        {
          "method": "POST",
          "url": "/services/data/v60.0/sobjects/Contact",
          "referenceId": "cont",
          "body": {
            "LastName": "Graph Contact",
            "AccountId": "@{acct.id}"
          }
        }
      ]
    }
  ]
}
```
- Up to 500 nodes across all graphs
- Each graph is an independent transaction

---

## 3. Tree Export with Relationships

### Export Records with Relationships
```bash
# Export accounts with child contacts
sf data export tree -q "SELECT Id, Name, Industry, (SELECT Id, FirstName, LastName, Email FROM Contacts) FROM Account WHERE Industry = 'Technology' LIMIT 20" -o MyOrg -d data/export

# This creates:
# data/export/Account.json       — Account records
# data/export/Contact.json       — Contact records
# data/export/Account-Contact-plan.json — Import plan
```

### Plan File Format
```json
[
  {
    "sobject": "Account",
    "saveRefs": true,
    "resolveRefs": false,
    "files": ["Account.json"]
  },
  {
    "sobject": "Contact",
    "saveRefs": false,
    "resolveRefs": true,
    "files": ["Contact.json"]
  }
]
```

### Import Records from Plan
```bash
sf data import tree -p data/export/Account-Contact-plan.json -o TargetOrg
```

### Record JSON Format with References
```json
{
  "records": [
    {
      "attributes": {
        "type": "Account",
        "referenceId": "AccountRef1"
      },
      "Name": "Acme Corp",
      "Industry": "Technology"
    }
  ]
}
```
```json
{
  "records": [
    {
      "attributes": {
        "type": "Contact",
        "referenceId": "ContactRef1"
      },
      "FirstName": "John",
      "LastName": "Doe",
      "AccountId": "@AccountRef1"
    }
  ]
}
```

---

## 4. External ID Upsert Strategies

### Choosing External ID Fields
- Must be marked as "External ID" on the field definition
- Ideally also marked as "Unique" for deterministic matching
- Common choices: legacy system IDs, integration keys, composite keys
- Text, Number, and Email fields can be External IDs

### Idempotent Upsert Pattern
```bash
# CLI upsert with external ID
sf data upsert record -s Account -v "Name='Acme' External_Id__c='EXT-001'" -i External_Id__c -o MyOrg

# Bulk upsert with external ID
sf data bulk upsert -s Account -f accounts.csv -i External_Id__c -o MyOrg -w 30
```

### CSV Format for External ID Upsert
```csv
External_Id__c,Name,Industry,Parent_External_Id__c
EXT-001,Acme Corp,Technology,
EXT-002,Acme Sub,Technology,EXT-001
```

### Cross-Object External ID References
```csv
External_Id__c,LastName,FirstName,Account.External_Id__c
CONT-001,Doe,John,EXT-001
CONT-002,Smith,Jane,EXT-002
```
- Use `ParentObject.ExternalIdField` to reference parent records by external ID
- Avoids needing to look up Salesforce IDs

### Cross-Org ID Mapping
```apex
// Mapping table pattern
public class CrossOrgIdMapper {
    // Custom object: Org_Id_Map__c with Source_Id__c, Target_Id__c, Object_Type__c
    public static Map<String, Id> getIdMap(String objectType, Set<String> sourceIds) {
        Map<String, Id> idMap = new Map<String, Id>();
        for (Org_Id_Map__c mapping : [
            SELECT Source_Id__c, Target_Id__c
            FROM Org_Id_Map__c
            WHERE Object_Type__c = :objectType
            AND Source_Id__c IN :sourceIds
        ]) {
            idMap.put(mapping.Source_Id__c, (Id)mapping.Target_Id__c);
        }
        return idMap;
    }
}
```

---

## 5. Large Data Volume Best Practices

### Skinny Tables
- Custom platform feature (request via Salesforce Support)
- Denormalized table mirroring frequently queried fields
- Eliminates joins, dramatically speeds up reports/queries
- Must include fields commonly used in filters
- Automatically synced with source object

### Custom Indexes
```
Contact Salesforce Support to request custom indexes on:
- Fields frequently used in WHERE clauses
- Fields used with selective filters
- External ID fields (auto-indexed)
- Consider two-column indexes for common filter combinations
```

### Query Optimization for >1M Records
```apex
// GOOD: Selective query (uses index)
List<Account> accts = [
    SELECT Id, Name FROM Account
    WHERE External_Id__c = :extId
];

// GOOD: Date range with indexed field
List<Case> cases = [
    SELECT Id, Subject FROM Case
    WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
    AND Status = 'Open'
    LIMIT 10000
];

// BAD: Non-selective query (full table scan)
List<Account> accts = [
    SELECT Id, Name FROM Account
    WHERE Name LIKE '%test%'
];

// BAD: Leading wildcard prevents index use
// BAD: Negative filters (!=, NOT IN, EXCLUDES) are non-selective
```

### Selectivity Thresholds
- Standard index: Filter returns < 30% of first million + 15% of remaining records
- Custom index: Filter returns < 10% of first million + 5% of remaining records
- Less than 1,000,000 total records returned

### Archive Strategies
- Move old records to Big Objects (see section 6)
- Use External Objects with Salesforce Connect
- Implement data lifecycle policies (archive after X months)
- Batch Apex for periodic cleanup:
```apex
global class DataArchiveBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoff = Date.today().addMonths(-24);
        return Database.getQueryLocator([
            SELECT Id FROM Case
            WHERE Status = 'Closed' AND ClosedDate < :cutoff
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        // Copy to Big Object or external archive
        List<Archived_Case__b> archives = new List<Archived_Case__b>();
        for (Case c : scope) {
            archives.add(new Archived_Case__b(
                Case_Id__c = c.Id,
                Archived_Date__c = DateTime.now()
            ));
        }
        Database.insertImmediate(archives);

        // Then delete originals
        delete scope;
    }

    global void finish(Database.BatchableContext bc) {
        // Send completion notification
    }
}
```

### Lean Data Model
- Avoid formula fields on high-volume objects (calculated at query time)
- Minimize roll-up summary fields (recalculated on child DML)
- Use async processing for complex calculations
- Consider platform events for decoupled processing

---

## 6. Data Archiving with Big Objects

### Big Object Definition
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <fields>
        <fullName>Account_Id__c</fullName>
        <label>Account ID</label>
        <length>18</length>
        <type>Text</type>
    </fields>
    <fields>
        <fullName>Amount__c</fullName>
        <label>Amount</label>
        <precision>18</precision>
        <scale>2</scale>
        <type>Number</type>
    </fields>
    <fields>
        <fullName>Transaction_Date__c</fullName>
        <label>Transaction Date</label>
        <type>DateTime</type>
    </fields>
    <indexes>
        <fullName>ArchivedTransactionIndex</fullName>
        <fields>
            <name>Account_Id__c</name>
            <sortDirection>ASC</sortDirection>
        </fields>
        <fields>
            <name>Transaction_Date__c</name>
            <sortDirection>DESC</sortDirection>
        </fields>
        <label>Archived Transaction Index</label>
    </indexes>
    <label>Archived Transaction</label>
    <pluralLabel>Archived Transactions</pluralLabel>
</CustomObject>
```

### Insert Records into Big Objects
```apex
// Use Database.insertImmediate for Big Objects
List<Archived_Transaction__b> records = new List<Archived_Transaction__b>();
for (Integer i = 0; i < 200; i++) {
    Archived_Transaction__b rec = new Archived_Transaction__b();
    rec.Account_Id__c = '001000000000001';
    rec.Transaction_Date__c = DateTime.now().addDays(-i);
    rec.Amount__c = 1000 + i;
    records.add(rec);
}
Database.insertImmediate(records);
```

### Query Big Objects
```apex
// SOQL query must filter on index fields in order
List<Archived_Transaction__b> results = [
    SELECT Account_Id__c, Transaction_Date__c, Amount__c
    FROM Archived_Transaction__b
    WHERE Account_Id__c = '001000000000001'
    AND Transaction_Date__c >= :startDate
    ORDER BY Account_Id__c ASC, Transaction_Date__c DESC
    LIMIT 200
];
```

### Async SOQL for Big Objects
```bash
# REST API: Create async SOQL query
curl -X POST https://instance.salesforce.com/services/data/v60.0/async-queries \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "SELECT Account_Id__c, Amount__c FROM Archived_Transaction__b WHERE Account_Id__c = '\''001000000000001'\''",
    "targetObject": "Query_Result__c",
    "targetFieldMap": {
      "Account_Id__c": "Source_Account__c",
      "Amount__c": "Amount__c"
    }
  }'
```

### Big Object Limitations
- No triggers, flows, or process builder
- No standard UI (must build custom LWC/Visualforce)
- Cannot update or delete individual records (upsert based on index)
- No SOQL aggregate functions
- Query must filter on index fields in order (left-to-right)

---

## 7. ContentVersion File Upload

### Apex File Upload Example
```apex
public class FileUploadService {

    // Upload a file and link to a record
    public static Id uploadFile(Id parentId, String fileName, Blob fileBody) {
        // Create ContentVersion (this auto-creates ContentDocument)
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = fileBody;
        cv.FirstPublishLocationId = parentId; // Auto-creates ContentDocumentLink
        insert cv;

        return cv.Id;
    }

    // Upload file and manually create link
    public static Id uploadFileWithLink(Id parentId, String fileName, Blob fileBody) {
        // Step 1: Create ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = fileBody;
        insert cv;

        // Step 2: Get ContentDocument ID
        Id contentDocId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;

        // Step 3: Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocId;
        cdl.LinkedEntityId = parentId;
        cdl.ShareType = 'V'; // V = Viewer, C = Collaborator, I = Inferred
        cdl.Visibility = 'AllUsers'; // AllUsers, InternalUsers, SharedUsers
        insert cdl;

        return contentDocId;
    }
}
```

### Relationship Model
```
ContentDocument (the file container)
  └── ContentVersion (each version of the file)
       - VersionData (Blob - actual file content)
       - Title, PathOnClient, FileExtension
  └── ContentDocumentLink (links file to records)
       - LinkedEntityId (Account, Case, etc.)
       - ShareType, Visibility
```

### Query Files for a Record
```apex
List<ContentDocumentLink> links = [
    SELECT ContentDocumentId, ContentDocument.Title,
           ContentDocument.LatestPublishedVersion.VersionData,
           ContentDocument.FileExtension,
           ContentDocument.ContentSize
    FROM ContentDocumentLink
    WHERE LinkedEntityId = :recordId
];
```

### Base64 Encoding for REST API
```json
POST /services/data/v60.0/sobjects/ContentVersion

{
  "Title": "MyDocument",
  "PathOnClient": "MyDocument.pdf",
  "VersionData": "<base64-encoded-content>"
}
```

### File Size Limits
- Maximum file size: 2 GB (per ContentVersion)
- Apex heap size: 12 MB (sync) / 12 MB (async) - limits in-memory file processing
- REST API body size: 50 MB per request (use multipart for larger)
- Base64 encoding increases size by ~33%

---

## 8. Multi-Currency Data Handling

### CurrencyIsoCode Field
```apex
// All currency fields automatically convert when CurrencyIsoCode is set
Opportunity opp = new Opportunity();
opp.Name = 'Euro Deal';
opp.StageName = 'Prospecting';
opp.CloseDate = Date.today().addDays(30);
opp.Amount = 50000;
opp.CurrencyIsoCode = 'EUR';
insert opp;
```

### Query with Currency Conversion
```apex
// Amounts returned in record's currency by default
List<Opportunity> opps = [
    SELECT Name, Amount, CurrencyIsoCode
    FROM Opportunity
];

// Convert to corporate currency using convertCurrency()
List<Opportunity> opps = [
    SELECT Name, convertCurrency(Amount) convertedAmount
    FROM Opportunity
];
```

### Conversion Rates
```
Setup > Company Information > Currency Setup > Manage Currencies:
- Static conversion rates: single rate per currency
- Dated exchange rates (Advanced Currency Management):
  rates change over time, tied to close date
```

### Dated Exchange Rates
```apex
// Query dated exchange rates
List<DatedConversionRate> rates = [
    SELECT IsoCode, ConversionRate, StartDate, NextStartDate
    FROM DatedConversionRate
    WHERE IsoCode = 'EUR'
    ORDER BY StartDate DESC
];
```

---

## 9. User/Owner Field Population

### Mapping Users Between Orgs
```apex
// Strategy 1: Match by email
Map<String, Id> userByEmail = new Map<String, Id>();
for (User u : [SELECT Id, Email FROM User WHERE IsActive = true]) {
    userByEmail.put(u.Email.toLowerCase(), u.Id);
}

// Strategy 2: Match by Federation ID (SSO identifier)
Map<String, Id> userByFedId = new Map<String, Id>();
for (User u : [SELECT Id, FederationIdentifier FROM User WHERE IsActive = true]) {
    if (u.FederationIdentifier != null) {
        userByFedId.put(u.FederationIdentifier, u.Id);
    }
}

// Strategy 3: Match by Employee Number
Map<String, Id> userByEmpNum = new Map<String, Id>();
for (User u : [SELECT Id, EmployeeNumber FROM User WHERE IsActive = true]) {
    if (u.EmployeeNumber != null) {
        userByEmpNum.put(u.EmployeeNumber, u.Id);
    }
}
```

### Handling Inactive Users
```apex
public class OwnerAssignmentService {

    private static final Id DEFAULT_QUEUE_ID;

    static {
        DEFAULT_QUEUE_ID = [
            SELECT Id FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'Unassigned_Queue'
        ].Id;
    }

    public static Id resolveOwner(String sourceOwnerId, Map<String, Id> ownerMap) {
        Id targetOwner = ownerMap.get(sourceOwnerId);
        if (targetOwner == null) {
            // Fallback to queue or default user
            return DEFAULT_QUEUE_ID;
        }
        return targetOwner;
    }
}
```

### Queue Assignments
```apex
// Assign record to queue
Lead newLead = new Lead();
newLead.LastName = 'Doe';
newLead.Company = 'Acme';
newLead.OwnerId = [
    SELECT Id FROM Group
    WHERE Type = 'Queue' AND DeveloperName = 'Web_Lead_Queue'
].Id;
insert newLead;
```

---

## 10. ETL Patterns

### Extract
```bash
# SOQL Export
sf data query -q "SELECT Id, Name, Industry FROM Account" -o MyOrg -r csv > accounts.csv

# Bulk Export (large datasets)
sf data query -q "SELECT Id, Name, Industry FROM Account" -o MyOrg -r csv --bulk > accounts.csv

# REST API query with pagination
# Use nextRecordsUrl for batches > 2000 records
```

### Transform (Apex)
```apex
public class DataTransformService {

    public static List<Account> transformAccounts(List<Map<String, String>> sourceData) {
        List<Account> accounts = new List<Account>();
        Map<String, String> industryMapping = getIndustryMapping();

        for (Map<String, String> row : sourceData) {
            Account a = new Account();
            a.Name = row.get('COMPANY_NAME');
            a.External_Id__c = row.get('SOURCE_ID');
            a.Industry = industryMapping.get(row.get('INDUSTRY_CODE'));
            a.Phone = normalizePhone(row.get('PHONE'));
            accounts.add(a);
        }
        return accounts;
    }

    private static String normalizePhone(String phone) {
        if (String.isBlank(phone)) return null;
        return phone.replaceAll('[^0-9+]', '');
    }

    private static Map<String, String> getIndustryMapping() {
        Map<String, String> mapping = new Map<String, String>();
        for (Industry_Mapping__mdt m : Industry_Mapping__mdt.getAll().values()) {
            mapping.put(m.Source_Code__c, m.Salesforce_Value__c);
        }
        return mapping;
    }
}
```

### Load
```bash
# Bulk upsert with external ID
sf data bulk upsert -s Account -f transformed_accounts.csv -i External_Id__c -o TargetOrg -w 30
```

### Error Handling Pattern
```apex
public class ETLErrorHandler {

    public static void processResults(List<Database.UpsertResult> results, List<SObject> records) {
        List<ETL_Error__c> errors = new List<ETL_Error__c>();

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                ETL_Error__c err = new ETL_Error__c();
                err.Object_Type__c = records[i].getSObjectType().getDescribe().getName();
                err.Record_Data__c = JSON.serialize(records[i]).left(32768);
                err.Error_Message__c = '';
                for (Database.Error e : results[i].getErrors()) {
                    err.Error_Message__c += e.getStatusCode() + ': ' + e.getMessage() + '\n';
                }
                errors.add(err);
            }
        }

        if (!errors.isEmpty()) {
            insert errors;
        }
    }
}
```

---

## 11. Data Backup & Recovery

### Weekly Export
```
Setup > Data Export > Export Now / Schedule Export
- Options: Include images, documents, attachments
- Include all data or select specific objects
- Frequency: Weekly or Monthly
- Export files available for 48 hours after generation
```

### Data Loader Backup Script
```bash
#!/bin/bash
# Automated backup script using sf CLI

DATE=$(date +%Y%m%d)
BACKUP_DIR="backups/$DATE"
ORG_ALIAS="ProductionOrg"

mkdir -p "$BACKUP_DIR"

OBJECTS=("Account" "Contact" "Opportunity" "Case" "Lead")

for OBJ in "${OBJECTS[@]}"; do
    echo "Exporting $OBJ..."
    sf data query \
        -q "SELECT FIELDS(ALL) FROM $OBJ LIMIT 50000" \
        -o $ORG_ALIAS \
        -r csv \
        --bulk > "$BACKUP_DIR/${OBJ}.csv"
done

echo "Backup complete: $BACKUP_DIR"
```

### Org-to-Org Backup Pattern
```apex
// Use scheduled batch to replicate critical data to backup org
global class DataReplicationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime lastSync = getLastSyncTime();
        return Database.getQueryLocator([
            SELECT Id, Name, Industry, External_Id__c
            FROM Account
            WHERE LastModifiedDate >= :lastSync
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        // Serialize and send to backup org via REST API
        String jsonBody = JSON.serialize(scope);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Backup_Org/services/apexrest/backup/Account');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        new Http().send(req);
    }

    global void finish(Database.BatchableContext bc) {
        updateLastSyncTime();
    }
}
```

---

## 12. Sandbox Seeding Automation

### Complete Test Data Seeding Script
```apex
public class SandboxDataSeeder {

    public static void seedAllData() {
        // Create in dependency order
        List<Account> accounts = createAccounts(50);
        List<Contact> contacts = createContacts(accounts, 3); // 3 per account
        List<Opportunity> opps = createOpportunities(accounts, 2); // 2 per account
        List<Case> cases = createCases(accounts, contacts);
        createTasks(contacts);
    }

    private static List<Account> createAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        List<String> industries = new List<String>{
            'Technology', 'Finance', 'Healthcare', 'Manufacturing', 'Retail'
        };

        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + (i + 1),
                Industry = industries[Math.mod(i, industries.size())],
                AnnualRevenue = (i + 1) * 100000,
                BillingCity = 'San Francisco',
                BillingState = 'CA',
                BillingCountry = 'US',
                Phone = '555-' + String.valueOf(1000 + i),
                External_Id__c = 'SEED-ACCT-' + (i + 1)
            ));
        }
        insert accounts;
        return accounts;
    }

    private static List<Contact> createContacts(List<Account> accounts, Integer perAccount) {
        List<Contact> contacts = new List<Contact>();
        List<String> titles = new List<String>{
            'CEO', 'VP Sales', 'Director of IT', 'CFO', 'Manager'
        };

        Integer idx = 0;
        for (Account a : accounts) {
            for (Integer i = 0; i < perAccount; i++) {
                contacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact ' + idx,
                    AccountId = a.Id,
                    Email = 'test.contact' + idx + '@test.invalid',
                    Title = titles[Math.mod(idx, titles.size())],
                    Phone = '555-' + String.valueOf(2000 + idx)
                ));
                idx++;
            }
        }
        insert contacts;
        return contacts;
    }

    private static List<Opportunity> createOpportunities(List<Account> accounts, Integer perAccount) {
        List<Opportunity> opps = new List<Opportunity>();
        List<String> stages = new List<String>{
            'Prospecting', 'Qualification', 'Proposal', 'Negotiation', 'Closed Won'
        };

        Integer idx = 0;
        for (Account a : accounts) {
            for (Integer i = 0; i < perAccount; i++) {
                opps.add(new Opportunity(
                    Name = a.Name + ' - Deal ' + (i + 1),
                    AccountId = a.Id,
                    StageName = stages[Math.mod(idx, stages.size())],
                    CloseDate = Date.today().addDays(30 + (idx * 7)),
                    Amount = (idx + 1) * 25000
                ));
                idx++;
            }
        }
        insert opps;
        return opps;
    }

    private static List<Case> createCases(List<Account> accounts, List<Contact> contacts) {
        List<Case> cases = new List<Case>();
        List<String> statuses = new List<String>{'New', 'Working', 'Escalated', 'Closed'};

        for (Integer i = 0; i < Math.min(accounts.size(), 20); i++) {
            cases.add(new Case(
                AccountId = accounts[i].Id,
                ContactId = contacts[i].Id,
                Subject = 'Test Case ' + (i + 1),
                Description = 'Seeded test case for sandbox testing',
                Status = statuses[Math.mod(i, statuses.size())],
                Priority = Math.mod(i, 3) == 0 ? 'High' : 'Medium',
                Origin = 'Web'
            ));
        }
        insert cases;
        return cases;
    }

    private static void createTasks(List<Contact> contacts) {
        List<Task> tasks = new List<Task>();

        for (Integer i = 0; i < Math.min(contacts.size(), 30); i++) {
            tasks.add(new Task(
                WhoId = contacts[i].Id,
                Subject = 'Follow up with ' + contacts[i].LastName,
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = Date.today().addDays(i + 1)
            ));
        }
        insert tasks;
    }
}
```

### Using with SandboxPostCopy
```apex
global class SeedDataPostRefresh implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        SandboxDataSeeder.seedAllData();
    }
}
```
