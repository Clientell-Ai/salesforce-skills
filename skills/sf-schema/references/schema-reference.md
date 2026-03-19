# Salesforce Schema Metadata XML Reference

## 1. Formula Field

### Text Formula
```xml
<fields>
    <fullName>Full_Name__c</fullName>
    <label>Full Name</label>
    <type>Text</type>
    <formula>FirstName &amp; " " &amp; LastName</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
    <externalId>false</externalId>
    <required>false</required>
</fields>
```

### Number Formula
```xml
<fields>
    <fullName>Discount_Amount__c</fullName>
    <label>Discount Amount</label>
    <type>Number</type>
    <precision>18</precision>
    <scale>2</scale>
    <formula>Amount__c * Discount_Percent__c / 100</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
</fields>
```

### Date Formula
```xml
<fields>
    <fullName>Renewal_Date__c</fullName>
    <label>Renewal Date</label>
    <type>Date</type>
    <formula>ADDMONTHS(Start_Date__c, Contract_Length__c)</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
</fields>
```

### Cross-Object Formula
```xml
<fields>
    <fullName>Account_Industry__c</fullName>
    <label>Account Industry</label>
    <type>Text</type>
    <formula>Account__r.Industry</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
</fields>
```

### CASE / IF / ISBLANK Functions
```xml
<fields>
    <fullName>Priority_Score__c</fullName>
    <label>Priority Score</label>
    <type>Number</type>
    <precision>3</precision>
    <scale>0</scale>
    <formula>
CASE(Priority,
    "High", 3,
    "Medium", 2,
    "Low", 1,
    0
)
+
IF(ISBLANK(Email), 0, 1)
    </formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
</fields>
```

---

## 2. Rollup Summary Field

### SUM Rollup
```xml
<fields>
    <fullName>Total_Amount__c</fullName>
    <label>Total Amount</label>
    <summarizedField>Opportunity.Amount</summarizedField>
    <summaryFilterItems>
        <field>Opportunity.StageName</field>
        <operation>notEqual</operation>
        <value>Closed Lost</value>
    </summaryFilterItems>
    <summaryForeignKey>Opportunity.AccountId</summaryForeignKey>
    <summaryOperation>sum</summaryOperation>
    <type>Summary</type>
</fields>
```

### COUNT Rollup
```xml
<fields>
    <fullName>Number_of_Contacts__c</fullName>
    <label>Number of Contacts</label>
    <summaryForeignKey>Contact.AccountId</summaryForeignKey>
    <summaryOperation>count</summaryOperation>
    <type>Summary</type>
</fields>
```

### MIN Rollup
```xml
<fields>
    <fullName>Earliest_Close_Date__c</fullName>
    <label>Earliest Close Date</label>
    <summarizedField>Opportunity.CloseDate</summarizedField>
    <summaryForeignKey>Opportunity.AccountId</summaryForeignKey>
    <summaryOperation>min</summaryOperation>
    <type>Summary</type>
</fields>
```

### MAX Rollup
```xml
<fields>
    <fullName>Largest_Deal__c</fullName>
    <label>Largest Deal</label>
    <summarizedField>Opportunity.Amount</summarizedField>
    <summaryForeignKey>Opportunity.AccountId</summaryForeignKey>
    <summaryOperation>max</summaryOperation>
    <type>Summary</type>
</fields>
```

---

## 3. Geolocation Field

```xml
<fields>
    <fullName>Location__c</fullName>
    <label>Location</label>
    <displayLocationInDecimal>true</displayLocationInDecimal>
    <scale>6</scale>
    <type>Location</type>
    <required>false</required>
</fields>
```

### Usage Notes
- Access latitude: `Location__Latitude__s`
- Access longitude: `Location__Longitude__s`
- Display formats: `Decimal` or `DegMinSec`
- Scale: number of decimal places (up to 15)
- SOQL distance function: `DISTANCE(Location__c, GEOLOCATION(lat, lng), 'mi')`

---

