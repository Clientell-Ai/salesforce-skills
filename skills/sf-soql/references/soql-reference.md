# SOQL/SOSL Comprehensive Reference

## 1. Complete Date Literals Table

### Standard Date Literals

| Literal | Description | Example |
|---|---|---|
| `YESTERDAY` | Starts 00:00:00 yesterday, ends 00:00:00 today | `SELECT Id FROM Task WHERE ActivityDate = YESTERDAY` |
| `TODAY` | Starts 00:00:00 today, ends 00:00:00 tomorrow | `SELECT Id FROM Lead WHERE CreatedDate = TODAY` |
| `TOMORROW` | Starts 00:00:00 tomorrow, ends 00:00:00 day after | `SELECT Id FROM Event WHERE ActivityDate = TOMORROW` |

### Week Literals

| Literal | Description | Example |
|---|---|---|
| `THIS_WEEK` | Current week (Sunday–Saturday) | `SELECT Id FROM Opportunity WHERE CloseDate = THIS_WEEK` |
| `LAST_WEEK` | Previous week | `SELECT Id FROM Case WHERE CreatedDate = LAST_WEEK` |
| `NEXT_WEEK` | Following week | `SELECT Id FROM Event WHERE ActivityDate = NEXT_WEEK` |

### Month Literals

| Literal | Description | Example |
|---|---|---|
| `THIS_MONTH` | Current calendar month | `SELECT Id FROM Opportunity WHERE CloseDate = THIS_MONTH` |
| `LAST_MONTH` | Previous calendar month | `SELECT SUM(Amount) FROM Opportunity WHERE CloseDate = LAST_MONTH` |
| `NEXT_MONTH` | Following calendar month | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_MONTH` |

### Quarter Literals

| Literal | Description | Example |
|---|---|---|
| `THIS_QUARTER` | Current quarter (Jan–Mar, Apr–Jun, Jul–Sep, Oct–Dec) | `SELECT Id, Amount FROM Opportunity WHERE CloseDate = THIS_QUARTER` |
| `LAST_QUARTER` | Previous quarter | `SELECT COUNT() FROM Opportunity WHERE CloseDate = LAST_QUARTER AND IsWon = true` |
| `NEXT_QUARTER` | Following quarter | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_QUARTER` |

### Year Literals

| Literal | Description | Example |
|---|---|---|
| `THIS_YEAR` | Current calendar year | `SELECT Id, Amount FROM Opportunity WHERE CloseDate = THIS_YEAR` |
| `LAST_YEAR` | Previous calendar year | `SELECT SUM(Amount) FROM Opportunity WHERE CloseDate = LAST_YEAR AND IsWon = true` |
| `NEXT_YEAR` | Following calendar year | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_YEAR` |

### Relative N-Day Literals

| Literal | Description | Example |
|---|---|---|
| `LAST_N_DAYS:n` | Last n days (not including today) | `SELECT Id FROM Lead WHERE CreatedDate = LAST_N_DAYS:30` |
| `NEXT_N_DAYS:n` | Next n days (not including today) | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_N_DAYS:60` |
| `LAST_90_DAYS` | Last 90 days | `SELECT Id FROM Account WHERE LastActivityDate = LAST_90_DAYS` |
| `NEXT_90_DAYS` | Next 90 days | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_90_DAYS` |
| `N_DAYS_AGO:n` | Exactly n days ago | `SELECT Id FROM Task WHERE ActivityDate = N_DAYS_AGO:7` |

### Relative N-Week Literals

| Literal | Description | Example |
|---|---|---|
| `LAST_N_WEEKS:n` | Last n weeks | `SELECT Id FROM Case WHERE CreatedDate = LAST_N_WEEKS:4` |
| `NEXT_N_WEEKS:n` | Next n weeks | `SELECT Id FROM Event WHERE ActivityDate = NEXT_N_WEEKS:2` |
| `N_WEEKS_AGO:n` | Exactly n weeks ago | `SELECT Id FROM Task WHERE CreatedDate > N_WEEKS_AGO:4` |

### Relative N-Month Literals

| Literal | Description | Example |
|---|---|---|
| `LAST_N_MONTHS:n` | Last n months | `SELECT Id FROM Opportunity WHERE CloseDate = LAST_N_MONTHS:6` |
| `NEXT_N_MONTHS:n` | Next n months | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_N_MONTHS:3` |
| `N_MONTHS_AGO:n` | Exactly n months ago | `SELECT Id FROM Account WHERE CreatedDate > N_MONTHS_AGO:12` |

