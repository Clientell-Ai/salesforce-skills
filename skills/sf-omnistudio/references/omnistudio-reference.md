# OmniStudio Reference

Deep reference for OmniStudio component metadata, namespace mappings, and operational guidance.

## Namespace Detection Queries

Run these queries sequentially. The first successful result identifies the installed namespace.

```sql
-- Probe 1: Core (Industries Cloud, Spring '22+)
SELECT COUNT() FROM OmniProcess

-- Probe 2: Vlocity CMT (Communications, Media, Energy)
SELECT COUNT() FROM vlocity_cmt__OmniScript__c

-- Probe 3: Vlocity INS (Insurance, Health)
SELECT COUNT() FROM vlocity_ins__OmniScript__c
```

A successful query returns exit code 0 with `totalSize` in JSON output. An `INVALID_TYPE` error means that namespace is absent.

## Complete Namespace Field Mapping

### Primary Objects

| Concept | Core | vlocity_cmt | vlocity_ins |
|---------|------|-------------|-------------|
| OmniScript / IP container | `OmniProcess` | `vlocity_cmt__OmniScript__c` | `vlocity_ins__OmniScript__c` |
| OmniScript / IP elements | `OmniProcessElement` | `vlocity_cmt__Element__c` | `vlocity_ins__Element__c` |
| FlexCard | `OmniUiCard` | `vlocity_cmt__VlocityUITemplate__c` | `vlocity_ins__VlocityUITemplate__c` |
| Data Mapper | `OmniDataTransform` | `vlocity_cmt__DRBundle__c` | `vlocity_ins__DRBundle__c` |
| Data Mapper Item | `OmniDataTransformItem` | `vlocity_cmt__DRMapItem__c` | `vlocity_ins__DRMapItem__c` |

### Key Fields

| Concept | Core Field | vlocity_cmt Field | vlocity_ins Field |
|---------|-----------|-------------------|-------------------|
| Script type | `Type` | `vlocity_cmt__Type__c` | `vlocity_ins__Type__c` |
| Script subtype | `SubType` | `vlocity_cmt__SubType__c` | `vlocity_ins__SubType__c` |
| Language | `Language` | `vlocity_cmt__Language__c` | `vlocity_ins__Language__c` |
| Active flag | `IsActive` | `vlocity_cmt__IsActive__c` | `vlocity_ins__IsActive__c` |
| Version number | `VersionNumber` | `vlocity_cmt__Version__c` | `vlocity_ins__Version__c` |
| Element config | `PropertySetConfig` | `vlocity_cmt__PropertySet__c` | `vlocity_ins__PropertySet__c` |
| Is Integration Procedure | `IsIntegrationProcedure` | `vlocity_cmt__IsIntegrationProcedure__c` | `vlocity_ins__IsIntegrationProcedure__c` |
| FlexCard data sources | `DataSourceConfig` | `vlocity_cmt__Definition__c` | `vlocity_ins__Definition__c` |
| FlexCard layout | `PropertySetConfig` | `PropertySetConfig` | `PropertySetConfig` |
| DM input object | `InputObjectName` (on Item) | `vlocity_cmt__InterfaceObject__c` | `vlocity_ins__InterfaceObject__c` |
| DM output object | `OutputObjectName` (on Item) | `vlocity_cmt__TargetFieldObjectType__c` | `vlocity_ins__TargetFieldObjectType__c` |

## OmniScript / IP Metadata Structure (Core)

OmniProcess fields: `Id`, `Name`, `Type`, `SubType`, `Language`, `VersionNumber`, `IsActive`, `IsIntegrationProcedure` (boolean discriminator), `OmniProcessType` (computed), `PropertySetConfig` (JSON), `LastModifiedDate`.

OmniProcessElement fields: `Id`, `OmniProcessId` (parent lookup), `Name`, `Type` (element type), `Level` (0=Step, 1+=children), `Order` (sequence), `PropertySetConfig` (JSON), `IsActive`.

### PropertySetConfig Structure (Action Elements)