## 4. Global Value Set

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GlobalValueSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Industry Categories</masterLabel>
    <description>Standardized industry categories across objects</description>
    <sorted>true</sorted>
    <customValue>
        <fullName>Technology</fullName>
        <label>Technology</label>
        <default>false</default>
        <isActive>true</isActive>
    </customValue>
    <customValue>
        <fullName>Finance</fullName>
        <label>Finance</label>
        <default>false</default>
        <isActive>true</isActive>
    </customValue>
    <customValue>
        <fullName>Healthcare</fullName>
        <label>Healthcare</label>
        <default>false</default>
        <isActive>true</isActive>
    </customValue>
    <customValue>
        <fullName>Manufacturing</fullName>
        <label>Manufacturing</label>
        <default>false</default>
        <isActive>true</isActive>
    </customValue>
    <customValue>
        <fullName>Retail</fullName>
        <label>Retail</label>
        <default>false</default>
        <isActive>true</isActive>
    </customValue>
</GlobalValueSet>
```

### Referencing Global Value Set in a Field
```xml
<fields>
    <fullName>Industry_Category__c</fullName>
    <label>Industry Category</label>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetName>Industry_Categories</valueSetName>
    </valueSet>
</fields>
```

---

## 5. Record Type

```xml
<?xml version="1.0" encoding="UTF-8"?>
<RecordType xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Case.Support_Case</fullName>
    <label>Support Case</label>
    <active>true</active>
    <description>Record type for customer support cases</description>
    <businessProcess>Support Process</businessProcess>
    <compactLayoutAssignment>Support_Compact</compactLayoutAssignment>
    <picklistValues>
        <picklist>Status</picklist>
        <values>
            <fullName>New</fullName>
            <default>true</default>
        </values>
        <values>
            <fullName>Working</fullName>
            <default>false</default>
        </values>
        <values>
            <fullName>Escalated</fullName>
            <default>false</default>
        </values>
        <values>
            <fullName>Closed</fullName>
            <default>false</default>
        </values>
    </picklistValues>
</RecordType>
```

---

## 6. Page Layout

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Layout xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Account-Sales Layout</fullName>
    <layoutSections>
        <customLabel>true</customLabel>
        <detailHeading>true</detailHeading>
        <editHeading>true</editHeading>
        <label>Account Information</label>
        <style>TwoColumnsLeftToRight</style>
        <layoutColumns>
            <layoutItems>
                <behavior>Required</behavior>
                <field>Name</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Phone</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Industry</field>
            </layoutItems>
        </layoutColumns>
        <layoutColumns>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>OwnerId</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>AnnualRevenue</field>
            </layoutItems>
            <layoutItems>
                <behavior>Readonly</behavior>
                <field>Rating</field>
            </layoutItems>
        </layoutColumns>
    </layoutSections>
    <layoutSections>
        <customLabel>true</customLabel>
        <detailHeading>true</detailHeading>
        <editHeading>true</editHeading>
        <label>Address Information</label>
        <style>TwoColumnsLeftToRight</style>
        <layoutColumns>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>BillingAddress</field>
            </layoutItems>
        </layoutColumns>
        <layoutColumns>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>ShippingAddress</field>
            </layoutItems>
        </layoutColumns>
    </layoutSections>
    <relatedLists>
        <fields>FULL_NAME</fields>
        <fields>CONTACT.TITLE</fields>
        <fields>CONTACT.EMAIL</fields>
        <fields>CONTACT.PHONE1</fields>
        <relatedList>RelatedContactList</relatedList>
    </relatedLists>
    <relatedLists>
        <fields>OPPORTUNITY.NAME</fields>
        <fields>OPPORTUNITY.STAGE_NAME</fields>
        <fields>OPPORTUNITY.AMOUNT</fields>
        <fields>OPPORTUNITY.CLOSE_DATE</fields>
        <relatedList>RelatedOpportunityList</relatedList>
    </relatedLists>
    <miniLayout>
        <fields>Name</fields>
        <fields>Phone</fields>
        <fields>Industry</fields>
        <relatedLists>
            <relatedList>RelatedContactList</relatedList>
        </relatedLists>
    </miniLayout>
</Layout>
```

---