### Relative N-Quarter Literals

| Literal | Description | Example |
|---|---|---|
| `LAST_N_QUARTERS:n` | Last n quarters | `SELECT SUM(Amount) FROM Opportunity WHERE CloseDate = LAST_N_QUARTERS:4 AND IsWon = true` |
| `NEXT_N_QUARTERS:n` | Next n quarters | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_N_QUARTERS:2` |
| `N_QUARTERS_AGO:n` | Exactly n quarters ago | `SELECT Id FROM Opportunity WHERE CloseDate > N_QUARTERS_AGO:2` |

### Relative N-Year Literals

| Literal | Description | Example |
|---|---|---|
| `LAST_N_YEARS:n` | Last n years | `SELECT Id FROM Account WHERE CreatedDate = LAST_N_YEARS:3` |
| `NEXT_N_YEARS:n` | Next n years | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_N_YEARS:1` |
| `N_YEARS_AGO:n` | Exactly n years ago | `SELECT Id FROM Account WHERE CreatedDate > N_YEARS_AGO:5` |

### Fiscal Literals

| Literal | Description | Example |
|---|---|---|
| `THIS_FISCAL_QUARTER` | Current fiscal quarter | `SELECT SUM(Amount) FROM Opportunity WHERE CloseDate = THIS_FISCAL_QUARTER` |
| `LAST_FISCAL_QUARTER` | Previous fiscal quarter | `SELECT Id FROM Opportunity WHERE CloseDate = LAST_FISCAL_QUARTER` |
| `NEXT_FISCAL_QUARTER` | Next fiscal quarter | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_FISCAL_QUARTER` |
| `THIS_FISCAL_YEAR` | Current fiscal year | `SELECT SUM(Amount) FROM Opportunity WHERE CloseDate = THIS_FISCAL_YEAR AND IsWon = true` |
| `LAST_FISCAL_YEAR` | Previous fiscal year | `SELECT SUM(Amount) FROM Opportunity WHERE CloseDate = LAST_FISCAL_YEAR` |
| `NEXT_FISCAL_YEAR` | Next fiscal year | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_FISCAL_YEAR` |
| `LAST_N_FISCAL_QUARTERS:n` | Last n fiscal quarters | `SELECT SUM(Amount) FROM Opportunity WHERE CloseDate = LAST_N_FISCAL_QUARTERS:4` |
| `NEXT_N_FISCAL_QUARTERS:n` | Next n fiscal quarters | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_N_FISCAL_QUARTERS:2` |
| `LAST_N_FISCAL_YEARS:n` | Last n fiscal years | `SELECT SUM(Amount) FROM Opportunity WHERE CloseDate = LAST_N_FISCAL_YEARS:3` |
| `NEXT_N_FISCAL_YEARS:n` | Next n fiscal years | `SELECT Id FROM Opportunity WHERE CloseDate = NEXT_N_FISCAL_YEARS:1` |

---

## 2. SOSL Syntax and Examples

### Basic SOSL Structure

```sql
FIND {searchTerm} IN searchGroup
RETURNING objectList
[WITH filterClause]
[LIMIT n]
```

### FIND Clause with Search Terms

```sql
-- Simple search
FIND {Acme}

-- Phrase search (exact match)
FIND {"John Smith"}

-- Wildcard search
FIND {Acm*}           -- prefix wildcard
FIND {Jo?n}           -- single character wildcard

-- Logical operators
FIND {Acme AND Technology}
FIND {Acme OR Globex}
FIND {Acme AND NOT "Acme Labs"}

-- Escape reserved characters: ? & | ! { } [ ] ( ) ^ ~ * : " ' + -
FIND {acme \& sons}
```

### RETURNING Clause with Field Specs

```sql
-- Multiple objects with fields
FIND {Acme} RETURNING
    Account(Name, Industry, AnnualRevenue WHERE AnnualRevenue > 1000000 ORDER BY Name LIMIT 10),
    Contact(FirstName, LastName, Email WHERE MailingState = 'CA'),
    Opportunity(Name, Amount, StageName)

-- With specific LIMIT per object
FIND {cloud} RETURNING
    Account(Name LIMIT 5),
    Contact(Name LIMIT 10)
```

### IN Clause — Search Groups

```sql
-- Search all searchable fields (default)
FIND {John} IN ALL FIELDS RETURNING Contact(Name, Email)

