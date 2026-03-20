# Integration Configuration Reference

Metadata XML templates, auth flow details, and architecture decision guides for Salesforce integration setup.

> **Scope**: This file covers configuration and metadata. For Apex callout code patterns, see [integration-patterns.md](../../sf-apex/references/integration-patterns.md).

---

## 1. Named Credential XML Templates

### Legacy Named Credential -- Password Auth

```xml
<?xml version="1.0" encoding="UTF-8"?>
<NamedCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Legacy_Service</fullName>
    <label>Legacy Service</label>
    <endpoint>https://api.example.com/v1</endpoint>
    <principalType>NamedUser</principalType>
    <protocol>Password</protocol>
    <username>service_account</username>
</NamedCredential>
```

Legacy `protocol` values: `Password`, `Oauth`, `Jwt`, `JwtExchange`, `AwsSv4`, `NoAuthentication`. For no-auth (URL whitelisting only), set `principalType` to `Anonymous` and `protocol` to `NoAuthentication`.

### Enhanced Named Credential

```xml
<?xml version="1.0" encoding="UTF-8"?>
<NamedCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Enhanced_Service</fullName>
    <label>Enhanced Service</label>
    <endpoint>https://api.example.com/v2</endpoint>
    <externalCredential>Enhanced_Service_Auth</externalCredential>
    <generateAuthorizationHeader>true</generateAuthorizationHeader>
    <allowMergeFieldsInBody>false</allowMergeFieldsInBody>
    <allowMergeFieldsInHeader>true</allowMergeFieldsInHeader>
</NamedCredential>
```

---

## 2. External Credential XML with Permission Set Mapping

### OAuth External Credential

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ExternalCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Service_OAuth</fullName>
    <label>Service OAuth</label>
    <authenticationProtocol>Oauth</authenticationProtocol>
    <externalCredentialParameters>
        <parameterName>ClientId</parameterName>
        <parameterType>AuthProviderUrl</parameterType>
        <parameterValue>your_client_id</parameterValue>
    </externalCredentialParameters>
    <externalCredentialParameters>
        <parameterName>TokenUrl</parameterName>
        <parameterType>AuthProviderUrl</parameterType>
        <parameterValue>https://auth.example.com/oauth2/token</parameterValue>
    </externalCredentialParameters>
    <externalCredentialParameters>
        <parameterName>Scope</parameterName>
        <parameterType>AuthParameter</parameterType>
        <parameterValue>api read</parameterValue>
    </externalCredentialParameters>
    <principals>
        <principalName>ServicePrincipal</principalName>
        <principalType>NamedPrincipal</principalType>
        <sequenceNumber>1</sequenceNumber>
    </principals>
</ExternalCredential>
```

For custom header auth (e.g., API key), use `authenticationProtocol` `Custom` with `parameterType` `AuthHeader`.

### Permission Set Mapping (Required)

```xml
<!-- In a Permission Set -->
<externalCredentialPrincipalAccesses>
    <enabled>true</enabled>
    <externalCredentialPrincipal>Service_OAuth - ServicePrincipal</externalCredentialPrincipal>
</externalCredentialPrincipalAccesses>
```

Format: `<ExternalCredentialName> - <PrincipalName>`. Missing this mapping causes `NAMED_CREDENTIAL_NOT_FOUND` at runtime.

---

## 3. Connected App Metadata XML

### Standard OAuth Connected App

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ConnectedApp xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>MyWebApp</fullName>
    <label>My Web App</label>
    <contactEmail>admin@example.com</contactEmail>
    <oauthConfig>
        <callbackUrl>https://myapp.example.com/oauth/callback</callbackUrl>
        <consumerKey>AUTO_GENERATED</consumerKey>
        <isAdminApproved>false</isAdminApproved>
        <isConsumerSecretOptional>false</isConsumerSecretOptional>
        <scopes>Api</scopes>
        <scopes>RefreshToken</scopes>
    </oauthConfig>
    <oauthPolicy>
        <ipRelaxation>ENFORCE</ipRelaxation>
        <refreshTokenPolicy>SPECIFIC_LIFETIME</refreshTokenPolicy>
        <refreshTokenValidityPeriod>720</refreshTokenValidityPeriod>
        <refreshTokenValidityUnits>HOURS</refreshTokenValidityUnits>
    </oauthPolicy>
</ConnectedApp>
```

