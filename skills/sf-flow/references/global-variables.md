# Salesforce Flow Global Variables Reference

Complete reference for all global variables available in Salesforce Flows, with accessible fields and usage examples.

---

## $Record

The triggering record in record-triggered flows. Contains all fields of the triggering SObject.

**Available in:** Record-Triggered Flows, Platform Event-Triggered Flows

**Access pattern:** `$Record.FieldName`

### All Standard Fields (varies by object)

| Field | Description |
|-------|-------------|
| `$Record.Id` | Record ID |
| `$Record.Name` | Record name |
| `$Record.OwnerId` | Owner ID |
| `$Record.CreatedById` | Creator user ID |
| `$Record.CreatedDate` | Creation timestamp |
| `$Record.LastModifiedById` | Last modifier user ID |
| `$Record.LastModifiedDate` | Last modification timestamp |
| `$Record.RecordTypeId` | Record type ID |
| `$Record.IsDeleted` | Soft delete flag |

### Traversing Relationships

Access parent fields via dot notation (up to 5 levels):

```
$Record.Account.Name
$Record.Account.Owner.Email
$Record.Account.Owner.Manager.Name
$Record.CreatedBy.Profile.Name
```

### Usage in Flow XML

```xml
<conditions>
    <leftValueReference>$Record.Status</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue>
        <stringValue>Closed Won</stringValue>
    </rightValue>
</conditions>
```

---

## $Record__Prior

The previous values of the triggering record before the update. Only available in **before-update** and **after-update** record-triggered flows.

**Available in:** Record-Triggered Flows (Update context only)

**Access pattern:** `$Record__Prior.FieldName`

### Field Change Detection Patterns

Compare current and prior values to detect specific field changes:

```xml
<!-- Detect Stage change -->
<conditions>
    <leftValueReference>$Record.StageName</leftValueReference>
    <operator>NotEqualTo</operator>
    <rightValue>
        <elementReference>$Record__Prior.StageName</elementReference>
    </rightValue>
</conditions>
```

```xml
<!-- Detect change TO a specific value -->
<rules>
    <name>Stage_Changed_To_Closed_Won</name>
    <conditionLogic>and</conditionLogic>
    <conditions>
        <leftValueReference>$Record.StageName</leftValueReference>
        <operator>EqualTo</operator>
        <rightValue>
            <stringValue>Closed Won</stringValue>
        </rightValue>
    </conditions>
    <conditions>
        <leftValueReference>$Record__Prior.StageName</leftValueReference>
        <operator>NotEqualTo</operator>
        <rightValue>
            <stringValue>Closed Won</stringValue>
        </rightValue>
    </conditions>
    <connector>
        <targetReference>Handle_Closed_Won</targetReference>
    </connector>
    <label>Stage Changed To Closed Won</label>
</rules>
```

```xml
<!-- Detect Owner change -->
<conditions>
    <leftValueReference>$Record.OwnerId</leftValueReference>
    <operator>NotEqualTo</operator>
    <rightValue>
        <elementReference>$Record__Prior.OwnerId</elementReference>
    </rightValue>
</conditions>
```

```xml
<!-- Detect value increase (e.g., Amount increased) -->
<conditions>
    <leftValueReference>$Record.Amount</leftValueReference>
    <operator>GreaterThan</operator>
    <rightValue>
        <elementReference>$Record__Prior.Amount</elementReference>
    </rightValue>
</conditions>
```

### Use in Entry Conditions (Start Element)

```xml
<start>
    <locationX>50</locationX>
    <locationY>0</locationY>
    <connector>
        <targetReference>First_Element</targetReference>
    </connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>StageName</field>
        <operator>EqualTo</operator>
        <value>
            <stringValue>Closed Won</stringValue>
        </value>
    </filters>
    <filters>
        <field>StageName</field>
        <operator>IsChanged</operator>
        <value>
            <booleanValue>true</booleanValue>
        </value>
    </filters>
    <object>Opportunity</object>
    <recordTriggerType>Update</recordTriggerType>
    <triggerType>RecordAfterSave</triggerType>
</start>
```

---

## $Api

Session and endpoint information for the current API context.

**Available in:** All flow types

| Field | Type | Description |
|-------|------|-------------|
| `$Api.Session_ID` | String | Current session ID. Returns null in flows run without a session (scheduled, platform event). |
| `$Api.Enterprise_Server_URL` | String | Enterprise SOAP API endpoint URL for the org. |
| `$Api.Partner_Server_URL` | String | Partner SOAP API endpoint URL for the org. |