-- Search only name fields
FIND {John} IN NAME FIELDS RETURNING Contact(Name), Lead(Name)

-- Search only email fields
FIND {john@example.com} IN EMAIL FIELDS RETURNING Contact(Name, Email)

-- Search only phone fields
FIND {415} IN PHONE FIELDS RETURNING Contact(Name, Phone)

-- Search sidebar fields
FIND {Acme} IN SIDEBAR FIELDS RETURNING Account(Name)
```

### WITH Clauses

```sql
-- Division filter
FIND {Acme} RETURNING Account(Name) WITH DIVISION = 'Global'

-- Data category filter (Knowledge articles)
FIND {password reset} RETURNING KnowledgeArticleVersion(Title)
    WITH DATA CATEGORY Geography__c AT USA__c
    AND Products__c ABOVE_OR_BELOW Enterprise__c

-- Network filter (Communities)
FIND {question} RETURNING FeedItem(Id, Body) WITH NETWORK = '0DBxx0000000001'

-- Snippet
FIND {cloud computing} RETURNING KnowledgeArticleVersion(Title WHERE PublishStatus = 'Online')
    WITH SNIPPET(target_length=120)

-- Highlight
FIND {cloud} RETURNING Account(Name) WITH HIGHLIGHT
```

### LIMIT and OFFSET

```sql
-- Global limit across all objects
FIND {Acme} RETURNING Account(Name), Contact(Name) LIMIT 100

-- Per-object limit
FIND {Acme} RETURNING Account(Name LIMIT 20), Contact(Name LIMIT 30)

-- OFFSET for pagination (per object)
FIND {Acme} RETURNING Account(Name LIMIT 20 OFFSET 40)
```

### SOSL vs SOQL Decision Guide

| Criteria | SOQL | SOSL |
|---|---|---|
| Search across multiple objects | No (one object + relationships) | Yes (multiple objects) |
| Text search | LIKE only (slow, no index) | Full-text index (fast) |
| Exact field match | Yes | No |
| Aggregate queries | Yes (COUNT, SUM, etc.) | No |
| Relationship queries | Yes (parent/child) | Limited |
| DML results | Yes | No |
| Governor limit | 100 queries / transaction | 20 searches / transaction |
| Total rows | 50,000 | 2,000 |
| Real-time indexing | Immediate | May have delay |
| Use when | You know which object/field | Searching across objects/fields |

---

## 3. FIELDS() Functions

### FIELDS(ALL), FIELDS(STANDARD), FIELDS(CUSTOM)

```sql
-- All standard fields (no limit required)
SELECT FIELDS(STANDARD) FROM Account WHERE Id = '001xx000003ABCDEF'

-- All custom fields (no limit required)
SELECT FIELDS(CUSTOM) FROM Account WHERE Id = '001xx000003ABCDEF'

-- All fields — requires LIMIT 200
SELECT FIELDS(ALL) FROM Account WHERE Id = '001xx000003ABCDEF' LIMIT 200

-- Combining FIELDS() with explicit fields
SELECT FIELDS(STANDARD), Custom_Score__c, Custom_Rating__c
FROM Account
WHERE Id = '001xx000003ABCDEF'
```

**Rules:**
- `FIELDS(ALL)` requires `LIMIT 200` or fewer (hard requirement).
- `FIELDS(STANDARD)` and `FIELDS(CUSTOM)` have no special limit requirement.
- Cannot use `FIELDS()` in subqueries.
- Cannot use `FIELDS(ALL)` or `FIELDS(CUSTOM)` with `ORDER BY`, `GROUP BY`, or aggregate queries (they may include non-sortable/non-groupable fields).
- Works in REST API, Tooling API, and Apex (API v51.0+).

---

## 4. Geolocation Queries

### DISTANCE Function

```sql
-- Find accounts within 50 miles of a point
SELECT Id, Name, ShippingAddress
FROM Account
WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.7749, -122.4194), 'mi') < 50
ORDER BY DISTANCE(ShippingAddress, GEOLOCATION(37.7749, -122.4194), 'mi')

-- Using kilometers
SELECT Id, Name, BillingAddress
FROM Account
WHERE DISTANCE(BillingAddress, GEOLOCATION(51.5074, -0.1278), 'km') < 100
ORDER BY DISTANCE(BillingAddress, GEOLOCATION(51.5074, -0.1278), 'km')
LIMIT 20