DataRaptor Extract/Load Action:
```json
{
  "bundle": "DR_Extract_Account_Details",
  "inputMap": {
    "AccountId": "%ContextId%"
  },
  "outputMap": {},
  "optionsMap": {},
  "showError": true,
  "errorMessage": "Failed to retrieve account data"
}
```

Integration Procedure Action:
```json
{
  "ipMethod": "AccountOnboarding_Standard",
  "inputMap": {
    "accountId": "%AccountId%",
    "requestType": "new"
  },
  "outputMap": {},
  "optionsMap": {
    "useFuture": false
  },
  "showError": true,
  "errorMessage": "Onboarding procedure failed"
}
```

Remote Action:
```json
{
  "remoteClass": "AccountService",
  "remoteMethod": "validateAddress",
  "inputMap": {
    "street": "%Street%",
    "city": "%City%"
  },
  "outputMap": {}
}
```

## FlexCard Metadata Structure

OmniUiCard fields: `Id`, `Name`, `IsActive`, `VersionNumber`, `OmniUiCardType`, `AuthorName`, `DataSourceConfig` (JSON -- data sources), `PropertySetConfig` (JSON -- layout/states/actions), `LastModifiedDate`. There is NO `Definition` field on `OmniUiCard` in Core namespace.

### DataSourceConfig Structure

```json
{
  "dataSource": {
    "type": "IntegrationProcedures",
    "value": {
      "ipMethod": "AccountSummary_Fetch",
      "vlocityAsync": false,
      "inputMap": {
        "recordId": "{recordId}"
      },
      "resultVar": ""
    },
    "orderBy": {
      "name": "",
      "isReverse": ""
    },
    "contextVariables": []
  }
}
```

Valid `dataSource.type` values: `IntegrationProcedures` (must be plural), `SOQL`, `ApexRemote`, `REST`, `Custom`.

Context variables for input: `{recordId}` (record page), `{userId}` (running user), `{param.customKey}` (URL/parent card).

Merge field syntax: `{fieldName}`, `{Object.Field}`, `{records[0].Name}`.

## Integration Procedure Response Pattern

Each element writes output namespaced under its element name. Reference upstream outputs with `%elementName:keyPath%`:

```
Input JSON --> [GetAccount] --> [ValidateData] --> [CreateCase] --> Output JSON

Result: { "GetAccount": { "Name": "Acme" }, "ValidateData": { "isValid": true }, ... }
```

Caching: Set `cacheType`, `cacheTTL` (seconds), `cachePartition` in PropertySet. Only cache read-only IPs. Cached results bypass execution on cache hit.

## DataRaptor / Data Mapper Examples

### Extract Configuration

Query Account with related Contacts:

```
OmniDataTransform:
  Name: DR_Extract_Account_Details
  Type: Extract
  IsActive: true

OmniDataTransformItem records:
  Item 1: InputObjectName=Account, OutputObjectName=Account
    Field: Id -> AccountId
    Field: Name -> AccountName
    Field: Industry -> Industry
    Filter: Id = :AccountId (input parameter)
    LIMIT: 1

  Item 2: InputObjectName=Contact, OutputObjectName=Contacts
    Field: Id -> ContactId
    Field: FirstName -> FirstName
    Field: LastName -> LastName
    Field: Email -> Email
    Relationship: AccountId = Account.Id
    LIMIT: 50
```

### Transform Configuration

Flatten nested Account-Contact structure:

```
OmniDataTransform:
  Name: DR_Transform_Account_Flatten
  Type: Transform
  IsActive: true

OmniDataTransformItem records:
  Item 1: InputObjectName=Account:Name, OutputObjectName=AccountName
  Item 2: InputObjectName=Contacts[0]:FirstName, OutputObjectName=PrimaryContactFirst
  Item 3: InputObjectName=Contacts[0]:LastName, OutputObjectName=PrimaryContactLast
```

Transform operates entirely in memory -- no SOQL or DML.

### Load Configuration

Create a new Case record:

