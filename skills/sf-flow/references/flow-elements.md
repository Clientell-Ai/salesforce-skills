# Flow Elements Reference (Metadata XML Format)

Complete reference for all Salesforce Flow elements with valid Flow metadata XML examples.

---

## 1. Assignment Element

Set variable values, add to collections, perform arithmetic.

```xml
<assignments>
    <name>Set_Account_Variables</name>
    <label>Set Account Variables</label>
    <locationX>314</locationX>
    <locationY>278</locationY>
    <assignmentItems>
        <!-- Set a simple variable -->
        <assignToReference>varAccountName</assignToReference>
        <operator>Assign</operator>
        <value>
            <stringValue>Default Account</stringValue>
        </value>
    </assignmentItems>
    <assignmentItems>
        <!-- Add to a number variable -->
        <assignToReference>varTotalAmount</assignToReference>
        <operator>Add</operator>
        <value>
            <numberValue>100.0</numberValue>
        </value>
    </assignmentItems>
    <assignmentItems>
        <!-- Assign from a record field -->
        <assignToReference>varOwnerEmail</assignToReference>
        <operator>Assign</operator>
        <value>
            <elementReference>Get_Account.Owner.Email</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>
```

### Collection Addition

```xml
<assignments>
    <name>Add_To_Collection</name>
    <label>Add To Collection</label>
    <locationX>314</locationX>
    <locationY>398</locationY>
    <assignmentItems>
        <!-- Add a single record to a collection variable -->
        <assignToReference>colAccounts</assignToReference>
        <operator>Add</operator>
        <value>
            <elementReference>varCurrentAccount</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>
```

---

## 2. Decision Element

Branch logic with conditions, outcomes, and a default outcome.

```xml
<decisions>
    <name>Check_Account_Rating</name>
    <label>Check Account Rating</label>
    <locationX>578</locationX>
    <locationY>278</locationY>
    <defaultConnector>
        <targetReference>Handle_Default</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
    <rules>
        <name>Is_Hot</name>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>$Record.Rating</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <stringValue>Hot</stringValue>
            </rightValue>
        </conditions>
        <conditions>
            <leftValueReference>$Record.AnnualRevenue</leftValueReference>
            <operator>GreaterThan</operator>
            <rightValue>
                <numberValue>1000000.0</numberValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Handle_Hot_Account</targetReference>
        </connector>
        <label>Is Hot</label>
    </rules>
    <rules>
        <name>Is_Warm</name>
        <conditionLogic>or</conditionLogic>
        <conditions>
            <leftValueReference>$Record.Rating</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <stringValue>Warm</stringValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Handle_Warm_Account</targetReference>
        </connector>
        <label>Is Warm</label>
    </rules>
</decisions>
```

### Custom Condition Logic

```xml
<rules>
    <name>Complex_Logic</name>
    <!-- Custom logic: (1 AND 2) OR 3 -->
    <conditionLogic>(1 AND 2) OR 3</conditionLogic>
    <conditions>
        <leftValueReference>$Record.Industry</leftValueReference>
        <operator>EqualTo</operator>
        <rightValue>
            <stringValue>Technology</stringValue>
        </rightValue>
    </conditions>
    <conditions>
        <leftValueReference>$Record.AnnualRevenue</leftValueReference>
        <operator>GreaterThan</operator>
        <rightValue>
            <numberValue>500000.0</numberValue>
        </rightValue>
    </conditions>
    <conditions>
        <leftValueReference>$Record.Rating</leftValueReference>
        <operator>EqualTo</operator>
        <rightValue>
            <stringValue>Hot</stringValue>
        </rightValue>
    </conditions>
    <connector>
        <targetReference>Handle_Match</targetReference>
    </connector>
    <label>Complex Match</label>
</rules>
```

---

## 3. Loop Element

Iterate over a collection, processing one item at a time.

```xml
<loops>
    <name>Loop_Through_Contacts</name>
    <label>Loop Through Contacts</label>
    <locationX>578</locationX>
    <locationY>518</locationY>
    <collectionReference>Get_Contacts</collectionReference>
    <iterationOrder>Asc</iterationOrder>
    <nextValueConnector>
        <targetReference>Update_Contact_Fields</targetReference>
    </nextValueConnector>
    <noMoreValuesConnector>
        <targetReference>Update_All_Contacts</targetReference>
    </noMoreValuesConnector>
</loops>
```