-- Custom geolocation field
SELECT Id, Name, Store_Location__c
FROM Store__c
WHERE DISTANCE(Store_Location__c, GEOLOCATION(40.7128, -74.0060), 'mi') < 10
ORDER BY DISTANCE(Store_Location__c, GEOLOCATION(40.7128, -74.0060), 'mi')
```

**Notes:**
- `DISTANCE()` returns a number (distance in specified unit).
- Supported units: `'mi'` (miles), `'km'` (kilometers).
- Compound address fields (BillingAddress, ShippingAddress) support DISTANCE.
- Custom geolocation fields also support DISTANCE.
- The GEOLOCATION function takes latitude and longitude as decimal numbers.

---

## 5. WITH SECURITY_ENFORCED vs WITH USER_MODE

### Comparison Table

| Feature | SECURITY_ENFORCED | USER_MODE |
|---|---|---|
| Object-level security | Enforced | Enforced |
| Field-level security (FLS) | Enforced | Enforced |
| Sharing rules | Not enforced | Enforced |
| Restriction rules | Not supported | Supported |
| Error behavior | Throws exception if field/object inaccessible | Silently strips inaccessible fields |
| Polymorphic fields | Not supported | Supported |
| Availability | SOQL clause | Database method parameter |
| Recommendation | Legacy (still supported) | Preferred (Spring '23+) |

### SECURITY_ENFORCED Examples

```sql
-- Throws System.QueryException if any field/object is not accessible
SELECT Id, Name, AnnualRevenue
FROM Account
WHERE Industry = 'Technology'
WITH SECURITY_ENFORCED
```

### USER_MODE Examples (Preferred)

```apex
// In Apex — Database method approach
List<Account> accounts = Database.query(
    'SELECT Id, Name, AnnualRevenue FROM Account WHERE Industry = \'Technology\'',
    AccessLevel.USER_MODE
);

// SOQL inline (API v60.0+)
List<Account> accounts = [
    SELECT Id, Name, AnnualRevenue
    FROM Account
    WHERE Industry = 'Technology'
    WITH USER_MODE
];

// DML with USER_MODE
Database.insert(newAccounts, AccessLevel.USER_MODE);
Database.update(existingAccounts, AccessLevel.USER_MODE);
```

### Migration Path

```apex
// BEFORE (legacy)
List<Account> accs = [
    SELECT Id, Name FROM Account WITH SECURITY_ENFORCED
];

// AFTER (recommended)
List<Account> accs = [
    SELECT Id, Name FROM Account WITH USER_MODE
];
```

---

## 6. Dynamic SOQL Builder Pattern

### Database.query() with AccessLevel.USER_MODE

```apex
public class AccountQueryBuilder {
    private List<String> fields = new List<String>();
    private List<String> conditions = new List<String>();
    private String orderByClause;
    private Integer limitCount;
    private Map<String, Object> bindMap = new Map<String, Object>();

    public AccountQueryBuilder selectFields(List<String> fieldNames) {
        this.fields.addAll(fieldNames);
        return this;
    }

    public AccountQueryBuilder whereIndustry(String industry) {
        this.conditions.add('Industry = :industry');
        this.bindMap.put('industry', industry);
        return this;
    }

    public AccountQueryBuilder whereRevenueGreaterThan(Decimal amount) {
        this.conditions.add('AnnualRevenue > :amount');
        this.bindMap.put('amount', amount);
        return this;
    }

    public AccountQueryBuilder whereNameLike(String searchTerm) {
        // For truly dynamic values that can't use bind variables
        String safeTerm = String.escapeSingleQuotes(searchTerm);
        this.conditions.add('Name LIKE \'%' + safeTerm + '%\'');
        return this;
    }

    public AccountQueryBuilder orderBy(String field, String direction) {
        this.orderByClause = String.escapeSingleQuotes(field) + ' ' + direction;
        return this;
    }

    public AccountQueryBuilder limitTo(Integer count) {
        this.limitCount = count;
        return this;
    }

    public String build() {
        if (this.fields.isEmpty()) {
            this.fields.add('Id');
        }

        String query = 'SELECT ' + String.join(this.fields, ', ');
        query += ' FROM Account';

        if (!this.conditions.isEmpty()) {
            query += ' WHERE ' + String.join(this.conditions, ' AND ');
        }

        if (this.orderByClause != null) {
            query += ' ORDER BY ' + this.orderByClause;
        }

        if (this.limitCount != null) {
            query += ' LIMIT ' + this.limitCount;
        }

        return query;
    }