### Usage Example

```xml
<!-- Pass session ID to an external callout via Apex action -->
<actionCalls>
    <name>Call_External_Service</name>
    <label>Call External Service</label>
    <actionName>ExternalServiceAction</actionName>
    <actionType>apex</actionType>
    <inputParameters>
        <name>sessionId</name>
        <value>
            <elementReference>$Api.Session_ID</elementReference>
        </value>
    </inputParameters>
    <inputParameters>
        <name>serverUrl</name>
        <value>
            <elementReference>$Api.Partner_Server_URL</elementReference>
        </value>
    </inputParameters>
</actionCalls>
```

---

## $Organization

Information about the current Salesforce org.

**Available in:** All flow types

| Field | Type | Description |
|-------|------|-------------|
| `$Organization.Id` | String | Organization ID (18-character) |
| `$Organization.Name` | String | Organization name |
| `$Organization.City` | String | City from company info |
| `$Organization.State` | String | State/Province |
| `$Organization.Country` | String | Country |
| `$Organization.PostalCode` | String | Postal/ZIP code |
| `$Organization.Street` | String | Street address |
| `$Organization.Phone` | String | Main phone number |
| `$Organization.Fax` | String | Fax number |
| `$Organization.DefaultLocaleSidKey` | String | Default locale (e.g., `en_US`) |
| `$Organization.LanguageLocaleKey` | String | Default language |
| `$Organization.TimeZoneSidKey` | String | Default time zone |
| `$Organization.UiSkin` | String | UI theme |
| `$Organization.InstanceName` | String | Instance (e.g., `NA135`, `CS42`) |
| `$Organization.IsSandbox` | Boolean | True if org is a sandbox |
| `$Organization.TrialExpirationDate` | Date | Trial expiration (null if not trial) |

### Usage Example

```xml
<!-- Branch logic based on sandbox vs production -->
<decisions>
    <name>Check_Environment</name>
    <label>Check Environment</label>
    <defaultConnector>
        <targetReference>Production_Logic</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>Production</defaultConnectorLabel>
    <rules>
        <name>Is_Sandbox</name>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>$Organization.IsSandbox</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <booleanValue>true</booleanValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Sandbox_Logic</targetReference>
        </connector>
        <label>Is Sandbox</label>
    </rules>
</decisions>
```

---

## $Profile

Current running user's profile information.

**Available in:** All flow types

| Field | Type | Description |
|-------|------|-------------|
| `$Profile.Id` | String | Profile ID |
| `$Profile.Name` | String | Profile name (e.g., `System Administrator`, `Standard User`) |

### Usage Example

```xml
<!-- Restrict action to System Administrators -->
<conditions>
    <leftValueReference>$Profile.Name</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue>
        <stringValue>System Administrator</stringValue>
    </rightValue>
</conditions>
```

---

## $User

Current running user's information.

**Available in:** All flow types

| Field | Type | Description |
|-------|------|-------------|
| `$User.Id` | String | User ID |
| `$User.FirstName` | String | First name |
| `$User.LastName` | String | Last name |
| `$User.Email` | String | Email address |
| `$User.Username` | String | Username (email format) |
| `$User.ProfileId` | String | Profile ID |
| `$User.UserRoleId` | String | Role ID |
| `$User.ManagerId` | String | Manager's user ID |
| `$User.Title` | String | Title |
| `$User.CompanyName` | String | Company name |
| `$User.Department` | String | Department |
| `$User.Division` | String | Division |
| `$User.Phone` | String | Phone number |
| `$User.MobilePhone` | String | Mobile phone |
| `$User.Alias` | String | Alias |
| `$User.CommunityNickname` | String | Community nickname |
| `$User.IsActive` | Boolean | Active flag |
| `$User.TimeZoneSidKey` | String | User time zone |
| `$User.LocaleSidKey` | String | User locale |
| `$User.LanguageLocaleKey` | String | User language |
| `$User.DefaultCurrency` | String | User default currency (multi-currency orgs) |
| `$User.ContactId` | String | Contact ID (community users) |
| `$User.AccountId` | String | Account ID (community users) |
| `$User.SmallPhotoUrl` | String | Small profile photo URL |
| `$User.FullPhotoUrl` | String | Full profile photo URL |