```
OmniDataTransform:
  Name: DR_Load_Case_Create
  Type: Load
  IsActive: true

OmniDataTransformItem records:
  Item 1: InputObjectName=Subject, OutputObjectName=Case:Subject
  Item 2: InputObjectName=Description, OutputObjectName=Case:Description
  Item 3: InputObjectName=AccountId, OutputObjectName=Case:AccountId
  Item 4: InputObjectName=Priority, OutputObjectName=Case:Priority
  DML Operation: Insert
```

## Common OmniScript Element Types

### Input Elements Configuration

| Element | Required PropertySetConfig Keys | Notes |
|---------|-------------------------------|-------|
| Text | `label`, `placeholder` | Optional: `pattern` (regex validation), `maxLength` |
| Number | `label`, `min`, `max` | Optional: `step`, `format` (decimal places) |
| Select | `label`, `options` or `optionSource` | Static: `options` array. Dynamic: `optionSource` with Data Mapper |
| Type Ahead | `label`, `dataSource`, `searchField` | `minCharacters` for search threshold, `resultField` for display |
| Date | `label`, `dateFormat` | Optional: `minDate`, `maxDate` for range constraints |
| Checkbox | `label`, `defaultValue` | Boolean input; `defaultValue` is true/false |
| File | `label`, `maxFileSize`, `allowedExtensions` | File upload with size and type constraints |

### Container Elements Configuration

| Element | Required PropertySetConfig Keys | Notes |
|---------|-------------------------------|-------|
| Step | `chartLabel` | `show` expression for conditional visibility |
| Conditional Block | `conditionType`, `show` | `conditionType`: "Hide if True" or "Show if True" |
| Loop Block | `loopData` | JSON path to the array to iterate over |

## IP Action Type Reference

| Action Type | PropertySetConfig Key | Value Format | Purpose |
|-------------|----------------------|-------------|---------|
| DataRaptor Extract | `bundle` | Data Mapper name (string) | Read Salesforce data |
| DataRaptor Load | `bundle` | Data Mapper name (string) | Write Salesforce data (insert/update/upsert/delete) |
| DataRaptor Transform | `bundle` | Data Mapper name (string) | In-memory data reshaping |
| DataRaptor Turbo | `bundle` | Data Mapper name (string) | High-volume compiled read |
| Remote Action | `remoteClass`, `remoteMethod` | Apex class and method names | Invoke Apex logic |
| Integration Procedure | `ipMethod` | Type_SubType (string) | Call nested IP |
| HTTP Action | `path`, `method` | URL path, HTTP method | External API callout |
| Matrix Action | `matrixName` | Decision matrix name | Lookup value from decision table |
| Email Action | `emailTemplateId` | Template ID | Send email notification |
| Set Values | `elementValueMap` | Key-value JSON | Assign variables |

## Deployment Order for OmniStudio Components

Always deploy in dependency order to avoid broken references:

```
1. OmniDataTransform      (Data Mappers -- no dependencies on other OmniStudio)
2. OmniIntegrationProcedure (IPs -- depend on Data Mappers, Apex classes)
3. OmniScript              (OmniScripts -- depend on IPs and Data Mappers)
4. OmniUiCard              (FlexCards -- depend on IPs, may launch OmniScripts)
```

Deploy each type sequentially, then activate components via `IsActive=true` update.

## Dependency Mapping Queries

### Find All Components Referencing a Data Mapper

```sql
-- Find IPs/OmniScripts using a specific Data Mapper (by bundle name in element config)
SELECT Id, OmniProcessId, Name, Type, PropertySetConfig
FROM OmniProcessElement
WHERE PropertySetConfig LIKE '%DR_Extract_Account_Details%'
```

### Find All FlexCards Using a Specific IP

```sql
SELECT Id, Name, DataSourceConfig
FROM OmniUiCard
WHERE DataSourceConfig LIKE '%AccountSummary_Fetch%'
AND IsActive = true
```

### Find All OmniScripts Calling a Specific IP

```sql
SELECT Id, OmniProcessId, Name, Type, PropertySetConfig
FROM OmniProcessElement
WHERE Type = 'Integration Procedure Action'
AND PropertySetConfig LIKE '%AccountOnboarding_Standard%'
```

### Component Inventory