    public List<Account> execute() {
        String query = this.build();
        return Database.queryWithBinds(
            query,
            this.bindMap,
            AccessLevel.USER_MODE
        );
    }
}
```

### Usage

```apex
AccountQueryBuilder builder = new AccountQueryBuilder();
List<Account> results = builder
    .selectFields(new List<String>{'Id', 'Name', 'Industry', 'AnnualRevenue'})
    .whereIndustry('Technology')
    .whereRevenueGreaterThan(1000000)
    .orderBy('Name', 'ASC')
    .limitTo(50)
    .execute();
```

### Safe Bind Variable Usage

```apex
// SAFE: Using bind variables (recommended)
String industry = 'Technology';
List<Account> accounts = Database.query(
    'SELECT Id, Name FROM Account WHERE Industry = :industry'
);

// SAFE: List/Set binding
Set<Id> accountIds = new Set<Id>{'001xx000003ABC', '001xx000003DEF'};
List<Account> accounts = Database.query(
    'SELECT Id, Name FROM Account WHERE Id IN :accountIds'
);

// SAFE: With Database.queryWithBinds (API v57.0+)
Map<String, Object> bindMap = new Map<String, Object>{
    'industry' => 'Technology',
    'minRevenue' => 500000
};
List<Account> results = Database.queryWithBinds(
    'SELECT Id, Name FROM Account WHERE Industry = :industry AND AnnualRevenue > :minRevenue',
    bindMap,
    AccessLevel.USER_MODE
);

// UNSAFE — SOQL Injection risk (avoid!)
String userInput = 'Technology';
// BAD: String concatenation with user input
String query = 'SELECT Id FROM Account WHERE Industry = \'' + userInput + '\'';

// SAFE alternative for truly dynamic values
String query = 'SELECT Id FROM Account WHERE Industry = \'' + String.escapeSingleQuotes(userInput) + '\'';
```

---

## 7. Advanced Aggregate Patterns

### GROUP BY ROLLUP

```sql
-- Subtotals and grand total in one query
SELECT Industry, Rating, COUNT(Id) cnt, SUM(AnnualRevenue) totalRevenue
FROM Account
GROUP BY ROLLUP(Industry, Rating)

-- Result includes:
-- Rows grouped by Industry + Rating
-- Subtotal rows for each Industry (Rating = null)
-- Grand total row (Industry = null, Rating = null)
```

### GROUP BY CUBE

```sql
-- All possible grouping combinations
SELECT Type, StageName, SUM(Amount) totalAmount
FROM Opportunity
GROUP BY CUBE(Type, StageName)

-- Result includes:
-- Rows grouped by Type + StageName
-- Subtotal rows for each Type
-- Subtotal rows for each StageName
-- Grand total row
```

### GROUPING() Function

```sql
-- Identify whether a null is from data or from ROLLUP/CUBE aggregation
SELECT
    Industry,
    Rating,
    GROUPING(Industry) grpIndustry,
    GROUPING(Rating) grpRating,
    COUNT(Id) cnt,
    SUM(AnnualRevenue) totalRevenue
FROM Account
GROUP BY ROLLUP(Industry, Rating)

-- GROUPING() returns 1 if the row is a subtotal/grand total for that column
-- GROUPING() returns 0 if the row is a regular grouped row
```

### HAVING with Multiple Conditions

```sql
SELECT Industry, COUNT(Id) cnt, SUM(AnnualRevenue) totalRevenue
FROM Account
GROUP BY Industry
HAVING COUNT(Id) > 5
    AND SUM(AnnualRevenue) > 1000000
    AND Industry != null
ORDER BY SUM(AnnualRevenue) DESC
```

```sql
-- Combining with date grouping
SELECT CALENDAR_YEAR(CloseDate) yr, CALENDAR_MONTH(CloseDate) mo,
       SUM(Amount) totalAmount, COUNT(Id) dealCount
FROM Opportunity
WHERE IsWon = true
GROUP BY CALENDAR_YEAR(CloseDate), CALENDAR_MONTH(CloseDate)
HAVING SUM(Amount) > 100000
ORDER BY CALENDAR_YEAR(CloseDate) DESC, CALENDAR_MONTH(CloseDate) DESC
```

---

## 8. FOR UPDATE Record Locking

### Pessimistic Locking Pattern

```apex
// Lock records to prevent concurrent modification
List<Account> accounts = [
    SELECT Id, Name, AnnualRevenue
    FROM Account
    WHERE Id = :accountId
    FOR UPDATE
];

