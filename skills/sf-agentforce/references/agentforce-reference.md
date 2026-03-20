# Agentforce Reference

Comprehensive reference for Agentforce agent development. All examples target API version 66.0.

---

## Agent Metadata Templates

### Complete .agent-meta.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Bot xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Customer_Service_Agent</fullName>
    <masterLabel>Customer Service Agent</masterLabel>
    <description>Autonomous agent for handling customer service inquiries</description>
    <type>Bot</type>
    <botVersions>
        <botVersion>
            <fullName>v1</fullName>
            <number>1</number>
            <status>Active</status>
        </botVersion>
    </botVersions>
    <contextVariables>
        <contextVariable>
            <name>ContactId</name>
            <dataType>Text</dataType>
        </contextVariable>
    </contextVariables>
</Bot>
```

### Topic Definition XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiTopic xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Order Management</masterLabel>
    <developerName>Order_Management</developerName>
    <description>Handles order status checks, shipment tracking, and delivery estimates</description>
    <scope>
        <inScope>Order status lookups, shipment tracking, delivery estimates</inScope>
        <outOfScope>New order placement, returns, refunds, account management</outOfScope>
    </scope>
    <instructions>
        <instruction>Ask for the order number before lookup</instruction>
        <instruction>Use Order_Lookup to retrieve order details</instruction>
        <instruction>Provide tracking info for shipped orders</instruction>
        <instruction>Escalate if customer is dissatisfied after two attempts</instruction>
    </instructions>
    <actions>
        <action>Order_Lookup</action>
        <action>Shipment_Tracking</action>
    </actions>
</GenAiTopic>
```

---

## Action Configuration Examples

### Flow Action

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiFunction xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Order Lookup</masterLabel>
    <developerName>Order_Lookup</developerName>
    <description>Retrieves order details by order number</description>
    <capabilityDescription>Use when the customer asks about order status or delivery</capabilityDescription>
    <targetType>Flow</targetType>
    <targetName>Order_Lookup_Flow</targetName>
    <inputs>
        <input>
            <name>orderNumber</name>
            <description>The order number (e.g., ORD-12345)</description>
            <dataType>String</dataType>
            <required>true</required>
        </input>
    </inputs>
    <outputs>
        <output>
            <name>orderStatus</name>
            <description>Current order status</description>
            <dataType>String</dataType>
        </output>
        <output>
            <name>estimatedDelivery</name>
            <description>Estimated delivery date</description>
            <dataType>String</dataType>
        </output>
    </outputs>
</GenAiFunction>
```

### Apex Action

```xml
<GenAiFunction xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Calculate Refund</masterLabel>
    <developerName>Calculate_Refund</developerName>
    <capabilityDescription>Use when the customer requests a refund</capabilityDescription>
    <targetType>Apex</targetType>
    <targetName>RefundCalculator</targetName>
    <inputs>
        <input><name>orderId</name><dataType>String</dataType><required>true</required></input>
        <input><name>returnReason</name><dataType>String</dataType><required>true</required></input>
    </inputs>
    <outputs>
        <output><name>refundAmount</name><dataType>Number</dataType></output>
        <output><name>eligible</name><dataType>Boolean</dataType></output>
    </outputs>
</GenAiFunction>
```

The Apex target must use `@InvocableMethod` with `@InvocableVariable` fields matching the input/output names exactly.

### PromptTemplate Action

```xml
<GenAiFunction xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Draft Response Email</masterLabel>
    <developerName>Draft_Response_Email</developerName>
    <capabilityDescription>Use to compose email responses to customers</capabilityDescription>
    <targetType>PromptTemplate</targetType>
    <targetName>Customer_Response_Email_Template</targetName>
    <inputs>
        <input><name>caseId</name><dataType>String</dataType><required>true</required></input>
        <input><name>resolution</name><dataType>String</dataType><required>true</required></input>
    </inputs>
    <outputs>
        <output><name>emailBody</name><dataType>String</dataType></output>
    </outputs>