### Usage Examples

```xml
<!-- Assign task to current user's manager -->
<inputAssignments>
    <field>OwnerId</field>
    <value>
        <elementReference>$User.ManagerId</elementReference>
    </value>
</inputAssignments>
```

```xml
<!-- Send notification to the running user -->
<inputParameters>
    <name>emailAddresses</name>
    <value>
        <elementReference>$User.Email</elementReference>
    </value>
</inputParameters>
```

```xml
<!-- Check if running user is a community user -->
<conditions>
    <leftValueReference>$User.ContactId</leftValueReference>
    <operator>IsNull</operator>
    <rightValue>
        <booleanValue>false</booleanValue>
    </rightValue>
</conditions>
```

---

## $Flow

Flow execution context information.

**Available in:** All flow types

| Field | Type | Description |
|-------|------|-------------|
| `$Flow.CurrentDateTime` | DateTime | Current date and time at the moment of evaluation |
| `$Flow.CurrentDate` | Date | Current date (no time component) |
| `$Flow.CurrentStage` | String | Active stage in a staged flow (Screen Flow with stages) |
| `$Flow.ActiveStages` | Collection | Collection of active stage names |
| `$Flow.FaultMessage` | String | Error message when a fault connector is followed. Only populated in fault paths. |
| `$Flow.InterviewGuid` | String | Unique identifier for the current flow interview (execution instance) |

### Usage Examples

```xml
<!-- Set a due date 7 days from now -->
<formulas>
    <name>frmDueDate</name>
    <dataType>Date</dataType>
    <expression>{!$Flow.CurrentDate} + 7</expression>
</formulas>
```

```xml
<!-- Use in fault connector for error logging -->
<inputAssignments>
    <field>Error_Message__c</field>
    <value>
        <elementReference>$Flow.FaultMessage</elementReference>
    </value>
</inputAssignments>
<inputAssignments>
    <field>Interview_GUID__c</field>
    <value>
        <elementReference>$Flow.InterviewGuid</elementReference>
    </value>
</inputAssignments>
```

```xml
<!-- Navigate between stages -->
<assignments>
    <name>Move_To_Review_Stage</name>
    <label>Move To Review Stage</label>
    <assignmentItems>
        <assignToReference>$Flow.CurrentStage</assignToReference>
        <operator>Assign</operator>
        <value>
            <elementReference>Stage_Review</elementReference>
        </value>
    </assignmentItems>
</assignments>
```

---

## $Permission

Check whether the running user has a specific Custom Permission.

**Available in:** All flow types

**Access pattern:** `$Permission.CustomPermissionApiName` (returns Boolean)

### Usage Example

```xml
<!-- Check if user has a custom permission -->
<conditions>
    <leftValueReference>$Permission.Can_Approve_Large_Deals</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue>
        <booleanValue>true</booleanValue>
    </rightValue>
</conditions>
```

```xml
<!-- Gate a screen flow section behind a permission -->
<fields>
    <name>Admin_Section</name>
    <fieldText>&lt;p&gt;Administrative Override Options&lt;/p&gt;</fieldText>
    <fieldType>DisplayText</fieldType>
    <visibilityRule>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>$Permission.Admin_Override_Access</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <booleanValue>true</booleanValue>
            </rightValue>
        </conditions>
    </visibilityRule>
</fields>
```

---

## $Label

Access Custom Labels by their API name. Returns the label value in the running user's language.

**Available in:** All flow types

**Access pattern:** `$Label.CustomLabelApiName` (returns String)

### Usage Example

```xml
<!-- Display a custom label in a screen -->
<fields>
    <name>Welcome_Message</name>
    <fieldText>{!$Label.Welcome_Message_Text}</fieldText>
    <fieldType>DisplayText</fieldType>
</fields>
```

```xml
<!-- Use custom label as email subject -->
<inputParameters>
    <name>emailSubject</name>
    <value>
        <elementReference>$Label.Notification_Email_Subject</elementReference>
    </value>
</inputParameters>
```

```xml
<!-- Use in a formula -->
<formulas>
    <name>frmLocalizedGreeting</name>
    <dataType>String</dataType>
    <expression>{!$Label.Greeting_Prefix} &amp; " " &amp; {!$User.FirstName}</expression>
</formulas>
```

---

## $Setup

Access Custom Metadata Type records and their field values.

**Available in:** All flow types