// Now these records are locked for the duration of the transaction
// Other transactions trying to lock the same records will wait (up to 10 seconds)
if (!accounts.isEmpty()) {
    accounts[0].AnnualRevenue += 50000;
    update accounts;
}
```

### Lock Timeout Behavior

```apex
try {
    List<Account> accounts = [
        SELECT Id, Name FROM Account WHERE Id = :accountId FOR UPDATE
    ];
    // Process locked records
    update accounts;
} catch (QueryException e) {
    // Record is locked by another transaction
    if (e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
        // Handle lock contention — retry or inform user
        System.debug('Record is currently locked by another process');
    }
}
```

### Usage Guidelines

- Lock timeout is approximately 10 seconds.
- Cannot use `FOR UPDATE` with aggregate queries, COUNT, subqueries, or relationship queries returning locked rows.
- Cannot use in Visualforce `getters` or `@AuraEnabled` methods marked `cacheable=true`.
- Use only when concurrent updates to the same records are likely.
- Keep transactions short to minimize lock duration.
- The lock is released when the transaction commits or rolls back.

---

## 9. ALL ROWS Including Deleted

### Syntax and Use Cases

```sql
-- Include soft-deleted records (in Recycle Bin)
SELECT Id, Name, IsDeleted
FROM Account
WHERE Name LIKE 'Acme%'
ALL ROWS

-- Count including deleted
SELECT COUNT()
FROM Contact
WHERE AccountId = '001xx000003ABC'
ALL ROWS

-- Filter specifically for deleted records
SELECT Id, Name
FROM Account
WHERE IsDeleted = true
ALL ROWS
```

### Deleted Record Retention

- Soft-deleted records are retained for **15 days** in the Recycle Bin.
- After 15 days, records are hard-deleted and no longer queryable even with `ALL ROWS`.
- `ALL ROWS` includes records deleted by merge operations.
- Cannot use `ALL ROWS` with `FOR UPDATE`.

### Audit/Recovery Queries

```apex
// Find recently deleted records for recovery
List<Account> deletedAccounts = [
    SELECT Id, Name, Industry, LastModifiedDate
    FROM Account
    WHERE IsDeleted = true
    ALL ROWS
];

// Undelete recovered records
if (!deletedAccounts.isEmpty()) {
    undelete deletedAccounts;
}

// Audit: count deletions in last 7 days
Integer deletedCount = [
    SELECT COUNT()
    FROM Account
    WHERE IsDeleted = true
        AND SystemModstamp = LAST_N_DAYS:7
    ALL ROWS
];
```

---

## 10. SOQL For Loops

### Automatic 200-Record Batching

```apex
// Standard query — loads ALL records into memory at once (risk of heap limit)
List<Account> allAccounts = [SELECT Id, Name FROM Account];

// SOQL for loop — processes 200 records at a time (heap-efficient)
for (Account acc : [SELECT Id, Name FROM Account]) {
    // Each iteration processes 1 record
    // Internally, Salesforce fetches 200 at a time via query cursors
    acc.Description = 'Processed';
}

// List-based SOQL for loop — explicit 200-record batches
for (List<Account> accountBatch : [SELECT Id, Name FROM Account]) {
    // accountBatch contains up to 200 records
    // Best for bulk DML operations
    update accountBatch;
}
```

### Governor Limit Benefits

| Pattern | Heap Usage | Query Rows | DML Statements |
|---|---|---|---|
| `List<SObject> list = [query]` | All rows in memory | Same | Depends on usage |
| `for (SObject s : [query])` | ~200 rows at a time | Same | 1 per record (risky) |
| `for (List<SObject> batch : [query])` | ~200 rows at a time | Same | 1 per batch (best) |

### Pattern Comparison

```apex
// WORST: Individual DML inside loop
for (Account acc : [SELECT Id FROM Account WHERE Industry = 'Technology']) {
    acc.Description = 'Tech';
    update acc; // DML inside loop — governor limit risk!
}

// BETTER: Collect then DML
List<Account> toUpdate = new List<Account>();
for (Account acc : [SELECT Id FROM Account WHERE Industry = 'Technology']) {
    acc.Description = 'Tech';
    toUpdate.add(acc);
}
update toUpdate; // Single DML — but loads all into heap