## 7. Compact Layout

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CompactLayout xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Account.Sales_Compact</fullName>
    <label>Sales Compact Layout</label>
    <fields>Name</fields>
    <fields>Phone</fields>
    <fields>Industry</fields>
    <fields>AnnualRevenue</fields>
    <fields>OwnerId</fields>
</CompactLayout>
```

---

## 8. FlexiPage (Lightning Record Page)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<FlexiPage xmlns="http://soap.sforge.com/2006/04/metadata">
    <flexiPageType>RecordPage</flexiPageType>
    <masterLabel>Account Record Page</masterLabel>
    <sobjectType>Account</sobjectType>
    <template>
        <name>flexipage:defaultPageTemplate2</name>
    </template>
    <flexiPageRegions>
        <name>header</name>
        <mode>Replace</mode>
        <type>Region</type>
        <itemInstances>
            <componentInstance>
                <componentName>force:highlights</componentName>
            </componentInstance>
        </itemInstances>
    </flexiPageRegions>
    <flexiPageRegions>
        <name>main</name>
        <mode>Replace</mode>
        <type>Region</type>
        <itemInstances>
            <componentInstance>
                <componentName>force:recordDetail</componentName>
            </componentInstance>
        </itemInstances>
        <itemInstances>
            <componentInstance>
                <componentName>c:customAccountDashboard</componentName>
                <componentInstanceProperties>
                    <name>showChart</name>
                    <value>true</value>
                </componentInstanceProperties>
                <visibilityRule>
                    <criteria>
                        <leftValue>{!Record.AnnualRevenue}</leftValue>
                        <operator>GREATERTHAN</operator>
                        <rightValue>1000000</rightValue>
                    </criteria>
                </visibilityRule>
            </componentInstance>
        </itemInstances>
    </flexiPageRegions>
    <flexiPageRegions>
        <name>sidebar</name>
        <mode>Replace</mode>
        <type>Region</type>
        <itemInstances>
            <componentInstance>
                <componentName>force:relatedListContainer</componentName>
            </componentInstance>
        </itemInstances>
    </flexiPageRegions>
</FlexiPage>
```

---

## 9. Custom Metadata Type

### Type Definition
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Integration_Setting__mdt</fullName>
    <label>Integration Setting</label>
    <pluralLabel>Integration Settings</pluralLabel>
    <visibility>Public</visibility>
    <fields>
        <fullName>Endpoint__c</fullName>
        <label>Endpoint</label>
        <type>Url</type>
        <required>true</required>
    </fields>
    <fields>
        <fullName>Timeout__c</fullName>
        <label>Timeout (ms)</label>
        <type>Number</type>
        <precision>5</precision>
        <scale>0</scale>
        <required>false</required>
        <defaultValue>30000</defaultValue>
    </fields>
    <fields>
        <fullName>Is_Active__c</fullName>
        <label>Is Active</label>
        <type>Checkbox</type>
        <defaultValue>true</defaultValue>
    </fields>
    <fields>
        <fullName>Batch_Size__c</fullName>
        <label>Batch Size</label>
        <type>Number</type>
        <precision>4</precision>
        <scale>0</scale>
        <defaultValue>200</defaultValue>
    </fields>
</CustomObject>
```

### Record Instance
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>ERP Integration</label>
    <protected>false</protected>
    <values>
        <field>Endpoint__c</field>
        <value>https://erp.example.com/api/v2</value>
    </values>
    <values>
        <field>Timeout__c</field>
        <value>15000</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value>true</value>
    </values>
    <values>
        <field>Batch_Size__c</field>
        <value>100</value>
    </values>
</CustomMetadata>
```

### Apex Access Pattern
```apex
// Query all active settings
List<Integration_Setting__mdt> settings = [
    SELECT Label, Endpoint__c, Timeout__c, Batch_Size__c
    FROM Integration_Setting__mdt
    WHERE Is_Active__c = true
];

// Get specific record
Integration_Setting__mdt erp = Integration_Setting__mdt.getInstance('ERP_Integration');
String endpoint = erp.Endpoint__c;
```

---

## 10. Custom Settings (Hierarchy)