### JWT Bearer Differences

Add `<certificate>JWTSigningCert</certificate>` in oauthConfig. Set `isAdminApproved` to `true` and `isConsumerSecretOptional` to `true`.

### Client Credentials Differences

Add `<isClientCredentialFlowEnabled>true</isClientCredentialFlowEnabled>` in oauthConfig. Set `isAdminApproved` to `true`. Set `refreshTokenPolicy` to `IMMEDIATE_EXPIRATION`. Requires assigning a run-as user in Setup.

---

## 4. External Service Registration

### Steps

1. Prepare OpenAPI 3.0 spec (JSON or YAML, max 100 KB)
2. Create Named Credential for the API base URL
3. Setup > External Services > New External Service
4. Provide spec (paste, upload, or URL) and review parsed operations
5. Save -- invocable actions are generated for use in Flows

### Metadata

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ExternalServiceRegistration xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>OrderService</fullName>
    <label>Order Service</label>
    <namedCredential>Order_API</namedCredential>
    <schema>{... OpenAPI 3.0 JSON ...}</schema>
    <schemaType>OpenApi3</schemaType>
    <status>Complete</status>
</ExternalServiceRegistration>
```

### OpenAPI Spec Tips

- Keep schemas flat -- deeply nested objects may fail parsing
- Define `operationId` for each endpoint (used as the Flow action name)
- Auth defined in spec is ignored -- Salesforce uses the Named Credential
- Polymorphic schemas (`oneOf`, `anyOf`) may not parse correctly

---

## 5. Platform Event Definition XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Integration_Event__e</fullName>
    <label>Integration Event</label>
    <pluralLabel>Integration Events</pluralLabel>
    <publishBehavior>PublishAfterCommit</publishBehavior>
    <fields>
        <fullName>Event_Type__c</fullName>
        <label>Event Type</label>
        <type>Text</type>
        <length>50</length>
    </fields>
    <fields>
        <fullName>Payload__c</fullName>
        <label>Payload</label>
        <type>LongTextArea</type>
        <length>131072</length>
        <visibleLines>5</visibleLines>
    </fields>
</CustomObject>
```

### Subscriber Error Handling

```apex
trigger IntegrationEventTrigger on Integration_Event__e (after insert) {
    for (Integration_Event__e event : Trigger.new) {
        try {
            IntegrationEventHandler.process(event);
        } catch (Exception e) {
            // Set checkpoint to prevent infinite retry loop
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(event.ReplayId);
        }
    }
}
```

Publishing from Flow: use a "Create Records" element targeting the Platform Event object.

---

## 6. CDC Enablement and Subscriber Trigger

### Enabling via Metadata

```xml
<ChangeDataCaptureSettings xmlns="http://soap.sforce.com/2006/04/metadata">
    <enableChangeDataCapture>true</enableChangeDataCapture>
    <selectedEntities>Account</selectedEntities>
    <selectedEntities>Contact</selectedEntities>
</ChangeDataCaptureSettings>
```

### Subscriber Pattern

```apex
trigger AccountCDCTrigger on AccountChangeEvent (after insert) {
    for (AccountChangeEvent event : Trigger.new) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        switch on header.getChangeType() {
            when 'CREATE' {
                // Handle new records -- header.getRecordIds() has the IDs
            }
            when 'UPDATE' {
                if (header.getChangedFields().contains('OwnerId')) {
                    // React to ownership changes
                }
            }
            when 'DELETE' {
                // Audit deletion
            }
        }
    }
}
```

### CDC Channels

| Object type | Channel |
|-------------|---------|
| Standard (Account) | `/data/AccountChangeEvent` |
| Custom (Order__c) | `/data/Order__ChangeEvent` |
| All changes | `/data/ChangeEvents` |

---

