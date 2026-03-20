# Diagram Reference: Templates, Examples & Syntax

Reusable templates and patterns for generating Salesforce architecture diagrams in Mermaid and ASCII.

---

## ERD Templates

### Standard Sales Cloud Data Model

```mermaid
erDiagram
    Account ||--o{ Contact : "has"
    Account ||--o{ Opportunity : "has"
    Account ||--o{ Case : "has"
    Contact ||--o{ Case : "opened by"
    Opportunity ||--|{ OpportunityLineItem : "contains"
    Opportunity ||--o{ OpportunityContactRole : "involves"
    Contact ||--o{ OpportunityContactRole : "plays role"
    Opportunity }o--|| Pricebook2 : "uses"
    Product2 ||--|{ PricebookEntry : "listed in"
    OpportunityLineItem }o--|| PricebookEntry : "references"
    Lead ||--o| Account : "converts to"
    Lead ||--o| Contact : "converts to"

    Account {
        Id Id PK
        string Name
        string Industry
    }
    Contact {
        Id Id PK
        Id AccountId FK
        string LastName
        string Email
    }
    Opportunity {
        Id Id PK
        Id AccountId FK
        string StageName
        currency Amount
    }
    Case {
        Id Id PK
        Id AccountId FK
        Id ContactId FK
        string Status
    }
```

### Custom Object Junction Pattern

```mermaid
erDiagram
    Project__c ||--|{ Project_Member__c : "has members"
    Contact ||--|{ Project_Member__c : "assigned to"
    Project_Member__c {
        Id Project__c FK "Master-Detail"
        Id Contact__c FK "Master-Detail"
        picklist Role__c
    }
```

---

## Class Diagram Templates

### Trigger Handler Pattern

```mermaid
classDiagram
    class TriggerHandler {
        <<abstract>>
        +run() void
        +beforeInsert() void
        +afterUpdate() void
    }
    class AccountTriggerHandler {
        +beforeInsert() void
        -validateIndustry(List~Account~) void
    }
    TriggerHandler <|-- AccountTriggerHandler : extends
    AccountTriggerHandler --> AccountService : delegates to
```

### Service-Selector-Domain Pattern

```mermaid
classDiagram
    class AccountService {
        +getAccountsByIds(Set~Id~) List~Account~
        +mergeAccounts(Id, List~Id~) MergeResult
    }
    class AccountSelector {
        +selectById(Set~Id~) List~Account~
        +selectWithContacts(Set~Id~) List~Account~
    }
    class Accounts {
        <<domain>>
        -records List~Account~
        +validateIndustry() void
        +setDefaultRating() void
    }
    AccountService --> AccountSelector : queries via
    AccountService --> Accounts : operates on
```

---

## Sequence Diagram Templates

### REST Callout with Error Handling

```mermaid
sequenceDiagram
    autonumber
    participant Ctrl as ApexController
    participant Svc as IntegrationService
    participant Ext as External REST API
    Ctrl->>Svc: callExternalAPI(recordIds)
    Svc->>Ext: POST /api/v2/accounts
    alt Success (200)
        Ext-->>Svc: 200 OK {data}
        Svc-->>Ctrl: IntegrationResult(success)
    else Error (4xx/5xx)
        Ext-->>Svc: Error {message}
        Svc->>Svc: Log to Integration_Log__c
        Svc-->>Ctrl: IntegrationResult(failure)
    end
```

### Platform Event Pub/Sub

```mermaid
sequenceDiagram
    autonumber
    participant Apex as Publisher
    participant Bus as Event Bus
    participant Sub1 as Trigger
    participant Sub2 as Flow
    Apex->>Bus: EventBus.publish(events)
    Note over Bus: 72h retention
    par Subscribers
        Bus-->>Sub1: Deliver (new transaction)
        Bus-->>Sub2: Deliver
    end
    Note over Sub1: Retry via EventBus.RetryableException
```

---

## Flow-to-Mermaid Conversion Rules

### XML Element Mapping