### Definition
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Feature_Flags__c</fullName>
    <label>Feature Flags</label>
    <customSettingsType>Hierarchy</customSettingsType>
    <visibility>Public</visibility>
    <fields>
        <fullName>Enable_Integration__c</fullName>
        <label>Enable Integration</label>
        <type>Checkbox</type>
        <defaultValue>false</defaultValue>
    </fields>
    <fields>
        <fullName>Debug_Mode__c</fullName>
        <label>Debug Mode</label>
        <type>Checkbox</type>
        <defaultValue>false</defaultValue>
    </fields>
    <fields>
        <fullName>Max_Records__c</fullName>
        <label>Max Records</label>
        <type>Number</type>
        <precision>6</precision>
        <scale>0</scale>
    </fields>
</CustomObject>
```

### Apex Access
```apex
// Get for current user (respects hierarchy: User > Profile > Org)
Feature_Flags__c flags = Feature_Flags__c.getInstance();
Boolean integrationEnabled = flags.Enable_Integration__c;

// Get org defaults
Feature_Flags__c orgDefaults = Feature_Flags__c.getOrgDefaults();

// Get for specific user
Feature_Flags__c userFlags = Feature_Flags__c.getInstance(userId);

// Get for specific profile
Feature_Flags__c profileFlags = Feature_Flags__c.getInstance(profileId);
```

---

## 11. Platform Event

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Order_Event__e</fullName>
    <label>Order Event</label>
    <pluralLabel>Order Events</pluralLabel>
    <deploymentStatus>Deployed</deploymentStatus>
    <eventType>HighVolume</eventType>
    <publishBehavior>PublishAfterCommit</publishBehavior>
    <fields>
        <fullName>Order_Id__c</fullName>
        <label>Order ID</label>
        <type>Text</type>
        <length>18</length>
        <isFilteringDisabled>false</isFilteringDisabled>
        <isNameField>false</isNameField>
        <isSortingDisabled>false</isSortingDisabled>
    </fields>
    <fields>
        <fullName>Action__c</fullName>
        <label>Action</label>
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

### Publish Behavior Options
- `PublishAfterCommit` — Event published after transaction commits (default)
- `PublishImmediately` — Event published immediately, regardless of transaction outcome

### Apex Publish/Subscribe
```apex
// Publish
Order_Event__e event = new Order_Event__e(
    Order_Id__c = '001ABC',
    Action__c = 'Created',
    Payload__c = '{"status": "new"}'
);
Database.SaveResult sr = EventBus.publish(event);

// Subscribe via trigger
trigger OrderEventTrigger on Order_Event__e (after insert) {
    for (Order_Event__e event : Trigger.New) {
        // Process event
    }
}
```

---

## 12. Big Object

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Customer_Interaction__b</fullName>
    <label>Customer Interaction</label>
    <pluralLabel>Customer Interactions</pluralLabel>
    <deploymentStatus>Deployed</deploymentStatus>
    <fields>
        <fullName>Account_Id__c</fullName>
        <label>Account ID</label>
        <type>Text</type>
        <length>18</length>
        <required>true</required>
    </fields>
    <fields>
        <fullName>Interaction_Date__c</fullName>
        <label>Interaction Date</label>
        <type>DateTime</type>
        <required>true</required>
    </fields>
    <fields>
        <fullName>Channel__c</fullName>
        <label>Channel</label>
        <type>Text</type>
        <length>50</length>
    </fields>
    <fields>
        <fullName>Details__c</fullName>
        <label>Details</label>
        <type>LongTextArea</type>
        <length>32000</length>
        <visibleLines>5</visibleLines>
    </fields>
    <indexes>
        <fullName>CustomerInteractionIndex</fullName>
        <label>Customer Interaction Index</label>
        <fields>
            <name>Account_Id__c</name>
            <sortDirection>ASC</sortDirection>
        </fields>
        <fields>
            <name>Interaction_Date__c</name>
            <sortDirection>DESC</sortDirection>
        </fields>
    </indexes>
</CustomObject>
```

---

## 13. Custom Tab

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>My_Custom_Object__c</fullName>
    <customObject>true</customObject>
    <label>My Custom Object</label>
    <description>Tab for managing custom object records</description>
    <motif>Custom68: Desk</motif>
    <mobileReady>true</mobileReady>
