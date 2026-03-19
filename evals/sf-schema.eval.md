# sf-schema Evaluation

## Should Trigger
- "Create a custom object called Invoice__c with standard fields"
- "Add a lookup field from Contact to a custom Account_Plan__c object"
- "Generate the metadata XML for a new permission set"
- "Create a record type on Opportunity for renewal deals"
- "Build a custom metadata type for app configuration settings"
- "Add a picklist field to Lead with these values: Hot, Warm, Cold"
- "Create a validation rule that prevents closing Opportunities without a Contact Role"
- "Generate a page layout XML for the Case object"
- "Set up a formula field that calculates days since last activity"
- "Create a permission set that grants access to custom objects and fields"
- "Add a master-detail relationship between Invoice__c and Line_Item__c"
- "Create a custom label for multi-language support"

## Should NOT Trigger
- "Write a trigger on my new custom object" (expected: sf-apex)
- "Write test coverage for the validation rule logic in Apex" (expected: sf-test)
- "Build a Flow to automate record creation on my new object" (expected: sf-flow)
- "Create an LWC form for my custom object" (expected: sf-lwc)
- "Query the custom fields I just created" (expected: sf-soql)
- "Review field-level security settings in my Apex code" (expected: sf-security)
- "Deploy my new custom objects to production" (expected: sf-deploy)
- "Load data into my newly created custom object" (expected: sf-data)
- "What kind of customization do I need for my use case?" (expected: sf-find)
- "Write an Apex class to enforce complex validation beyond what rules support" (expected: sf-apex)
- "Bulk import records into the custom object I just created" (expected: sf-data)
- "Check if my metadata changes pass the security review" (expected: sf-security)