| Flow XML Tag | Mermaid Shape | Syntax |
|-------------|--------------|--------|
| `<start>` | Start node | `([Start])` |
| `<screens>` | Screen | `[/Screen Name/]` |
| `<decisions>` | Decision | `{Decision?}` |
| `<assignments>` | Assignment | `[Set Variables]` |
| `<recordLookups>` | Query | `[(Get Records)]` |
| `<recordCreates>` | DML | `[[Create Record]]` |
| `<recordUpdates>` | DML | `[[Update Record]]` |
| `<recordDeletes>` | DML | `[[Delete Record]]` |
| `<loops>` | Loop | `{For Each Item}` |
| `<actionCalls>` | Action | `(Invoke Action)` |
| `<subflows>` | Subflow | `[[Run Subflow]]` |
| `<waits>` | Wait | `{{Wait for Event}}` |

### Connector Mapping

| Flow Connector | Mermaid Syntax |
|---------------|---------------|
| `<connector>` | `A --> B` |
| `<defaultConnector>` | `A -->\|Default\| B` |
| `<faultConnector>` | `A -.->\|Fault\| B` |
| `<nextValueConnector>` | `A -->\|Next Item\| B` |
| `<noMoreValuesConnector>` | `A -->\|Done\| B` |

### Conversion Example

```mermaid
flowchart TD
    Start([Start]) --> Get_Account[(Get Account)]
    Get_Account --> Check_Status{Status = Active?}
    Check_Status -->|Is Active| Update_Rating[[Update Rating]]
    Check_Status -->|Default| Send_Alert(Send Alert Email)
    Update_Rating --> End([End])
    Send_Alert --> End
```

---

## Deployment Dependency Graph Template

```mermaid
flowchart LR
    subgraph Schema
        CO[Objects] --> CF[Fields]
    end
    subgraph Code
        Cls[Apex Classes] --> Trg[Triggers]
    end
    subgraph UI
        LWC --> FP[FlexiPages]
    end
    subgraph Config
        Fl[Flows]
        PS[Permission Sets]
    end
    CO --> Cls
    Cls --> LWC
    CO --> Fl
    CO --> PS
```

---

## Mermaid Syntax Cheat Sheet

### erDiagram Relationships

```
    A ||--|| B    One to one (exact)
    A ||--o{ B    One to many (Lookup)
    A ||--|{ B    One to many (Master-Detail)
    A }o--o{ B    Many to many (via junction)
    A }o--|| B    Many to one (optional)
```

### classDiagram Relationships

```
    A <|-- B      Inheritance (extends)
    A <|.. B      Implementation (implements)
    A *-- B       Composition (strong ownership)
    A o-- B       Aggregation (weak ownership)
    A --> B       Association (uses)
    A ..> B       Dependency (depends on)
```

### Styling Nodes

```
classDef standard fill:#1b96ff,stroke:#0176d3,color:#fff
classDef custom fill:#06a59a,stroke:#04877a,color:#fff
classDef external fill:#ff6b6b,stroke:#d63d3d,color:#fff
```

### Transaction Boundary — use `rect` blocks in sequence diagrams:

```
rect rgb(240, 248, 255)
    Note over A,C: Transaction 1
end
rect rgb(255, 240, 240)
    Note over D,E: Async context
end
```

---

## ASCII Fallback Templates

### ERD (ASCII)

```text
+-------------+  1:N  +-------------+  N:1  +------------------+
|   Account   |------>|   Contact   |------>|   Opportunity    |
+-------------+       +-------------+       +------------------+
| Id (PK)     |       | AccountId   |       | AccountId (FK)   |
| Name        |       | LastName    |       | StageName        |
| Industry    |       | Email       |       | Amount           |
+-------------+       +-------------+       +------------------+
```

### Sequence (ASCII)

```text
  LWC           Controller     Service        External API
   |               |              |               |
   |--callApex---->|              |               |
   |               |--process---->|               |
   |               |              |--HTTP POST--->|
   |               |              |<--200 OK------|
   |               |<--result-----|               |
   |<--response----|              |               |
```

### Class Hierarchy (ASCII)

```text
  TriggerHandler (abstract)
  +-- AccountTriggerHandler --> AccountService --> AccountSelector
  +-- OpportunityTriggerHandler --> OpportunityService
  +-- CaseTriggerHandler --> CaseService
```

---

## Tips

- Start simple, drill down on request
- Use real Salesforce API names, not display labels
- Annotate governor limits (SOQL/DML counts) and async boundaries
- Label relationships with verbs: "has", "belongs to", "references"
- Test rendering in GitHub markdown or Mermaid live editor
- Max 30 entities per ERD, 100 nodes per diagram; split by domain
- Colors: blue for standard, green for custom, red for external