The loop variable is automatically available as `Loop_Through_Contacts` (the element's API name) inside the loop body. Access fields with `Loop_Through_Contacts.FieldName`.

---

## 4. Get Records

Query records with filters, sorting, and field selection.

```xml
<recordLookups>
    <name>Get_Related_Contacts</name>
    <label>Get Related Contacts</label>
    <locationX>314</locationX>
    <locationY>518</locationY>
    <assignNullValuesIfNoRecordsFound>true</assignNullValuesIfNoRecordsFound>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Handle_Error</targetReference>
    </faultConnector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>AccountId</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </filters>
    <filters>
        <field>Email</field>
        <operator>IsNull</operator>
        <value>
            <booleanValue>false</booleanValue>
        </value>
    </filters>
    <getFirstRecordOnly>false</getFirstRecordOnly>
    <object>Contact</object>
    <sortField>LastName</sortField>
    <sortOrder>Asc</sortOrder>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordLookups>
```

### Get First Record Only (Storing Specific Fields)

```xml
<recordLookups>
    <name>Get_Account_Owner</name>
    <label>Get Account Owner</label>
    <locationX>314</locationX>
    <locationY>398</locationY>
    <assignNullValuesIfNoRecordsFound>true</assignNullValuesIfNoRecordsFound>
    <connector>
        <targetReference>Decision_Element</targetReference>
    </connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Id</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>$Record.OwnerId</elementReference>
        </value>
    </filters>
    <getFirstRecordOnly>true</getFirstRecordOnly>
    <object>User</object>
    <queriedFields>Id</queriedFields>
    <queriedFields>Email</queriedFields>
    <queriedFields>ManagerId</queriedFields>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordLookups>
```

---

## 5. Create Records

Insert new records with field value mappings.

### Single Record

```xml
<recordCreates>
    <name>Create_Task</name>
    <label>Create Task</label>
    <locationX>578</locationX>
    <locationY>638</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Handle_Error</targetReference>
    </faultConnector>
    <inputAssignments>
        <field>Subject</field>
        <value>
            <stringValue>Follow Up</stringValue>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>WhoId</field>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Status</field>
        <value>
            <stringValue>Not Started</stringValue>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>ActivityDate</field>
        <value>
            <elementReference>$Flow.CurrentDate</elementReference>
        </value>
    </inputAssignments>
    <object>Task</object>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordCreates>
```

### Multiple Records (from Collection Variable)

```xml
<recordCreates>
    <name>Create_Multiple_Tasks</name>
    <label>Create Multiple Tasks</label>
    <locationX>578</locationX>
    <locationY>758</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Handle_Error</targetReference>
    </faultConnector>
    <inputReference>colTasksToCreate</inputReference>
</recordCreates>
```

---

## 6. Update Records

Update records by filter criteria or from a record/collection variable.

### Update by Filter Criteria

```xml
<recordUpdates>
    <name>Update_Related_Opportunities</name>
    <label>Update Related Opportunities</label>
    <locationX>578</locationX>
    <locationY>878</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Handle_Error</targetReference>
    </faultConnector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>AccountId</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </filters>
    <filters>
        <field>StageName</field>
        <operator>EqualTo</operator>
        <value>
            <stringValue>Prospecting</stringValue>
        </value>
    </filters>
    <inputAssignments>
        <field>Description</field>
        <value>
            <stringValue>Account rating changed to Hot</stringValue>
        </value>
    </inputAssignments>
    <object>Opportunity</object>
</recordUpdates>
```

### Update from a Collection Variable

```xml
<recordUpdates>
    <name>Update_Contacts_Collection</name>
    <label>Update Contacts Collection</label>
    <locationX>578</locationX>
    <locationY>998</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <inputReference>colContactsToUpdate</inputReference>
</recordUpdates>
```

---

## 7. Delete Records

Delete records matching filter criteria.

```xml
<recordDeletes>
    <name>Delete_Old_Tasks</name>
    <label>Delete Old Tasks</label>
    <locationX>578</locationX>
    <locationY>1118</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Handle_Error</targetReference>
    </faultConnector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>WhoId</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </filters>
    <filters>
        <field>Status</field>
        <operator>EqualTo</operator>
        <value>
            <stringValue>Completed</stringValue>
        </value>
    </filters>
    <object>Task</object>
</recordDeletes>
```

### Delete from a Collection Variable

```xml
<recordDeletes>
    <name>Delete_Records_Collection</name>
    <label>Delete Records Collection</label>
    <locationX>578</locationX>
    <locationY>1238</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <inputReference>colRecordsToDelete</inputReference>
</recordDeletes>
```

---

## 8. Screen Element

Build interactive UI screens with input components, validation, and conditional visibility.

```xml
<screens>
    <name>Input_Screen</name>
    <label>Input Screen</label>
    <locationX>314</locationX>
    <locationY>158</locationY>
    <allowBack>true</allowBack>
    <allowFinish>true</allowFinish>
    <allowPause>false</allowPause>
    <connector>
        <targetReference>Process_Input</targetReference>
    </connector>
    <showFooter>true</showFooter>
    <showHeader>true</showHeader>
    <fields>
        <name>Display_Text</name>
        <fieldText>&lt;p&gt;Please enter the account details below.&lt;/p&gt;</fieldText>
        <fieldType>DisplayText</fieldType>
    </fields>
    <fields>
        <name>Account_Name_Input</name>
        <dataType>String</dataType>
        <fieldText>Account Name</fieldText>
        <fieldType>InputField</fieldType>
        <isRequired>true</isRequired>
    </fields>
    <fields>
        <name>Annual_Revenue_Input</name>
        <dataType>Currency</dataType>
        <fieldText>Annual Revenue</fieldText>
        <fieldType>InputField</fieldType>
        <isRequired>false</isRequired>
        <scale>2</scale>
    </fields>
    <fields>
        <name>Industry_Picklist</name>
        <choiceReferences>Industry_Choices</choiceReferences>
        <dataType>String</dataType>
        <fieldText>Industry</fieldText>
        <fieldType>DropdownBox</fieldType>
        <isRequired>true</isRequired>
    </fields>
    <fields>
        <name>Is_Priority</name>
        <dataType>Boolean</dataType>
        <fieldText>Is Priority Account?</fieldText>
        <fieldType>InputField</fieldType>
    </fields>
    <!-- Conditional visibility -->
    <fields>
        <name>Priority_Reason</name>
        <dataType>String</dataType>
        <fieldText>Priority Reason</fieldText>
        <fieldType>LargeTextArea</fieldType>
        <visibilityRule>
            <conditionLogic>and</conditionLogic>
            <conditions>
                <leftValueReference>Is_Priority</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>
                    <booleanValue>true</booleanValue>
                </rightValue>
            </conditions>
        </visibilityRule>
    </fields>
    <!-- Input validation -->
    <fields>
        <name>Email_Input</name>
        <dataType>String</dataType>
        <fieldText>Email Address</fieldText>
        <fieldType>InputField</fieldType>
        <validationRule>
            <errorMessage>Please enter a valid email address.</errorMessage>
            <formulaExpression>REGEX({!Email_Input}, &quot;[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}&quot;)</formulaExpression>
        </validationRule>
    </fields>
</screens>
```

---

## 9. Action Element

Call Apex invocable actions, standard actions, or quick actions.

### Apex Invocable Action

```xml
<actionCalls>
    <name>Call_Apex_Action</name>
    <label>Call Apex Action</label>
    <locationX>578</locationX>
    <locationY>1358</locationY>
    <actionName>MyInvocableClass</actionName>
    <actionType>apex</actionType>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Handle_Error</targetReference>
    </faultConnector>
    <inputParameters>
        <name>accountId</name>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </inputParameters>
    <inputParameters>
        <name>newRating</name>
        <value>
            <stringValue>Hot</stringValue>
        </value>
    </inputParameters>
    <outputParameters>
        <assignToReference>varResult</assignToReference>
        <name>outputMessage</name>
    </outputParameters>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</actionCalls>
```

### Send Email Action

```xml
<actionCalls>
    <name>Send_Email_Alert</name>
    <label>Send Email Alert</label>
    <locationX>578</locationX>
    <locationY>1478</locationY>
    <actionName>emailSimple</actionName>
    <actionType>emailSimple</actionType>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <inputParameters>
        <name>emailAddresses</name>
        <value>
            <elementReference>$Record.Owner.Email</elementReference>
        </value>
    </inputParameters>
    <inputParameters>
        <name>emailSubject</name>
        <value>
            <stringValue>Account Rating Changed</stringValue>
        </value>
    </inputParameters>
    <inputParameters>
        <name>emailBody</name>
        <value>
            <elementReference>varEmailBody</elementReference>
        </value>
    </inputParameters>
</actionCalls>
```

### Submit for Approval Action

```xml
<actionCalls>
    <name>Submit_For_Approval</name>
    <label>Submit For Approval</label>
    <locationX>578</locationX>
    <locationY>1598</locationY>
    <actionName>submit</actionName>
    <actionType>submit</actionType>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <inputParameters>
        <name>objectId</name>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </inputParameters>
    <inputParameters>
        <name>comment</name>
        <value>
            <stringValue>Auto-submitted by flow</stringValue>
        </value>
    </inputParameters>
</actionCalls>
```

---

## 10. Subflow Element

Call another flow, passing input and output variables.

```xml
<subflows>
    <name>Call_Notification_Flow</name>
    <label>Call Notification Flow</label>
    <locationX>578</locationX>
    <locationY>1718</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <flowName>Send_Notification_Subflow</flowName>
    <inputAssignments>
        <name>inputRecordId</name>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <name>inputNotificationType</name>
        <value>
            <stringValue>AccountUpdate</stringValue>
        </value>
    </inputAssignments>
    <outputAssignments>
        <assignToReference>varNotificationResult</assignToReference>
        <name>outputSuccess</name>
    </outputAssignments>
</subflows>
```

---

## 11. Wait Element

Pause flow execution until time-based or event-based conditions are met.

### Time-Based Wait

```xml
<waits>
    <name>Wait_For_Follow_Up</name>
    <label>Wait For Follow Up</label>
    <locationX>578</locationX>
    <locationY>1838</locationY>
    <defaultConnector>
        <targetReference>Timeout_Handler</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>Default (Timeout)</defaultConnectorLabel>
    <waitEvents>
        <name>Three_Days_Later</name>
        <conditionLogic>and</conditionLogic>
        <connector>
            <targetReference>Send_Follow_Up_Email</targetReference>
        </connector>
        <eventType>AlarmEvent</eventType>
        <inputParameters>
            <name>AlarmTime</name>
            <value>
                <elementReference>varFollowUpDateTime</elementReference>
            </value>
        </inputParameters>
        <inputParameters>
            <name>TimeOffset</name>
            <value>
                <numberValue>72</numberValue>
            </value>
        </inputParameters>
        <inputParameters>
            <name>TimeOffsetUnit</name>
            <value>
                <stringValue>Hours</stringValue>
            </value>
        </inputParameters>
        <label>Three Days Later</label>
    </waitEvents>
</waits>
```

### Event-Based Wait (Platform Event)

```xml
<waits>
    <name>Wait_For_Approval_Event</name>
    <label>Wait For Approval Event</label>
    <locationX>578</locationX>
    <locationY>1958</locationY>
    <defaultConnector>
        <targetReference>Timeout_Handler</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>Default</defaultConnectorLabel>
    <waitEvents>
        <name>Approval_Received</name>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>Approval_Received.Record_Id__c</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <elementReference>$Record.Id</elementReference>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Process_Approval</targetReference>
        </connector>
        <eventType>Approval_Event__e</eventType>
        <label>Approval Received</label>
    </waitEvents>
</waits>
```

---

## 12. Stage Element

Define stages for guided visual processes (Screen Flows).

```xml
<stages>
    <name>Stage_Account_Info</name>
    <label>Account Information</label>
    <isActive>true</isActive>
    <stageOrder>1</stageOrder>
</stages>
<stages>
    <name>Stage_Contact_Info</name>
    <label>Contact Information</label>
    <isActive>true</isActive>
    <stageOrder>2</stageOrder>
</stages>
<stages>
    <name>Stage_Review</name>
    <label>Review &amp; Submit</label>
    <isActive>true</isActive>
    <stageOrder>3</stageOrder>
</stages>
```

Set the current stage via assignment:

```xml
<assignments>
    <name>Set_Stage_To_Contact</name>
    <label>Set Stage To Contact Info</label>
    <locationX>314</locationX>
    <locationY>518</locationY>
    <assignmentItems>
        <assignToReference>$Flow.CurrentStage</assignToReference>
        <operator>Assign</operator>
        <value>
            <elementReference>Stage_Contact_Info</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Contact_Screen</targetReference>
    </connector>
</assignments>
```

---

## 13. Connector Syntax

Connectors define the flow's execution path between elements.

### Standard Connector

```xml
<connector>
    <targetReference>Next_Element_Name</targetReference>
</connector>
```

### Default Connector (on Decision/Wait)

```xml
<defaultConnector>
    <targetReference>Default_Path_Element</targetReference>
</defaultConnector>
<defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
```

### Fault Connector

```xml
<faultConnector>
    <targetReference>Error_Handler_Element</targetReference>
</faultConnector>
```

### Next Value Connector (on Loop)

```xml
<nextValueConnector>
    <targetReference>Process_Current_Item</targetReference>
</nextValueConnector>
```

### No More Values Connector (on Loop)

```xml
<noMoreValuesConnector>
    <targetReference>After_Loop_Element</targetReference>
</noMoreValuesConnector>
```

### Schedule Connector (on Start element for scheduled flows)

```xml
<scheduledPaths>
    <name>Run_Immediately</name>
    <connector>
        <targetReference>First_Element</targetReference>
    </connector>
    <label>Run Immediately</label>
    <offsetNumber>0</offsetNumber>
    <offsetUnit>Hours</offsetUnit>
    <timeSource>RecordTriggerEvent</timeSource>
</scheduledPaths>
```

---

## 14. Platform Event-Triggered Flow

Complete XML for a flow triggered by a Platform Event.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>59.0</apiVersion>
    <description>Processes incoming Order Events and creates tasks</description>
    <interviewLabel>Order Event Handler {!$Flow.CurrentDateTime}</interviewLabel>
    <label>Order Event Handler</label>
    <processType>AutoLaunchedFlow</processType>
    <status>Active</status>

    <!-- Start element for Platform Event trigger -->
    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Check_Event_Status</targetReference>
        </connector>
        <object>Order_Event__e</object>
        <triggerType>PlatformEvent</triggerType>
    </start>

    <decisions>
        <name>Check_Event_Status</name>
        <label>Check Event Status</label>
        <locationX>314</locationX>
        <locationY>158</locationY>
        <defaultConnector>
            <targetReference>Log_Other_Status</targetReference>
        </defaultConnector>
        <defaultConnectorLabel>Other Status</defaultConnectorLabel>
        <rules>
            <name>Is_Shipped</name>
            <conditionLogic>and</conditionLogic>
            <conditions>
                <!-- Access event payload fields via $Record -->
                <leftValueReference>$Record.Status__c</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>
                    <stringValue>Shipped</stringValue>
                </rightValue>
            </conditions>
            <connector>
                <targetReference>Create_Shipping_Task</targetReference>
            </connector>
            <label>Is Shipped</label>
        </rules>
    </decisions>

    <recordCreates>
        <name>Create_Shipping_Task</name>
        <label>Create Shipping Task</label>
        <locationX>314</locationX>
        <locationY>398</locationY>
        <inputAssignments>
            <field>Subject</field>
            <value>
                <elementReference>$Record.Order_Id__c</elementReference>
            </value>
        </inputAssignments>
        <inputAssignments>
            <field>Status</field>
            <value>
                <stringValue>Not Started</stringValue>
            </value>
        </inputAssignments>
        <object>Task</object>
        <storeOutputAutomatically>true</storeOutputAutomatically>
    </recordCreates>

    <assignments>
        <name>Log_Other_Status</name>
        <label>Log Other Status</label>
        <locationX>578</locationX>
        <locationY>398</locationY>
        <assignmentItems>
            <assignToReference>varLogMessage</assignToReference>
            <operator>Assign</operator>
            <value>
                <elementReference>$Record.Status__c</elementReference>
            </value>
        </assignmentItems>
    </assignments>

    <variables>
        <name>varLogMessage</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>false</isOutput>
    </variables>
</Flow>
```

---

## 15. Scheduled Flow

Complete XML with schedule/frequency configuration.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>59.0</apiVersion>
    <description>Weekly cleanup of stale leads</description>
    <interviewLabel>Stale Lead Cleanup {!$Flow.CurrentDateTime}</interviewLabel>
    <label>Stale Lead Cleanup</label>
    <processType>AutoLaunchedFlow</processType>
    <status>Active</status>

    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Update_Stale_Lead</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Status</field>
            <operator>EqualTo</operator>
            <value>
                <stringValue>Open - Not Contacted</stringValue>
            </value>
        </filters>
        <filters>
            <field>LastModifiedDate</field>
            <operator>LessThan</operator>
            <value>
                <elementReference>$Flow.CurrentDateTime</elementReference>
            </value>
        </filters>
        <object>Lead</object>
        <schedule>
            <frequency>Weekly</frequency>
            <startDate>2024-01-07</startDate>
            <startTime>02:00:00.000Z</startTime>
        </schedule>
        <scheduledPaths>
            <connector>
                <targetReference>Update_Stale_Lead</targetReference>
            </connector>
            <pathType>AsyncAfterCommit</pathType>
        </scheduledPaths>
        <triggerType>Scheduled</triggerType>
    </start>

    <recordUpdates>
        <name>Update_Stale_Lead</name>
        <label>Update Stale Lead</label>
        <locationX>314</locationX>
        <locationY>158</locationY>
        <inputAssignments>
            <field>Status</field>
            <value>
                <stringValue>Closed - Not Converted</stringValue>
            </value>
        </inputAssignments>
        <inputAssignments>
            <field>Description</field>
            <value>
                <stringValue>Auto-closed by scheduled flow due to inactivity.</stringValue>
            </value>
        </inputAssignments>
        <inputReference>$Record</inputReference>
    </recordUpdates>
</Flow>
```

---

## 16. Orchestration Flow

Step definitions and stage dependencies in an orchestration.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>59.0</apiVersion>
    <label>Customer Onboarding Orchestration</label>
    <processType>Orchestrator</processType>
    <status>Active</status>

    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Stage_Data_Collection</targetReference>
        </connector>
    </start>

    <!-- Orchestration Stage -->
    <orchestratedStages>
        <name>Stage_Data_Collection</name>
        <label>Data Collection</label>
        <locationX>314</locationX>
        <locationY>158</locationY>
        <connector>
            <targetReference>Stage_Approval</targetReference>
        </connector>
        <stageSteps>
            <name>Step_Collect_Info</name>
            <actionName>Collect_Customer_Info_Screen_Flow</actionName>
            <actionType>stepInteractive</actionType>
            <assignees>
                <assignee>
                    <elementReference>$Record.OwnerId</elementReference>
                </assignee>
                <assigneeType>User</assigneeType>
            </assignees>
            <inputParameters>
                <name>recordId</name>
                <value>
                    <elementReference>$Record.Id</elementReference>
                </value>
            </inputParameters>
        </stageSteps>
    </orchestratedStages>

    <!-- Dependent Stage -->
    <orchestratedStages>
        <name>Stage_Approval</name>
        <label>Manager Approval</label>
        <locationX>578</locationX>
        <locationY>158</locationY>
        <connector>
            <targetReference>Stage_Provisioning</targetReference>
        </connector>
        <stageSteps>
            <name>Step_Manager_Review</name>
            <actionName>Manager_Approval_Screen_Flow</actionName>
            <actionType>stepInteractive</actionType>
            <assignees>
                <assignee>
                    <elementReference>$Record.Owner.ManagerId</elementReference>
                </assignee>
                <assigneeType>User</assigneeType>
            </assignees>
            <entryConditions>
                <leftValueReference>$Record.AnnualRevenue</leftValueReference>
                <operator>GreaterThan</operator>
                <rightValue>
                    <numberValue>100000.0</numberValue>
                </rightValue>
            </entryConditions>
        </stageSteps>
    </orchestratedStages>

    <!-- Background Step Stage -->
    <orchestratedStages>
        <name>Stage_Provisioning</name>
        <label>Provisioning</label>
        <locationX>842</locationX>
        <locationY>158</locationY>
        <stageSteps>
            <name>Step_Provision_Account</name>
            <actionName>Provision_Account_Autolaunched_Flow</actionName>
            <actionType>stepBackground</actionType>
        </stageSteps>
    </orchestratedStages>
</Flow>
```

---

## 17. Screen Flow with Dynamic Choices

Query-based choice set for dynamic picklist values.

```xml
<!-- Dynamic Choice Set from SOQL -->
<dynamicChoiceSets>
    <name>Account_Choices</name>
    <dataType>String</dataType>
    <displayField>Name</displayField>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Industry</field>
        <operator>EqualTo</operator>
        <value>
            <stringValue>Technology</stringValue>
        </value>
    </filters>
    <filters>
        <field>IsActive__c</field>
        <operator>EqualTo</operator>
        <value>
            <booleanValue>true</booleanValue>
        </value>
    </filters>
    <object>Account</object>
    <outputAssignments>
        <assignToReference>varSelectedAccountId</assignToReference>
        <field>Id</field>
    </outputAssignments>
    <sortField>Name</sortField>
    <sortOrder>Asc</sortOrder>
    <valueField>Id</valueField>
</dynamicChoiceSets>

<!-- Screen using the dynamic choice set -->
<screens>
    <name>Select_Account_Screen</name>
    <label>Select Account</label>
    <locationX>314</locationX>
    <locationY>158</locationY>
    <allowFinish>true</allowFinish>
    <connector>
        <targetReference>Process_Selection</targetReference>
    </connector>
    <showFooter>true</showFooter>
    <showHeader>true</showHeader>
    <fields>
        <name>Account_Dropdown</name>
        <choiceReferences>Account_Choices</choiceReferences>
        <dataType>String</dataType>
        <fieldText>Select an Account</fieldText>
        <fieldType>DropdownBox</fieldType>
        <isRequired>true</isRequired>
    </fields>
</screens>

<!-- Static choice definition for comparison -->
<choices>
    <name>Choice_High</name>
    <choiceText>High Priority</choiceText>
    <dataType>String</dataType>
    <value>
        <stringValue>High</stringValue>
    </value>
</choices>
<choices>
    <name>Choice_Medium</name>
    <choiceText>Medium Priority</choiceText>
    <dataType>String</dataType>
    <value>
        <stringValue>Medium</stringValue>
    </value>
</choices>
<choices>
    <name>Choice_Low</name>
    <choiceText>Low Priority</choiceText>
    <dataType>String</dataType>
    <value>
        <stringValue>Low</stringValue>
    </value>
</choices>
```

---

## 18. Collection Variable Operations

Add, remove, and filter collections in assignment elements.

```xml
<!-- Define collection variables -->
<variables>
    <name>colAccounts</name>
    <dataType>SObject</dataType>
    <isCollection>true</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <objectType>Account</objectType>
</variables>
<variables>
    <name>colFilteredAccounts</name>
    <dataType>SObject</dataType>
    <isCollection>true</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <objectType>Account</objectType>
</variables>
<variables>
    <name>varCurrentAccount</name>
    <dataType>SObject</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <objectType>Account</objectType>
</variables>

<!-- Add a record to a collection -->
<assignments>
    <name>Add_Account_To_Collection</name>
    <label>Add Account To Collection</label>
    <locationX>314</locationX>
    <locationY>278</locationY>
    <assignmentItems>
        <assignToReference>colAccounts</assignToReference>
        <operator>Add</operator>
        <value>
            <elementReference>varCurrentAccount</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>

<!-- Remove first matching item from collection -->
<assignments>
    <name>Remove_From_Collection</name>
    <label>Remove From Collection</label>
    <locationX>314</locationX>
    <locationY>398</locationY>
    <assignmentItems>
        <assignToReference>colAccounts</assignToReference>
        <operator>RemoveFirst</operator>
        <value>
            <elementReference>varCurrentAccount</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>

<!-- Remove all occurrences -->
<assignments>
    <name>Remove_All_From_Collection</name>
    <label>Remove All Matches</label>
    <locationX>314</locationX>
    <locationY>518</locationY>
    <assignmentItems>
        <assignToReference>colAccounts</assignToReference>
        <operator>RemoveAll</operator>
        <value>
            <elementReference>varCurrentAccount</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>

<!-- Remove all items (clear collection) by reassigning empty collection -->
<assignments>
    <name>Clear_Collection</name>
    <label>Clear Collection</label>
    <locationX>314</locationX>
    <locationY>638</locationY>
    <assignmentItems>
        <assignToReference>colAccounts</assignToReference>
        <operator>RemoveAll</operator>
        <value>
            <elementReference>colAccounts</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>

<!-- Collection Filter element (Spring '23+) -->
<collectionProcessors>
    <name>Filter_Hot_Accounts</name>
    <label>Filter Hot Accounts</label>
    <locationX>578</locationX>
    <locationY>278</locationY>
    <collectionProcessorType>FilterCollectionProcessor</collectionProcessorType>
    <collectionReference>colAccounts</collectionReference>
    <conditionLogic>and</conditionLogic>
    <conditions>
        <leftValueReference>colAccounts.Rating</leftValueReference>
        <operator>EqualTo</operator>
        <rightValue>
            <stringValue>Hot</stringValue>
        </rightValue>
    </conditions>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <outputReference>colFilteredAccounts</outputReference>
</collectionProcessors>
```

---

## 19. Formula Element

Inline formula calculations used as flow resources.

```xml
<formulas>
    <name>frmDaysUntilClose</name>
    <dataType>Number</dataType>
    <expression>{!$Record.CloseDate} - {!$Flow.CurrentDate}</expression>
    <scale>0</scale>
</formulas>

<formulas>
    <name>frmFullName</name>
    <dataType>String</dataType>
    <expression>{!$Record.FirstName} &amp; &quot; &quot; &amp; {!$Record.LastName}</expression>
</formulas>

<formulas>
    <name>frmIsOverdue</name>
    <dataType>Boolean</dataType>
    <expression>{!$Record.CloseDate} &lt; TODAY()</expression>
</formulas>

<formulas>
    <name>frmDiscountedPrice</name>
    <dataType>Currency</dataType>
    <expression>IF(
    {!$Record.AnnualRevenue} &gt; 1000000,
    {!varListPrice} * 0.80,
    IF(
        {!$Record.AnnualRevenue} &gt; 500000,
        {!varListPrice} * 0.90,
        {!varListPrice}
    )
)</expression>
    <scale>2</scale>
</formulas>

<formulas>
    <name>frmQuarterEnd</name>
    <dataType>Date</dataType>
    <expression>DATE(
    YEAR(TODAY()),
    CEILING(MONTH(TODAY()) / 3) * 3 + 1,
    1
) - 1</expression>
</formulas>
```

---

## 20. Fault Connector Pattern

Handle errors gracefully using `$Flow.FaultMessage` and `$Flow.InterviewGuid` for error logging.

```xml
<!-- DML operation with fault connector -->
<recordCreates>
    <name>Create_Account</name>
    <label>Create Account</label>
    <locationX>314</locationX>
    <locationY>158</locationY>
    <connector>
        <targetReference>Success_Path</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Log_Error</targetReference>
    </faultConnector>
    <inputAssignments>
        <field>Name</field>
        <value>
            <elementReference>varAccountName</elementReference>
        </value>
    </inputAssignments>
    <object>Account</object>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordCreates>

<!-- Error logging element using $Flow.FaultMessage -->
<recordCreates>
    <name>Log_Error</name>
    <label>Log Error</label>
    <locationX>578</locationX>
    <locationY>158</locationY>
    <connector>
        <targetReference>Error_Screen</targetReference>
    </connector>
    <inputAssignments>
        <field>Error_Message__c</field>
        <value>
            <elementReference>$Flow.FaultMessage</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Flow_Interview_Id__c</field>
        <value>
            <elementReference>$Flow.InterviewGuid</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Flow_Name__c</field>
        <value>
            <stringValue>Account_Creation_Flow</stringValue>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Record_Id__c</field>
        <value>
            <elementReference>$Record.Id</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Timestamp__c</field>
        <value>
            <elementReference>$Flow.CurrentDateTime</elementReference>
        </value>
    </inputAssignments>
    <object>Flow_Error_Log__c</object>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordCreates>

<!-- Error screen for screen flows -->
<screens>
    <name>Error_Screen</name>
    <label>Error</label>
    <locationX>842</locationX>
    <locationY>158</locationY>
    <allowFinish>true</allowFinish>
    <showFooter>true</showFooter>
    <showHeader>true</showHeader>
    <fields>
        <name>Error_Display</name>
        <fieldText>&lt;p&gt;&lt;b&gt;An error occurred:&lt;/b&gt;&lt;/p&gt;
&lt;p&gt;{!$Flow.FaultMessage}&lt;/p&gt;
&lt;p&gt;Reference ID: {!$Flow.InterviewGuid}&lt;/p&gt;
&lt;p&gt;Please contact your administrator with the reference ID above.&lt;/p&gt;</fieldText>
        <fieldType>DisplayText</fieldType>
    </fields>
</screens>
```

### Complete Fault Handling Strategy

```xml
<!-- Retry pattern: Set a counter and retry the DML -->
<variables>
    <name>varRetryCount</name>
    <dataType>Number</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <scale>0</scale>
    <value>
        <numberValue>0</numberValue>
    </value>
</variables>

<variables>
    <name>varErrorOccurred</name>
    <dataType>Boolean</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <value>
        <booleanValue>false</booleanValue>
    </value>
</variables>

<!-- In fault handler, set error flag -->
<assignments>
    <name>Set_Error_Flag</name>
    <label>Set Error Flag</label>
    <locationX>578</locationX>
    <locationY>278</locationY>
    <assignmentItems>
        <assignToReference>varErrorOccurred</assignToReference>
        <operator>Assign</operator>
        <value>
            <booleanValue>true</booleanValue>
        </value>
    </assignmentItems>
    <assignmentItems>
        <assignToReference>varRetryCount</assignToReference>
        <operator>Add</operator>
        <value>
            <numberValue>1</numberValue>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Log_Error</targetReference>
    </connector>
</assignments>
```