// BEST: Batch-based for loop
for (List<Account> batch : [SELECT Id FROM Account WHERE Industry = 'Technology']) {
    for (Account acc : batch) {
        acc.Description = 'Tech';
    }
    update batch; // DML per batch of 200
}
```

---

## 11. Multi-Currency Queries

### convertCurrency() Function

```sql
-- Convert Amount to the user's currency
SELECT Id, Name, convertCurrency(Amount) convertedAmount
FROM Opportunity
WHERE convertCurrency(Amount) > 100000

-- Cannot use convertCurrency with ORDER BY
-- Cannot use convertCurrency in GROUP BY
-- Use the converted value in WHERE clause
SELECT Id, Name, Amount, CurrencyIsoCode
FROM Opportunity
WHERE convertCurrency(Amount) > 50000
```

### Corporate vs Personal Currency

```sql
-- Query the organization's default currency
SELECT IsoCode, ConversionRate, DecimalPlaces
FROM CurrencyType
WHERE IsActive = true
ORDER BY IsoCode

-- Query dated exchange rates (if Advanced Currency Management is enabled)
SELECT IsoCode, StartDate, NextStartDate, ConversionRate
FROM DatedConversionRate
WHERE StartDate <= TODAY AND NextStartDate > TODAY
```

### Querying CurrencyType Object

```apex
// Get all active currencies
List<CurrencyType> activeCurrencies = [
    SELECT IsoCode, ConversionRate, DecimalPlaces, IsCorporate
    FROM CurrencyType
    WHERE IsActive = true
];

// Get corporate currency
CurrencyType corporate = [
    SELECT IsoCode, ConversionRate
    FROM CurrencyType
    WHERE IsCorporate = true
    LIMIT 1
];
```

---

## 12. External Object Queries

### Limitations

```sql
-- External objects (suffix __x) have restricted SOQL support

-- Basic query (supported)
SELECT Id, Name__c, ExternalId
FROM ExternalAccount__x
WHERE Name__c = 'Acme'
LIMIT 100

-- Supported: simple WHERE, ORDER BY, LIMIT
SELECT Id, Name__c, Status__c
FROM ExternalOrder__x
WHERE Status__c = 'Active'
ORDER BY Name__c
LIMIT 50
```

### Limitations Summary

| Feature | Supported? |
|---|---|
| Basic SELECT | Yes |
| WHERE (simple) | Yes |
| ORDER BY | Yes |
| LIMIT | Yes |
| COUNT() | Limited (depends on adapter) |
| Aggregate functions (SUM, AVG) | No |
| GROUP BY | No |
| JOINs / Relationship queries | Limited (indirect lookups only) |
| OFFSET | No |
| FOR UPDATE | No |
| ALL ROWS | No |
| SOQL For Loop | Yes |
| IN clause (large lists) | Limited |

### Cross-Org Queries (Salesforce Connect)

```sql
-- Query external object via Salesforce Connect
SELECT Id, Name__c, Amount__c
FROM External_Opportunity__x
WHERE Stage__c = 'Closed Won'

-- Indirect lookup relationship (external to standard)
SELECT Id, Name, (SELECT Id FROM External_Orders__r)
FROM Account
WHERE Id = :accountId
```

### Performance Considerations

- Each external object query makes a callout to the external system.
- Callout limits apply (100 callouts per transaction).
- Query performance depends on the external system's response time.
- Use selective filters to minimize data transfer.
- Consider caching strategies for frequently accessed data.

---

## 13. Bind Variable Patterns

### Primitive Binding

```apex
String industry = 'Technology';
Integer minEmployees = 100;
Date cutoffDate = Date.today().addDays(-30);

List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WHERE Industry = :industry
        AND NumberOfEmployees > :minEmployees
        AND CreatedDate >= :cutoffDate
];
```

### List/Set Binding

```apex
// List binding
List<String> industries = new List<String>{'Technology', 'Finance', 'Healthcare'};
List<Account> accounts = [
    SELECT Id, Name FROM Account WHERE Industry IN :industries
];

// Set binding (removes duplicates)
Set<Id> accountIds = new Set<Id>();
accountIds.add('001xx000003ABC');
accountIds.add('001xx000003DEF');
List<Account> accounts = [
    SELECT Id, Name FROM Account WHERE Id IN :accountIds
];

// Binding from a map's keyset
Map<Id, Account> accountMap = new Map<Id, Account>([
    SELECT Id, Name FROM Account LIMIT 10
]);
List<Contact> contacts = [
    SELECT Id, Name FROM Contact WHERE AccountId IN :accountMap.keySet()
];
```

### Map Key Binding

```apex
// Use map values in queries
Map<Id, String> accountIndustries = new Map<Id, String>();
// ... populate map