</CustomTab>
```

### Lightning Web Component Tab
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforge.com/2006/04/metadata">
    <fullName>My_LWC_Tab</fullName>
    <label>My LWC Dashboard</label>
    <description>Custom LWC dashboard tab</description>
    <lwcComponent>myDashboardComponent</lwcComponent>
    <motif>Custom100: Shield</motif>
</CustomTab>
```

### Visualforce Tab
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>My_VF_Tab</fullName>
    <label>Legacy Dashboard</label>
    <page>MyVisualforcePage</page>
    <motif>Custom50: Compass</motif>
</CustomTab>
```

---

## 14. Quick Action

### Create Action
```xml
<?xml version="1.0" encoding="UTF-8"?>
<QuickAction xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Account.New_Case</fullName>
    <label>New Case</label>
    <type>Create</type>
    <targetObject>Case</targetObject>
    <targetParentField>AccountId</targetParentField>
    <description>Create a new case from Account</description>
    <successMessage>Case created successfully</successMessage>
    <quickActionLayout>
        <layoutSectionStyle>TwoColumnsLeftToRight</layoutSectionStyle>
        <quickActionLayoutColumns>
            <quickActionLayoutItems>
                <field>Subject</field>
                <uiBehavior>Required</uiBehavior>
            </quickActionLayoutItems>
            <quickActionLayoutItems>
                <field>Priority</field>
                <uiBehavior>Edit</uiBehavior>
            </quickActionLayoutItems>
        </quickActionLayoutColumns>
        <quickActionLayoutColumns>
            <quickActionLayoutItems>
                <field>Status</field>
                <uiBehavior>Readonly</uiBehavior>
            </quickActionLayoutItems>
        </quickActionLayoutColumns>
    </quickActionLayout>
</QuickAction>
```

### Update Action
```xml
<?xml version="1.0" encoding="UTF-8"?>
<QuickAction xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Case.Escalate</fullName>
    <label>Escalate</label>
    <type>Update</type>
    <targetObject>Case</targetObject>
    <quickActionLayout>
        <layoutSectionStyle>OneColumn</layoutSectionStyle>
        <quickActionLayoutColumns>
            <quickActionLayoutItems>
                <field>Priority</field>
                <uiBehavior>Edit</uiBehavior>
            </quickActionLayoutItems>
            <quickActionLayoutItems>
                <field>Description</field>
                <uiBehavior>Edit</uiBehavior>
            </quickActionLayoutItems>
        </quickActionLayoutColumns>
    </quickActionLayout>
</QuickAction>
```

### Log a Call Action
```xml
<?xml version="1.0" encoding="UTF-8"?>
<QuickAction xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Contact.Log_Call</fullName>
    <label>Log a Call</label>
    <type>LogACall</type>
    <targetObject>Task</targetObject>
    <targetParentField>WhoId</targetParentField>
    <quickActionLayout>
        <layoutSectionStyle>OneColumn</layoutSectionStyle>
        <quickActionLayoutColumns>
            <quickActionLayoutItems>
                <field>Subject</field>
                <uiBehavior>Required</uiBehavior>
            </quickActionLayoutItems>
            <quickActionLayoutItems>
                <field>Description</field>
                <uiBehavior>Edit</uiBehavior>
            </quickActionLayoutItems>
        </quickActionLayoutColumns>
    </quickActionLayout>
</QuickAction>
```

---

## 15. Custom Label

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomLabels xmlns="http://soap.sforce.com/2006/04/metadata">
    <labels>
        <fullName>Error_No_Permission</fullName>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>Error No Permission</shortDescription>
        <value>You do not have permission to perform this action.</value>
        <categories>Errors,UI</categories>
    </labels>
    <labels>
        <fullName>Success_Record_Saved</fullName>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>Success Record Saved</shortDescription>
        <value>Record saved successfully.</value>
        <categories>Success,UI</categories>
    </labels>
    <labels>
        <fullName>Batch_Job_Complete</fullName>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>Batch Job Complete</shortDescription>
        <value>Batch job completed. {0} records processed, {1} errors.</value>
        <categories>Notifications</categories>
    </labels>
</CustomLabels>
```

