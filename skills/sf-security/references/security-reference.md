# Salesforce Enterprise Security Reference

## 1. FLS Schema API Checks

### Object-Level Checks
```apex
// Check object accessibility before query
if (Schema.sObjectType.Account.isAccessible()) {
    List<Account> accounts = [SELECT Id, Name FROM Account];
}

// Check object createability before insert
if (Schema.sObjectType.Account.isCreateable()) {
    insert new Account(Name = 'Test');
}

// Check object updateability before update
if (Schema.sObjectType.Account.isUpdateable()) {
    update accountRecord;
}

// Check object deletability before delete
if (Schema.sObjectType.Account.isDeletable()) {
    delete accountRecord;
}
```

### Field-Level Checks
```apex
// Check individual field accessibility
if (Schema.sObjectType.Account.fields.Name.getDescribe().isAccessible()) {
    // Safe to read Name field
}

if (Schema.sObjectType.Account.fields.AnnualRevenue.getDescribe().isUpdateable()) {
    // Safe to update AnnualRevenue field
}

if (Schema.sObjectType.Account.fields.Industry.getDescribe().isCreateable()) {
    // Safe to set Industry on insert
}
```

### Pre-Check Pattern Before CRUD Operations
```apex
public class SecureAccountService {

    public static List<Account> getAccounts(Set<Id> accountIds) {
        // Object-level check
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new SecurityException('No read access to Account');
        }

        // Field-level checks
        List<String> accessibleFields = new List<String>();
        Map<String, Schema.SObjectField> fieldMap =
            Schema.sObjectType.Account.fields.getMap();

        for (String fieldName : new List<String>{'Name', 'Industry', 'AnnualRevenue', 'Phone'}) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            if (dfr.isAccessible()) {
                accessibleFields.add(fieldName);
            }
        }

        String query = 'SELECT Id, ' + String.join(accessibleFields, ', ') +
            ' FROM Account WHERE Id IN :accountIds';
        return Database.query(query);
    }

    public static void updateAccounts(List<Account> accounts) {
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new SecurityException('No update access to Account');
        }

        // Strip inaccessible fields before DML
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE, accounts
        );
        update decision.getRecords();
    }
}
```

### Bulk Field Describe Pattern
```apex
Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Contact.fields.getMap();
for (String fieldName : fieldMap.keySet()) {
    Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
    System.debug(fieldName + ' -> Accessible: ' + dfr.isAccessible()
        + ', Createable: ' + dfr.isCreateable()
        + ', Updateable: ' + dfr.isUpdateable());
}
```

---

## 2. Sharing Model Deep Dive

### Organization-Wide Defaults (OWD)

| OWD Setting             | Description                                                        |
|--------------------------|--------------------------------------------------------------------|
| **Private**              | Only record owner and users above in role hierarchy can access     |
| **Public Read Only**     | All users can read, but only owner/hierarchy can edit              |
| **Public Read/Write**    | All users can read and edit all records                            |
| **Controlled by Parent** | Access determined by parent record (detail in master-detail)       |