**Access pattern:** `$Setup.CustomMetadataTypeName__mdt.RecordDeveloperName.FieldName__c`

Note: This accesses Custom Metadata Type records without SOQL, and they do not count against query limits.

### Usage Examples

```xml
<!-- Read a configuration value from Custom Metadata -->
<conditions>
    <leftValueReference>$Setup.App_Config__mdt.Default.Is_Feature_Enabled__c</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue>
        <booleanValue>true</booleanValue>
    </rightValue>
</conditions>
```

```xml
<!-- Use Custom Metadata value in an assignment -->
<assignmentItems>
    <assignToReference>varMaxRetries</assignToReference>
    <operator>Assign</operator>
    <value>
        <elementReference>$Setup.Integration_Settings__mdt.Default.Max_Retries__c</elementReference>
    </value>
</assignmentItems>
```

```xml
<!-- Use in a formula -->
<formulas>
    <name>frmApiEndpoint</name>
    <dataType>String</dataType>
    <expression>{!$Setup.Integration_Settings__mdt.Default.Base_URL__c} &amp; "/api/v2/accounts"</expression>
</formulas>
```

---

## $System

System-level constants.

**Available in:** All flow types

| Field | Type | Description |
|-------|------|-------------|
| `$System.OriginDateTime` | DateTime | The literal value `1900-01-01 00:00:00`. Used as a baseline for date/time arithmetic. |

### Usage Example

```xml
<!-- Calculate minutes elapsed since a timestamp -->
<formulas>
    <name>frmMinutesElapsed</name>
    <dataType>Number</dataType>
    <expression>({!$Flow.CurrentDateTime} - {!$Record.CreatedDate}) * 24 * 60</expression>
    <scale>0</scale>
</formulas>

<!-- Use OriginDateTime as a sentinel/default value -->
<assignmentItems>
    <assignToReference>varLastProcessedDate</assignToReference>
    <operator>Assign</operator>
    <value>
        <elementReference>$System.OriginDateTime</elementReference>
    </value>
</assignmentItems>
```

---

## $ContentDocument

Access document information in document-triggered flows (ContentDocument or ContentVersion triggers).

**Available in:** Record-Triggered Flows on ContentDocument or ContentVersion

| Field | Type | Description |
|-------|------|-------------|
| `$Record.Title` | String | Document title |
| `$Record.FileType` | String | File extension (PDF, DOCX, etc.) |
| `$Record.ContentSize` | Number | File size in bytes |
| `$Record.OwnerId` | String | Owner of the document |
| `$Record.LatestPublishedVersionId` | String | Latest ContentVersion ID |
| `$Record.ParentId` | String | Parent record (when accessed via ContentDocumentLink) |

### Usage Example (ContentVersion-triggered flow)

```xml
<start>
    <locationX>50</locationX>
    <locationY>0</locationY>
    <connector>
        <targetReference>Check_File_Type</targetReference>
    </connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>FileType</field>
        <operator>EqualTo</operator>
        <value>
            <stringValue>PDF</stringValue>
        </value>
    </filters>
    <object>ContentVersion</object>
    <recordTriggerType>Create</recordTriggerType>
    <triggerType>RecordAfterSave</triggerType>
</start>

<decisions>
    <name>Check_File_Type</name>
    <label>Check File Type</label>
    <defaultConnector>
        <targetReference>Skip_Processing</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>Other Type</defaultConnectorLabel>
    <rules>
        <name>Is_PDF</name>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>$Record.FileType</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <stringValue>PDF</stringValue>
            </rightValue>
        </conditions>
        <conditions>
            <leftValueReference>$Record.ContentSize</leftValueReference>
            <operator>LessThan</operator>
            <rightValue>
                <numberValue>5242880</numberValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Process_PDF</targetReference>
        </connector>
        <label>Is PDF Under 5MB</label>
    </rules>
</decisions>
```

---

## Common Patterns and Recipes

### Pattern 1: Field Change Detection with Action

Detect when a specific field changes and perform an action only on that change:

```xml
<!-- Entry criteria: only run when Status changes -->
<start>
    <connector>
        <targetReference>Check_New_Status</targetReference>
    </connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Status__c</field>
        <operator>IsChanged</operator>
        <value>
            <booleanValue>true</booleanValue>
        </value>
    </filters>
    <object>Case</object>
    <recordTriggerType>Update</recordTriggerType>
    <triggerType>RecordAfterSave</triggerType>
</start>
```