</GenAiFunction>
```

---

## PromptTemplate Metadata

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PromptTemplate xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Customer Response Email Template</masterLabel>
    <developerName>Customer_Response_Email_Template</developerName>
    <templateType>einstein_gpt__flex</templateType>
    <status>Active</status>
    <promptVersions>
        <promptVersion>
            <versionNumber>1</versionNumber>
            <isActive>true</isActive>
            <messageList>
                <message>
                    <role>System</role>
                    <content>You are a professional customer service representative.
                        Write an empathetic, clear response email.</content>
                </message>
                <message>
                    <role>User</role>
                    <content>Case: {!caseId} Resolution: {!resolution}
                        Write a customer response email.</content>
                </message>
            </messageList>
            <inputVariables>
                <variable><name>caseId</name><dataType>String</dataType></variable>
                <variable><name>resolution</name><dataType>String</dataType></variable>
            </inputVariables>
            <outputVariable>
                <name>emailBody</name><dataType>String</dataType>
            </outputVariable>
        </promptVersion>
    </promptVersions>
</PromptTemplate>
```

Rules: Status must be `Active` (Draft causes publish errors). Input names must match GenAiFunction inputs. Use `{!variableName}` merge fields.

---

## Agent Script DSL Syntax Reference

### Block Order

```yaml
config:         # Agent identity and type
variables:      # Agent-level variables
system:         # System prompt and greeting
connection:     # Channel config (optional)
knowledge:      # Knowledge base (optional)
language:       # Language settings (optional)
start_agent:    # Entry point (exactly one)
topic:          # One or more topic definitions
```

### Config Block

```yaml
config:
  developer_name: Order_Service_Agent
  master_label: Order Service Agent
  agent_description: Handles order inquiries with deterministic routing
  agent_type: AgentforceServiceAgent
  default_agent_user: agent_user@company.com
```

- `developer_name` must match the folder/bundle name
- Use `agent_description` (not `description`)
- `default_agent_user`: required for Service Agents, forbidden for Employee Agents

### Variables

```yaml
variables:
  orderNumber:
    type: string
    description: Customer order number
  verified:
    type: boolean
    default: False
  lookupResult:
    type: string
    linked: True
```

Types: `string`, `boolean`, `number`, `date`, `datetime`. Linked variables cannot have defaults or use `object`/`list` types.

### States, Transitions, and Guards

```yaml
topic: VerifyCustomer
  description: Verifies customer identity
  instructions: ->
    Ask for email. Verify identity. Route accordingly.
  actions:
    verify:
      target: flow://Verify_Customer_Identity
      inputs:
        email: $input
      outputs:
        isVerified: verified
  transitions:
    - when: verified == True
      go_to: OrderService
    - when: verified == False
      go_to: VerificationFailed

topic: OrderModification
  description: Handles order modifications
  available when: verified == True
```

### Target Prefixes

- `flow://` — Flow
- `apex://` — Apex InvocableMethod
- `prompt://` — PromptTemplate

### Deterministic vs LLM-Directed

| Mechanism | Behavior |
|---|---|
| `set`, `transition to`, `run @actions.X` | Deterministic (always executes) |
| `{!@actions.X}` in instructions | LLM-directed (model decides) |
| `@utils.transition` | LLM-directed utility |

---

## Testing Spec YAML Format

```yaml
apiVersion: "66.0"
agentApiName: Order_Service_Agent
testCases:
  - name: Order Status - Happy Path
    turns:
      - utterance: "I need to check on my order"
        expectedTopic: Greeting
      - utterance: "Order ORD-98765"
        expectedTopic: Order_Management
        expectedActions: [Order_Lookup]
        expectedOutputContains: ["ORD-98765"]
  - name: Off Topic
    turns:
      - utterance: "Can you help me write a poem?"
        expectedBehavior: "Agent declines and redirects"
        expectedTopic: null
  - name: Escalation
    turns:
      - utterance: "I want to speak to a human"
        expectedEscalation: true
  - name: Phrasing Variation
    turns:
      - utterance: "Where is my package?"
        expectedTopic: Order_Management
      - utterance: "Track my shipment"
        expectedTopic: Order_Management
```