### Apex Usage
```apex
String msg = System.Label.Error_No_Permission;

// With parameters (using String.format)
String result = String.format(System.Label.Batch_Job_Complete, new List<String>{'500', '3'});
```

### LWC Usage
```javascript
import ERROR_LABEL from '@salesforce/label/c.Error_No_Permission';
```

---

## 16. List View

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Account.High_Value_Accounts</fullName>
    <label>High Value Accounts</label>
    <filterScope>Everything</filterScope>
    <columns>NAME</columns>
    <columns>ACCOUNT_NUMBER</columns>
    <columns>INDUSTRY</columns>
    <columns>ACCOUNT.ANNUAL_REVENUE</columns>
    <columns>ACCOUNT.PHONE1</columns>
    <columns>CORE.USERS.ALIAS</columns>
    <filters>
        <field>ACCOUNT.ANNUAL_REVENUE</field>
        <operation>greaterThan</operation>
        <value>1000000</value>
    </filters>
    <filters>
        <field>ACCOUNT.INDUSTRY</field>
        <operation>equals</operation>
        <value>Technology,Finance,Healthcare</value>
    </filters>
    <language>en_US</language>
    <sharedTo>
        <role>SalesManager</role>
        <group>AllInternalUsers</group>
    </sharedTo>
</ListView>
```

### Filter Scope Options
- `Everything` — All records
- `Mine` — My records
- `MineAndMyGroups` — My records and my groups' records
- `Queue` — Records in specific queue
- `Delegated` — Delegated records
- `Team` — My team's records

---

## 17. Path

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PathAssistant xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Opportunity_Sales_Path</fullName>
    <active>true</active>
    <entityName>Opportunity</entityName>
    <fieldName>StageName</fieldName>
    <masterLabel>Sales Path</masterLabel>
    <recordTypeName>B2B_Sale</recordTypeName>
    <pathAssistantSteps>
        <fieldNames>Amount</fieldNames>
        <fieldNames>CloseDate</fieldNames>
        <info>Identify the opportunity and gather initial requirements.</info>
        <picklistValueName>Prospecting</picklistValueName>
    </pathAssistantSteps>
    <pathAssistantSteps>
        <fieldNames>NextStep</fieldNames>
        <fieldNames>Description</fieldNames>
        <info>Qualify the lead and confirm budget, authority, need, timeline.</info>
        <picklistValueName>Qualification</picklistValueName>
    </pathAssistantSteps>
    <pathAssistantSteps>
        <fieldNames>Amount</fieldNames>
        <fieldNames>Probability</fieldNames>
        <info>Prepare and deliver the proposal to the customer.</info>
        <picklistValueName>Proposal/Price Quote</picklistValueName>
    </pathAssistantSteps>
    <pathAssistantSteps>
        <fieldNames>Amount</fieldNames>
        <fieldNames>CloseDate</fieldNames>
        <info>Negotiate terms and finalize the deal.</info>
        <picklistValueName>Negotiation/Review</picklistValueName>
    </pathAssistantSteps>
    <pathAssistantSteps>
        <fieldNames>Amount</fieldNames>
        <info>Congratulations! Close the deal and hand off to delivery.</info>
        <picklistValueName>Closed Won</picklistValueName>
    </pathAssistantSteps>
</PathAssistant>
```

---

## 18. Multi-Select Picklist

```xml
<fields>
    <fullName>Preferred_Channels__c</fullName>
    <label>Preferred Channels</label>
    <type>MultiselectPicklist</type>
    <required>false</required>
    <visibleLines>4</visibleLines>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>Email</fullName>
                <label>Email</label>
                <default>false</default>
                <isActive>true</isActive>
            </value>
            <value>
                <fullName>Phone</fullName>
                <label>Phone</label>
                <default>false</default>
                <isActive>true</isActive>
            </value>
            <value>
                <fullName>SMS</fullName>
                <label>SMS</label>
                <default>false</default>
                <isActive>true</isActive>
            </value>
            <value>
                <fullName>Social_Media</fullName>
                <label>Social Media</label>
                <default>false</default>
                <isActive>true</isActive>
            </value>
            <value>
                <fullName>In_Person</fullName>
                <label>In Person</label>
                <default>false</default>
                <isActive>true</isActive>
            </value>
        </valueSetDefinition>
    </valueSet>
</fields>
```