## 7. Auth Flow Comparison (Detailed)

| Dimension | JWT Bearer | Web Server | Auth Code + PKCE | Client Credentials | Device Flow |
|-----------|-----------|------------|------------------|-------------------|-------------|
| **User interaction** | None | Browser redirect | Browser redirect | None | Out-of-band |
| **Client type** | Confidential | Confidential | Public | Confidential | Either |
| **Credentials** | X.509 cert + key | Key + secret | Key + code verifier | Key + secret | Consumer key |
| **User context** | Yes (pre-auth'd) | Yes (authorizing) | Yes (authorizing) | No (run-as) | Yes |
| **Grant type** | `urn:ietf:params:oauth:grant-type:jwt-bearer` | `authorization_code` | `authorization_code` | `client_credentials` | `device_code` |
| **Refresh token** | No (re-sign JWT) | Yes (if scoped) | Yes (if scoped) | No | Yes (if scoped) |
| **Best for** | CI/CD, backends | Web portals | SPAs, mobile | Service accounts | CLI, IoT |

### Token Endpoint URLs

| Environment | URL |
|-------------|-----|
| Production | `https://login.salesforce.com/services/oauth2/token` |
| Sandbox | `https://test.salesforce.com/services/oauth2/token` |
| My Domain | `https://[domain].my.salesforce.com/services/oauth2/token` |

---

## 8. Callout Limits

| Limit | Sync | Async |
|-------|------|-------|
| Max callouts per transaction | 100 | 100 |
| Max timeout per callout | 120s | 120s |
| Max request/response size | 6 MB (heap) | 12 MB (heap) |
| Max endpoint URL length | 2,048 chars | 2,048 chars |

For retry patterns using Queueable with backoff, see [integration-patterns.md](../../sf-apex/references/integration-patterns.md).

---

## 9. Middleware Patterns

### When to Use Middleware

| Signal | Recommendation |
|--------|---------------|
| 5+ external systems | Middleware -- centralize routing |
| Complex data transformations | Middleware -- offload from Salesforce |
| High-volume real-time sync | Middleware -- buffer and throttle |
| Simple point-to-point, low volume | Direct callout with Named Credential |

### Common Platforms

| Platform | Strength |
|----------|----------|
| MuleSoft Anypoint | Salesforce-native, pre-built connectors |
| Informatica Cloud | Data integration, MDM |
| Dell Boomi | Multi-cloud, EDI |
| Workato | Low-code recipes |
| Apache Kafka | High-throughput event streaming (via Pub/Sub API) |

### Architecture Pattern

```
Outbound: Salesforce Platform Event --> Pub/Sub API --> Middleware --> External System
Inbound:  External System --> Middleware --> Salesforce REST API (via Connected App)
```

Keep business logic in Salesforce. Middleware handles routing, retry, circuit breaking, and transformation.

---

## 10. Event-Driven Architecture Decision Guide

### Choosing the Right Mechanism

```
Need to react to record changes?
  --> Yes: Change Data Capture (CDC)
  --> No: Need decoupled pub/sub?
      --> Yes: Platform Events
      --> No: Direct callout or Flow HTTP action
```

### Comparison

| Dimension | Platform Events | CDC | Outbound Messages |
|-----------|----------------|-----|-------------------|
| Trigger | Explicit publish | Automatic on DML | Workflow Rule criteria |
| Schema | Custom fields | Mirrors SObject | Selected fields |
| Direction | Pub/sub (any) | Subscribe only | Outbound SOAP |
| Retry | 8x subscriber retry | 8x subscriber retry | 24h with backoff |
| Retention | 24h (std) / 72h (HV) | 72h | Until acknowledged |
| Volume limit | 150K/hr (HV) | Edition-based | N/A |

### Combining Patterns

- **CDC + Platform Events**: CDC captures changes; Platform Events notify across boundaries
- **Platform Events + Middleware**: Events decouple Salesforce; middleware routes externally
- **Named Credentials + External Services**: auth + auto-generated Flow actions
- **Connected App + Named Credential**: OAuth client definition + outbound callout credential