```bash
sf agent test run --spec-dir tests/agent-specs/ -o TARGET_ORG --json
sf agent test run --spec-file tests/order-status.yaml -o TARGET_ORG --json --verbose
sf agent test results --test-run-id 0Atxx0000000001 -o TARGET_ORG --json
```

---

## Advanced Testing Patterns

### Multi-Turn Test Specs

Multi-turn specs validate context preservation across turns. Each turn can assert `expectedTopic`, `expectedActions`, `expectedOutputContains` (substring match), and `expectedOutputExcludes` (negative assertion to prevent data leaks).

### Test Coverage Metrics

Track five dimensions: **topic coverage** (% tested), **action coverage** (% invoked), **guardrail coverage** (harmful/off-topic inputs), **escalation coverage** (paths exercised), **phrasing variation** (3+ phrasings per top topic). Target 100% topic and action coverage.

### Additional CLI Commands

```bash
sf agent test list -o TARGET_ORG --json
```

---

## Observability & Monitoring

### STDM Trace Analysis

The Session Tracing Data Model (STDM) stores telemetry in Data Cloud. Entity hierarchy: `Session > Interaction > InteractionStep > Moment > Message`. Enable in **Setup > Einstein AI > Session Tracing**.

### Session Transcript Queries

```sql
SELECT SessionId, InteractionId, StepType, TopicName,
       ActionName, StartTime, EndTime, Status
FROM AgentforceInteractionStep
WHERE SessionId = '<session-id>'
ORDER BY StartTime ASC
```

### EventLogFile for Agent Events

```soql
SELECT Id, EventType, LogDate, LogFileLength
FROM EventLogFile
WHERE EventType = 'AIInteraction' AND LogDate >= LAST_N_DAYS:7
ORDER BY LogDate DESC
```

Download via `/sobjects/EventLogFile/<id>/LogFileBody`. Parse CSV for invocation counts, error rates, and p95 latency.

### Parquet Export

Export STDM to Parquet via Data Cloud Query API for offline analysis. Use Polars for lazy evaluation on large datasets. Common patterns: session duration distribution, topic routing accuracy, action failure rates, escalation trends.

---

## Persona Configuration

### System Instruction Template

```text
Identity: You are [Agent Name], a [role] for [Company].
Register: [Formal / Professional / Friendly-casual]
Tone: [Warm and empathetic / Neutral and efficient]
Rules:
- Use the customer's name when available
- Keep responses under 3 sentences for simple queries
- Never promise specific timelines or outcomes
```

### Voice Attributes

| Attribute | Range | Example |
|---|---|---|
| Register | Formal → Casual | Professional (3/5) |
| Warmth | Neutral → Empathetic | Warm (4/5) |
| Brevity | Verbose → Terse | Concise (4/5) |
| Humor | None → Light | Minimal (1/5) |

### Brand Voice Encoding

1. Extract brand adjectives (e.g., "trustworthy, innovative")
2. Map to behavioral rules ("trustworthy" → "cite data, never speculate")
3. Create a **phrase book** (preferred expressions) and **never-say list** (banned terms)
4. Encode into `system:` block (Agent Script) or agent description (Agent Builder)

### Persona Guardrails

- After two failed resolutions, shift to maximum empathy and offer human handoff
- Never provide medical, legal, or financial advice — redirect to qualified resources
- Never repeat back full SSN, credit card, or account numbers

---

## Models API

Setup: **Setup > Einstein AI > Model Management**. Configure default model and per-template overrides.