### Pattern 2: Conditional Logic Based on User and Record

```xml
<decisions>
    <name>Can_User_Modify</name>
    <label>Can User Modify</label>
    <defaultConnector>
        <targetReference>Access_Denied_Screen</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>No Access</defaultConnectorLabel>
    <rules>
        <name>Is_Owner_Or_Admin</name>
        <conditionLogic>or</conditionLogic>
        <conditions>
            <leftValueReference>$Record.OwnerId</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <elementReference>$User.Id</elementReference>
            </rightValue>
        </conditions>
        <conditions>
            <leftValueReference>$Profile.Name</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <stringValue>System Administrator</stringValue>
            </rightValue>
        </conditions>
        <conditions>
            <leftValueReference>$Permission.Override_Record_Access</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <booleanValue>true</booleanValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Allow_Modification</targetReference>
        </connector>
        <label>Is Owner or Admin</label>
    </rules>
</decisions>
```

### Pattern 3: Environment-Aware Configuration

```xml
<!-- Use Custom Metadata for environment-specific config -->
<formulas>
    <name>frmApiUrl</name>
    <dataType>String</dataType>
    <expression>IF(
    {!$Organization.IsSandbox},
    {!$Setup.API_Config__mdt.Sandbox.Endpoint_URL__c},
    {!$Setup.API_Config__mdt.Production.Endpoint_URL__c}
)</expression>
</formulas>
```

### Pattern 4: Error Handling with Context

```xml
<!-- Comprehensive error logging with all context variables -->
<recordCreates>
    <name>Create_Error_Log</name>
    <label>Create Error Log</label>
    <inputAssignments>
        <field>Error_Message__c</field>
        <value>
            <elementReference>$Flow.FaultMessage</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Interview_Id__c</field>
        <value>
            <elementReference>$Flow.InterviewGuid</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Running_User__c</field>
        <value>
            <elementReference>$User.Id</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>User_Profile__c</field>
        <value>
            <elementReference>$Profile.Name</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Org_Id__c</field>
        <value>
            <elementReference>$Organization.Id</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Is_Sandbox__c</field>
        <value>
            <elementReference>$Organization.IsSandbox</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Timestamp__c</field>
        <value>
            <elementReference>$Flow.CurrentDateTime</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Record_Id__c</field>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </inputAssignments>
    <object>Flow_Error_Log__c</object>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordCreates>
```

### Pattern 5: Multi-Field Change Detection Formula

```xml
<!-- Formula to detect any of several fields changing -->
<formulas>
    <name>frmKeyFieldsChanged</name>
    <dataType>Boolean</dataType>
    <expression>OR(
    {!$Record.Amount} != {!$Record__Prior.Amount},
    {!$Record.StageName} != {!$Record__Prior.StageName},
    {!$Record.CloseDate} != {!$Record__Prior.CloseDate},
    {!$Record.OwnerId} != {!$Record__Prior.OwnerId}
)</expression>
</formulas>

<!-- Use the formula in a decision -->
<decisions>
    <name>Did_Key_Fields_Change</name>
    <label>Did Key Fields Change</label>
    <defaultConnector>
        <targetReference>Skip_Notification</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>No Changes</defaultConnectorLabel>
    <rules>
        <name>Key_Fields_Changed</name>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>frmKeyFieldsChanged</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <booleanValue>true</booleanValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Send_Change_Notification</targetReference>
        </connector>
        <label>Key Fields Changed</label>
    </rules>
</decisions>
```

### Pattern 6: Using $Label for Multi-Language Support

```xml
<!-- Screen with localized labels -->
<screens>
    <name>Localized_Screen</name>
    <label>Localized Screen</label>
    <fields>
        <name>Header_Text</name>
        <fieldText>{!$Label.Screen_Header}</fieldText>
        <fieldType>DisplayText</fieldType>
    </fields>
    <fields>
        <name>Name_Input</name>
        <dataType>String</dataType>
        <fieldText>{!$Label.Name_Field_Label}</fieldText>
        <fieldType>InputField</fieldType>
        <isRequired>true</isRequired>
        <validationRule>
            <errorMessage>{!$Label.Name_Required_Error}</errorMessage>
            <formulaExpression>LEN({!Name_Input}) &gt; 0</formulaExpression>
        </validationRule>
    </fields>
</screens>
```