Use `SELECT COUNT() FROM <object>` with appropriate filters (`IsIntegrationProcedure=true/false` for OmniProcess) to inventory components. Add `GROUP BY IsActive` for active/inactive breakdown.

## Migration Checklist: Vlocity to Core

### Pre-Migration

- [ ] Identify installed Vlocity namespace (vlocity_cmt or vlocity_ins)
- [ ] Run full component inventory in source org
- [ ] Map all cross-component dependencies
- [ ] Document custom Apex classes referenced by Remote Actions
- [ ] Identify components with external HTTP callout configurations
- [ ] Verify target org has Industries Cloud / OmniStudio Core license
- [ ] Confirm target org API version supports Core namespace (API 234.0+ / Spring '22+)

### Object and Field Conversion

- [ ] Replace `vlocity_cmt__OmniScript__c` references with `OmniProcess`
- [ ] Replace `vlocity_cmt__Element__c` references with `OmniProcessElement`
- [ ] Replace `vlocity_cmt__VlocityUITemplate__c` references with `OmniUiCard`
- [ ] Replace `vlocity_cmt__DRBundle__c` references with `OmniDataTransform`
- [ ] Replace `vlocity_cmt__DRMapItem__c` references with `OmniDataTransformItem`
- [ ] Update field references: `vlocity_cmt__PropertySet__c` to `PropertySetConfig`
- [ ] Update field references: `vlocity_cmt__Type__c` to `Type`
- [ ] Update field references: `vlocity_cmt__SubType__c` to `SubType`
- [ ] Update FlexCard: `vlocity_cmt__Definition__c` to `DataSourceConfig`
- [ ] Update DM items: `vlocity_cmt__InterfaceObject__c` to `InputObjectName`
- [ ] Update DM items: `vlocity_cmt__TargetFieldObjectType__c` to `OutputObjectName`

### Deployment

- [ ] Deploy Data Mappers to target org and activate
- [ ] Deploy Integration Procedures to target org and activate
- [ ] Deploy OmniScripts to target org and activate
- [ ] Deploy FlexCards to target org and activate
- [ ] Test each component individually
- [ ] Test end-to-end flows (FlexCard -> OmniScript -> IP -> Data Mapper)

### Post-Migration

- [ ] Verify all components appear in OmniStudio Designer
- [ ] Confirm LWC OmniScripts render correctly (if applicable)
- [ ] Run regression tests on all business processes
- [ ] Monitor error logs for namespace-related failures
- [ ] Deactivate Vlocity components in source org (after validation period)
- [ ] Document any components that required manual adjustment

## Troubleshooting Common Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `INVALID_TYPE: OmniProcess` | Core namespace not installed | Verify Industries Cloud license; try Vlocity namespace queries |
| `sObject type 'vlocity_cmt__OmniScript__c' is not supported` | Vlocity CMT not installed | Use Core namespace queries instead |
| `Entity cannot be found` on retrieve | Component is in Draft state | Activate the component, then retrieve |
| IP action returns null | Referenced IP is inactive or Type_SubType mismatch | Verify IP is active; check `ipMethod` format matches exactly |
| FlexCard shows no data | IP data source misconfigured | Ensure `dataSource.type` uses the plural form `IntegrationProcedures`; verify IP is active |
| Data Mapper Load fails | Missing required fields or FLS violation | Check all required fields are mapped; verify profile has field-level access |
| `OmniDataTransformId` field not found | Foreign key uses long-form spelling | The correct field is `OmniDataTransformationId` — the abbreviated name doesn't exist |
| Circular dependency error | IP A calls IP B which calls IP A | Map call graph; restructure to eliminate cycles |
| OmniScript not rendering | Component inactive or element hierarchy broken | Check `IsActive=true`; verify Level/Order values form valid tree |
| Deployment fails with missing reference | Dependency not yet deployed | Follow deployment order: DM -> IP -> OS -> FlexCard |
| Cached IP returns stale data | TTL not expired; DML cached incorrectly | Clear cache partition; never cache IPs with DML operations |
| PropertySetConfig truncated in SOQL | Long text field exceeds SOQL return limit | Use Tooling API or REST API to fetch full field value |