```apex
public with sharing class AgentModelService {
    @InvocableMethod(label='Generate AI Content')
    public static List<GenerateResult> generate(List<GenerateRequest> requests) {
        List<GenerateResult> results = new List<GenerateResult>();
        for (GenerateRequest req : requests) {
            try {
                ConnectApi.EinsteinLlmGenerateParams params = new ConnectApi.EinsteinLlmGenerateParams();
                params.promptTextorId = req.prompt;
                ConnectApi.EinsteinLlmGenerationOutput output = ConnectApi.EinsteinAI.generateMessages(params);
                results.add(new GenerateResult(output.generatedMessages[0].text, true, null));
            } catch (Exception e) {
                results.add(new GenerateResult(null, false, e.getMessage()));
            }
        }
        return results;
    }

    public class GenerateRequest {
        @InvocableVariable(required=true) public String prompt;
    }

    public class GenerateResult {
        @InvocableVariable public String generatedText;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
        public GenerateResult(String text, Boolean ok, String err) {
            this.generatedText = text; this.success = ok; this.errorMessage = err;
        }
    }
}
```

All Models API calls go through Einstein Trust Layer automatically.

---

## Agent User Setup

1. **Create user**: Setup > Users > New User. License: `Salesforce Integration`.
2. **Assign permset**: `sf org assign permset -n AgentforceServiceAgent -o TARGET_ORG`
3. **Grant access**: Create a permission set with CRUD on required objects/fields.
4. **Configure**: Set `default_agent_user` in agent config.

| Issue | Fix |
|---|---|
| Actions fail silently | Grant object/field access to agent user |
| Agent non-functional after publish | Assign AgentforceServiceAgent permset |
| SOQL returns no results | Check sharing rules and role hierarchy |

---

## Common Agent Patterns

**Service Agent**: Customer-facing, `AgentforceServiceAgent`, dedicated agent user. Topics: greeting, order management, returns, escalation. Always verify identity early; always have an escalation path.

**Sales Agent**: Internal, `AgentforceEmployeeAgent`, runs as logged-in user. Topics: lead qualification, opportunity analysis, meeting prep, next-best-action. Heavy use of PromptTemplate actions. Prefer read-only actions.

**Knowledge Agent**: Internal, `AgentforceEmployeeAgent`. Topics: knowledge search, article recommendations, FAQ, process guidance. Bind knowledge base. Include article links in responses.

---

## Einstein Trust Layer

| Protection | Description |
|---|---|
| Prompt Defense | Blocks prompt injection attempts |
| Toxicity Detection | Filters harmful content |
| PII Masking | Redacts sensitive data before sending to model |
| Data Grounding | Anchors responses to CRM data |
| Audit Trail | Logs all LLM interactions |
| Zero Data Retention | Customer data not used for training |

Enabled by default. Configure in **Setup > Einstein AI > Trust Layer**.

---

## Debugging Agent Responses

### Approaches

1. **Agent Preview** (Setup > Agentforce > Agents > Preview): test utterances, observe routing and actions
2. **Event Logs**: Trust Layer events, action execution logs, session data
3. **CLI**: `sf agent list`, `sf project retrieve start -m "Bot,GenAiFunction,GenAiPlugin,GenAiTopic"`
4. **Validation**: `sf agent validate authoring-bundle --api-name MyAgent -o TARGET_ORG --json`

### Debugging Checklist

| Symptom | Check |
|---|---|
| No response | Published AND activated? |
| Wrong topic | Overlapping descriptions? Review scope. |
| Action not invoked | Attached to topic? Capability description clear? |
| Null inputs | Parameter names match target contract? |
| Runtime failure | Agent user has permissions? |
| Empty PromptTemplate output | Template Active? Merge fields correct? |
| Topic loop | Transitions defined? Exit conditions present? |
| Preview vs runtime mismatch | Check linked variables and context passing |