### SOQL with Multi-Select Picklist
```apex
// Use INCLUDES/EXCLUDES for multi-select picklist filters
List<Contact> contacts = [
    SELECT Id, Name, Preferred_Channels__c
    FROM Contact
    WHERE Preferred_Channels__c INCLUDES ('Email', 'Phone')
];
// Values stored as semicolon-separated: "Email;Phone;SMS"
```

---

## 19. Dependent Picklist

### Controlling Field (Standard Picklist)
```xml
<fields>
    <fullName>Region__c</fullName>
    <label>Region</label>
    <type>Picklist</type>
    <valueSet>
        <restricted>false</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>North America</fullName>
                <label>North America</label>
                <default>false</default>
            </value>
            <value>
                <fullName>Europe</fullName>
                <label>Europe</label>
                <default>false</default>
            </value>
            <value>
                <fullName>Asia Pacific</fullName>
                <label>Asia Pacific</label>
                <default>false</default>
            </value>
        </valueSetDefinition>
    </valueSet>
</fields>
```

### Dependent Field
```xml
<fields>
    <fullName>Country__c</fullName>
    <label>Country</label>
    <type>Picklist</type>
    <valueSet>
        <controllingField>Region__c</controllingField>
        <restricted>false</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>United States</fullName>
                <label>United States</label>
                <default>false</default>
            </value>
            <value>
                <fullName>Canada</fullName>
                <label>Canada</label>
                <default>false</default>
            </value>
            <value>
                <fullName>United Kingdom</fullName>
                <label>United Kingdom</label>
                <default>false</default>
            </value>
            <value>
                <fullName>Germany</fullName>
                <label>Germany</label>
                <default>false</default>
            </value>
            <value>
                <fullName>Japan</fullName>
                <label>Japan</label>
                <default>false</default>
            </value>
            <value>
                <fullName>Australia</fullName>
                <label>Australia</label>
                <default>false</default>
            </value>
        </valueSetDefinition>
        <valueSettings>
            <controllingFieldValue>North America</controllingFieldValue>
            <valueName>United States</valueName>
        </valueSettings>
        <valueSettings>
            <controllingFieldValue>North America</controllingFieldValue>
            <valueName>Canada</valueName>
        </valueSettings>
        <valueSettings>
            <controllingFieldValue>Europe</controllingFieldValue>
            <valueName>United Kingdom</valueName>
        </valueSettings>
        <valueSettings>
            <controllingFieldValue>Europe</controllingFieldValue>
            <valueName>Germany</valueName>
        </valueSettings>
        <valueSettings>
            <controllingFieldValue>Asia Pacific</controllingFieldValue>
            <valueName>Japan</valueName>
        </valueSettings>
        <valueSettings>
            <controllingFieldValue>Asia Pacific</controllingFieldValue>
            <valueName>Australia</valueName>
        </valueSettings>
    </valueSet>
</fields>
```

---

## 20. Encrypted Text Field

```xml
<fields>
    <fullName>SSN__c</fullName>
    <label>Social Security Number</label>
    <type>EncryptedText</type>
    <length>11</length>
    <maskChar>asterisk</maskChar>
    <maskType>lastFour</maskType>
    <required>false</required>
</fields>
```

### Mask Character Options
- `asterisk` — Masks with `*` characters
- `X` — Masks with `X` characters

### Mask Type Options
- `all` — Masks all characters
- `lastFour` — Shows last 4 characters (e.g., `*******6789`)
- `creditCard` — Shows last 4 digits in credit card format (e.g., `****-****-****-1234`)
- `nino` — National Insurance Number format
- `sin` — Social Insurance Number format
- `ssn` — Social Security Number format (e.g., `***-**-6789`)

### Limitations
- Maximum 175 characters
- Cannot be used as an External ID
- Cannot be unique
- Cannot use in filters, reports, SOQL WHERE
- Classic encryption (not Shield Platform Encryption)
- Cannot be used in formula fields