### Role Hierarchy
- Opens access **upward** (managers see subordinates' records)
- Does NOT restrict access
- Can be disabled for custom objects via "Grant Access Using Hierarchies" checkbox
- Standard objects always respect role hierarchy

### Criteria-Based Sharing Rules
```
Rule: Share Accounts where Industry = 'Technology'
Share with: Role = Sales Manager
Access Level: Read/Write
```
- Evaluated when record is created or edited
- Based on field values, not ownership
- Supports formula-based criteria

### Owner-Based Sharing Rules
```
Rule: Share records owned by Role = Eastern Sales
Share with: Role = Western Sales
Access Level: Read Only
```
- Based on record ownership (user, role, group)

### Territory Management
- Enterprise Territory Management (ETM) for account-based territories
- Territory types, territory models, assignment rules
- Supports multiple territory hierarchies simultaneously
- Territory-based sharing rules

---

## 3. Apex Managed Sharing

### Share Object Structure
Every standard/custom object with Private OWD has a corresponding Share object:
- `AccountShare`, `OpportunityShare`, `CaseShare`, `LeadShare`
- Custom objects: `MyObject__Share`

### Share Record Fields

| Field            | Description                                           |
|------------------|-------------------------------------------------------|
| `ParentId`       | ID of the record being shared (e.g., AccountId)       |
| `UserOrGroupId`  | User, Role, or Public Group receiving access           |
| `AccessLevel`    | `Read`, `Edit`, or `All`                              |
| `RowCause`       | Reason for sharing (e.g., `Manual`, custom reason)     |

### AccountShare Example
```apex
AccountShare share = new AccountShare();
share.AccountId = accountId;
share.UserOrGroupId = userId;
share.AccountAccessLevel = 'Edit';
share.OpportunityAccessLevel = 'Read';
share.RowCause = Schema.AccountShare.RowCause.Manual;

Database.SaveResult sr = Database.insert(share, false);
if (!sr.isSuccess()) {
    for (Database.Error err : sr.getErrors()) {
        System.debug('Share insert error: ' + err.getMessage());
    }
}
```

### Custom Object Share with Apex Sharing Reason
```apex
// Define sharing reason in custom object metadata first
// Then use in Apex:
MyObject__Share share = new MyObject__Share();
share.ParentId = recordId;
share.UserOrGroupId = userId;
share.AccessLevel = 'Edit';
share.RowCause = Schema.MyObject__Share.RowCause.Team_Member__c;
insert share;
```

### Bulk Sharing Pattern
```apex
public class BulkSharingService {

    public static void shareRecordsWithTeam(List<Id> recordIds, Id groupId) {
        List<MyObject__Share> shares = new List<MyObject__Share>();

        for (Id recordId : recordIds) {
            MyObject__Share share = new MyObject__Share();
            share.ParentId = recordId;
            share.UserOrGroupId = groupId;
            share.AccessLevel = 'Edit';
            share.RowCause = Schema.MyObject__Share.RowCause.Team_Member__c;
            shares.add(share);
        }

        List<Database.SaveResult> results = Database.insert(shares, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug('Failed to share record ' + recordIds[i]);
            }
        }
    }
}
```

### Deleting Shares
```apex
List<AccountShare> sharesToDelete = [
    SELECT Id FROM AccountShare
    WHERE AccountId = :accountId
    AND RowCause = :Schema.AccountShare.RowCause.Manual
    AND UserOrGroupId = :userId
];
delete sharesToDelete;
```

---

## 4. Shield Platform Encryption

### Encrypted Field Types
- Text, Text Area, Long Text Area, Rich Text Area
- Email, Phone, URL
- Date, Date/Time

### Deterministic vs Probabilistic

| Feature              | Deterministic                      | Probabilistic                      |
|----------------------|------------------------------------|------------------------------------|
| Filter in SOQL       | Yes (exact match, case-insensitive)| No                                 |
| Unique enforcement   | Yes                                | No                                 |
| Grouping             | Yes (GROUP BY, DISTINCT)           | No                                 |
| Security strength    | Strong                             | Strongest                          |

### Bring Your Own Key (BYOK)
- Upload tenant secrets or key material
- Customer controls key lifecycle (rotation, destruction)
- Compatible with HSM-generated keys
- Key rotation does not require data re-encryption (envelope encryption)

### Key Management
```
Setup > Platform Encryption > Key Management
- Generate tenant secret
- Upload customer-supplied key material
- Archive/destroy keys
- Key rotation (recommended every 12 months)
```

### Limitations
- Encrypted fields cannot be used in:
  - SOQL WHERE, ORDER BY, GROUP BY (unless deterministic)
  - Formula fields (cannot reference encrypted fields)
  - Criteria-based sharing rules
  - Standard/custom report filters
  - SOSL searches
- Maximum encrypted fields per object varies by license

---

## 5. Event Monitoring

### Key Event Types

| Event Type        | Description                                | Use Case                        |
|-------------------|--------------------------------------------|---------------------------------|
| Login             | User login attempts                        | Detect anomalous logins         |
| API               | API calls                                  | Monitor integrations            |
| Report Export     | Report exports/prints                      | Prevent data exfiltration       |
| Bulk API          | Bulk API operations                        | Large data movement detection   |
| Data Export        | Data Loader exports                        | Track mass downloads            |
| URI               | Page view events                           | Usage analytics                 |
| Lightning Page View| Lightning page loads                      | Adoption tracking               |

### Transaction Security Policies
```
Condition Builder or Apex Policy:
- Event: ReportEvent
- Condition: Report rows > 10000
- Action: Block + Notify Admin

- Event: LoginEvent
- Condition: LoginGeo.Country != 'United States'
- Action: Require MFA (raise session level)
```

### Apex Transaction Security Policy
```apex
global class DataExportPolicy implements TxnSecurity.PolicyCondition {
    public boolean evaluate(TxnSecurity.Event e) {
        // Block large data exports outside business hours
        Integer hour = DateTime.now().hour();
        if (hour < 6 || hour > 22) {
            if (e.getAttribute('NumberOfRecords') > 5000) {
                return true; // Trigger the action (block/alert)
            }
        }
        return false;
    }
}
```

### Real-Time vs Historical
- **Real-time**: Transaction Security policies evaluate as events occur
- **Historical**: EventLogFile objects stored for 30 days (1 day with add-on), queryable via SOQL/REST

---

## 6. OAuth Flows for Connected Apps

### Web Server Flow (Authorization Code)
```
1. Redirect user to: https://login.salesforce.com/services/oauth2/authorize
   ?response_type=code
   &client_id=CONSUMER_KEY
   &redirect_uri=CALLBACK_URL

2. User authorizes, Salesforce redirects to callback with ?code=AUTH_CODE

3. Server exchanges code for tokens:
   POST https://login.salesforce.com/services/oauth2/token
   grant_type=authorization_code
   &code=AUTH_CODE
   &client_id=CONSUMER_KEY
   &client_secret=CONSUMER_SECRET
   &redirect_uri=CALLBACK_URL

4. Response includes access_token, refresh_token, instance_url
```

### JWT Bearer Token Flow (Server-to-Server)
```
1. Create Connected App with digital certificate
2. Build JWT:
   Header: {"alg": "RS256"}
   Claims: {
     "iss": "CONSUMER_KEY",
     "sub": "user@example.com",
     "aud": "https://login.salesforce.com",
     "exp": <expiry_timestamp>
   }
3. Sign JWT with private key

4. POST https://login.salesforce.com/services/oauth2/token
   grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer
   &assertion=SIGNED_JWT

5. Response includes access_token, instance_url (no refresh_token)
```

### User-Agent Flow (Implicit)
```
1. Redirect to: https://login.salesforce.com/services/oauth2/authorize
   ?response_type=token
   &client_id=CONSUMER_KEY
   &redirect_uri=CALLBACK_URL

2. Token returned in URL fragment: #access_token=...&instance_url=...
   (Less secure — token exposed in URL, no refresh token)
```

### Device Flow
```
1. POST https://login.salesforce.com/services/oauth2/token
   grant_type=device_code
   &client_id=CONSUMER_KEY

2. Response: device_code, user_code, verification_uri

3. User visits verification_uri, enters user_code

4. Poll token endpoint with device_code until authorized
```

### Refresh Tokens
```
POST https://login.salesforce.com/services/oauth2/token
grant_type=refresh_token
&refresh_token=REFRESH_TOKEN
&client_id=CONSUMER_KEY
&client_secret=CONSUMER_SECRET
```

### Common Scopes
- `api` — Access REST/SOAP APIs
- `refresh_token` / `offline_access` — Obtain refresh token
- `full` — Full access
- `web` — Access web UI
- `chatter_api` — Chatter REST API
- `custom_permissions` — Custom permission access

---

## 7. Session Security

### Session Timeout Settings
```
Setup > Session Settings:
- Timeout value: 15 min to 24 hours (default 2 hours)
- Force logout on session timeout: enabled/disabled
- Lock sessions to IP address from which they originated
- Lock sessions to domain
```

### Login IP Ranges
- Defined per Profile
- Users outside range are completely blocked from login
- No email verification bypass

### Trusted IP Ranges
- Defined in Network Access (org-wide)
- Users within range skip identity verification (email/SMS)
- Does NOT block access from other IPs

### Session Security Levels

| Level             | Granted When                            | Use Case                    |
|-------------------|------------------------------------------|-----------------------------|
| Standard          | Username/password login                  | Normal access               |
| High Assurance    | MFA verified, Trusted IP + policy        | Sensitive operations        |

### MFA Enforcement
```
Setup > Identity Verification:
- Require MFA for all users (org-wide)
- Require MFA for specific profiles
- Require High Assurance for Connected Apps
- Session policy: "High Assurance" requirement per Connected App
```

### Raising Session Level in Apex
```apex
if (!Auth.SessionManagement.isIpAllowlisted()) {
    Auth.SessionManagement.setSessionLevel(Auth.SessionLevel.HIGH_ASSURANCE);
}
```

---

## 8. Certificate-Based Authentication

### Digital Certificates in Salesforce
```
Setup > Certificate and Key Management:
- Create self-signed certificate
- Create CA-signed certificate request (CSR)
- Import certificate
- Export certificate (public key)
```

### Mutual TLS (mTLS)
```
Setup > Certificate and Key Management:
- Upload mutual authentication certificate
- Configure API client certificate
- Associate with Named Credential for outbound calls

Named Credential configuration:
- Authentication Protocol: Certificate
- Certificate: Select uploaded cert
```

### JWT Certificate Signing
```apex
// Sign JWT with Salesforce certificate for outbound auth
Auth.JWT jwt = new Auth.JWT();
jwt.setSub('user@example.com');
jwt.setAud('https://target-system.com');
jwt.setIss('salesforce-org-id');

Auth.JWS jws = new Auth.JWS(jwt, 'My_Certificate_Name');
String token = jws.getCompactSerialization();

HttpRequest req = new HttpRequest();
req.setHeader('Authorization', 'Bearer ' + token);
```

---

## 9. CSRF Protection

### Salesforce Built-In CSRF Tokens
- Salesforce automatically includes anti-CSRF tokens in all standard pages
- Tokens are validated server-side on form submission
- Unique per user session

### Visualforce Automatic Protection
```html
<!-- apex:form automatically includes CSRF token -->
<apex:form>
    <apex:commandButton action="{!save}" value="Save"/>
</apex:form>

<!-- CSRF token is embedded as hidden field: _CONFIRMATIONTOKEN -->
```

### REST API Considerations
- REST API uses OAuth tokens (not session cookies), inherently CSRF-resistant
- Custom REST endpoints should validate Origin/Referer headers for browser-based calls
- Lightning components use CSRF tokens automatically via Aura/LWC framework

### Custom Visualforce CSRF Mitigation
```apex
// Verify that the request contains valid CSRF token
// This is automatic for apex:commandButton/apex:actionFunction
// For JavaScript remoting, tokens are handled by the framework

// DANGEROUS: Using onclick with JavaScript actions bypasses CSRF protection
// Avoid: <button onclick="window.location='...'">
```

---

## 10. Clickjacking Protection

### Salesforce Default Protections
```
Setup > Session Settings:
- Enable clickjack protection for setup pages (default: ON)
- Enable clickjack protection for non-setup pages (default: ON)
- Enable clickjack protection for customer Visualforce pages
  with standard headers (default: ON)
- Enable clickjack protection for customer Visualforce pages
  with headers disabled (default: OFF — enable this!)
```

### Headers Set by Salesforce
```http
X-Frame-Options: SAMEORIGIN
Content-Security-Policy: frame-ancestors 'self'
```

### Visualforce Pages with showHeader="false"
```html
<!-- Must explicitly enable clickjack protection -->
<apex:page showHeader="false">
    <!-- Without the session setting enabled, this page can be iframed -->
</apex:page>
```

### Custom CSP for Lightning Components
```javascript
// Lightning Locker / Lightning Web Security handles CSP automatically
// For external scripts, add to CSP Trusted Sites:
// Setup > CSP Trusted Sites > New
// Trusted Site URL: https://cdn.example.com
// Context: Lightning Components
```

---

## 11. Data Classification & Compliance

### GDPR Patterns

#### Right to Deletion (Right to be Forgotten)
```apex
public class GDPRDeletionService {
    public static void processErasureRequest(String email) {
        // Find all related records
        List<Contact> contacts = [
            SELECT Id FROM Contact WHERE Email = :email
        ];
        List<Lead> leads = [
            SELECT Id FROM Lead WHERE Email = :email
        ];

        // Delete or anonymize records
        // Consider: Cases, Activities, Campaign Members, etc.
        delete contacts;
        delete leads;

        // Log the erasure for compliance
        GDPR_Erasure_Log__c log = new GDPR_Erasure_Log__c();
        log.Request_Date__c = Date.today();
        log.Status__c = 'Completed';
        log.Records_Processed__c = contacts.size() + leads.size();
        insert log;
    }
}
```

#### Consent Management
```apex
// Individual object for consent tracking (standard Salesforce)
Individual ind = new Individual();
ind.FirstName = 'John';
ind.LastName = 'Doe';
ind.HasOptedOutProcessing = false;
ind.HasOptedOutSolicit = true;
ind.ShouldForget = false;
insert ind;

// Link to Contact
Contact c = [SELECT Id FROM Contact WHERE Id = :contactId];
c.IndividualId = ind.Id;
update c;
```

### Data Residency
- Hyperforce: choose data center region
- Data residency add-on for specific regions
- Cross-region replication considerations

### Field Audit Trail (Shield)
- Retain field history data up to 10 years
- Define retention policies per object/field
- Archived data queryable via FieldHistoryArchive big object
```apex
// Query archived field history
List<FieldHistoryArchive> history = [
    SELECT ParentId, FieldName, OldValue, NewValue, CreatedDate
    FROM FieldHistoryArchive
    WHERE ParentId = :accountId
    AND FieldName = 'AnnualRevenue'
    ORDER BY CreatedDate DESC
];
```

---

## 12. Guest User Security

### Guest User Profile Hardening
```
Setup > Sites > [Site Name] > Public Access Settings:
- Minimize object permissions (principle of least privilege)
- Remove ALL unnecessary object access
- Never grant Modify All or View All
- Restrict field-level security strictly
```

### Site-Level Sharing
```
- Guest users operate under a special sharing model
- "Secure guest user record access" (enforced since Spring '20)
- Records created by guest users default to owner = site guest user
- Must explicitly share records created by guest users with other users
```

### Unauthenticated Access Hardening Checklist
- [ ] Review all Visualforce pages marked "Available for public"
- [ ] Audit all Apex classes with guest profile access
- [ ] Review Lightning components exposed to guest users
- [ ] Check all flows accessible to guest users
- [ ] Remove guest user access to any non-essential APIs
- [ ] Disable API access on guest user profile
- [ ] Set restrictive Login IP Ranges for guest user profile
- [ ] Review all sharing rules that include guest user groups

---

## 13. AppExchange Security Review Checklist

### CRUD/FLS Enforcement
- [ ] All SOQL queries use `WITH USER_MODE` or manual FLS checks
- [ ] All DML operations use `AccessLevel.USER_MODE` or `Security.stripInaccessible()`
- [ ] Schema.Describe checks before dynamic SOQL/DML

### Sharing Model
- [ ] All Apex classes use `with sharing` by default
- [ ] Any `without sharing` class has documented justification
- [ ] `inherited sharing` used for utility classes

### Injection Prevention
- [ ] No direct string concatenation in SOQL/SOSL queries
- [ ] Bind variables used wherever possible
- [ ] `String.escapeSingleQuotes()` used for unavoidable dynamic queries
- [ ] `URLFOR()` or `EncodingUtil.urlEncode()` for URL construction

### XSS Prevention
- [ ] No `escape="false"` in Visualforce unless HTML is fully sanitized
- [ ] `JSENCODE()` used for JavaScript string contexts
- [ ] `HTMLENCODE()` used for HTML contexts
- [ ] `URLENCODE()` used for URL parameter contexts
- [ ] LWC: No `lwc:dom="manual"` with unsanitized content, no `innerHTML`

### CSRF Protection
- [ ] All state-changing operations use `apex:form` / `apex:commandButton`
- [ ] No state changes via GET requests

### Hardcoded Credentials
- [ ] No API keys, passwords, or tokens in source code
- [ ] Named Credentials used for all external callouts
- [ ] Custom Settings or Custom Metadata for configurable values
- [ ] No credentials in debug logs

### Debug Logging
- [ ] No `System.debug()` of sensitive data (PII, credentials, tokens)
- [ ] Debug mode disabled in production
- [ ] No verbose logging that exposes internal logic

### Open Redirects
- [ ] No user-controlled redirect URLs without validation
- [ ] Allowlist of valid redirect domains
- [ ] `PageReference` used instead of string URLs where possible

### SSL/TLS
- [ ] All external callouts use HTTPS
- [ ] No SSL certificate validation bypasses
- [ ] TLS 1.2+ enforced

### Sensitive Data Exposure
- [ ] No PII in URL parameters
- [ ] Proper field-level encryption for sensitive data
- [ ] No sensitive data in client-side JavaScript/LWC

### Insecure Deserialization
- [ ] No `JSON.deserialize()` with user-supplied type names
- [ ] Type-safe deserialization with known classes
- [ ] No `Type.forName()` with user input

### Additional Checks
- [ ] No dynamic Apex class instantiation from user input
- [ ] Custom Permission checks for sensitive features
- [ ] Remote Site Settings properly scoped (not overly broad)
- [ ] API version is current (not deprecated)
- [ ] Error messages don't expose stack traces or internal details to users
- [ ] Governor limit awareness and bulkification