// Bind to map key set
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WHERE Id IN :accountIndustries.keySet()
];
```

### Null Handling

```apex
// Bind variable can be null — this works
String industry = null;
List<Account> accounts = [
    SELECT Id FROM Account WHERE Industry = :industry
];
// Equivalent to: WHERE Industry = null

// Empty list binding — returns no rows (not an error)
List<Id> emptyIds = new List<Id>();
List<Account> accounts = [
    SELECT Id FROM Account WHERE Id IN :emptyIds
];
// Returns empty list

// Null-safe querying pattern
public List<Account> getAccounts(String industry) {
    if (String.isNotBlank(industry)) {
        return [SELECT Id, Name FROM Account WHERE Industry = :industry];
    }
    return [SELECT Id, Name FROM Account];
}
```

---

## 14. Query Plan Interpretation

### EXPLAIN Keyword Usage

In **Developer Console > Query Editor**, check "Use Tooling API" and prepend EXPLAIN:

```
EXPLAIN SELECT Id, Name FROM Account WHERE Name = 'Acme'
```

Or via Tooling API REST:

```
/services/data/v59.0/tooling/query?explain=SELECT+Id,Name+FROM+Account+WHERE+Name='Acme'
```

### Understanding the Query Plan Response

```json
{
  "plans": [
    {
      "cardinality": 3,
      "fields": ["Name"],
      "leadingOperationType": "Index",
      "relativeCost": 0.12,
      "sobjectCardinality": 50000,
      "sobjectType": "Account",
      "notes": [
        {
          "description": "Index on Account.Name",
          "fields": ["Name"],
          "tableEnumOrId": "Account"
        }
      ]
    }
  ]
}
```

### Key Metrics

| Metric | Description | Ideal Value |
|---|---|---|
| `cardinality` | Estimated rows returned | Low relative to total |
| `relativeCost` | Query cost (lower is better) | < 1.0 |
| `sobjectCardinality` | Total records in object | Context for selectivity |
| `leadingOperationType` | `Index`, `TableScan`, or `Other` | `Index` preferred |

### Selective vs Non-Selective Filters

A filter is **selective** when it returns less than a threshold of total records:

| Total Records | Selectivity Threshold |
|---|---|
| < 100,000 | < 30% of total records |
| 100,000 – 1,000,000 | < 15% of total records |
| > 1,000,000 | < 10% of total records |

Additionally, the filter must return **fewer than 333,333 records** regardless of percentage.

### Fields with Standard Indexes

The following fields have standard indexes (no custom index needed):

- `Id`
- `Name`
- `OwnerId`
- `CreatedDate`
- `SystemModstamp` / `LastModifiedDate`
- `RecordTypeId`
- `Foreign key fields` (lookup/master-detail)
- `Email` (on Contact, Lead)

### Custom Index Considerations

```sql
-- GOOD: Uses index (equality on indexed field)
SELECT Id FROM Account WHERE Name = 'Acme'

-- GOOD: Uses index (lookup field)
SELECT Id FROM Contact WHERE AccountId = '001xx000003ABC'

-- BAD: Negative filter — cannot use index
SELECT Id FROM Account WHERE Name != 'Acme'

-- BAD: Leading wildcard — cannot use index
SELECT Id FROM Account WHERE Name LIKE '%cme'

-- GOOD: Trailing wildcard — can use index
SELECT Id FROM Account WHERE Name LIKE 'Acm%'

-- BAD: OR with non-indexed field — full scan
SELECT Id FROM Account WHERE Name = 'Acme' OR Description = 'test'

-- BAD: Null comparison on indexed field — often non-selective
SELECT Id FROM Account WHERE Custom_Field__c = null

-- GOOD: Compound filter where at least one is selective
SELECT Id FROM Account
WHERE Name = 'Acme'
    AND Industry = 'Technology'

-- Request custom index via Salesforce Support for:
-- Custom fields used frequently in WHERE clauses
-- Fields with high cardinality (many unique values)
-- External ID fields (automatically indexed)
```

### Skinny Tables

- Salesforce can create "skinny tables" for frequently queried objects.
- Contains a subset of fields for faster reads.
- Must be requested via Salesforce Support.
- Not visible in SOQL — the optimizer uses them automatically.
- Ideal for reports and list views on objects with many fields.
