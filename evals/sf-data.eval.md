# sf-data Evaluation

## Should Trigger
- "Load 100,000 Account records from a CSV into my sandbox"
- "Migrate data from one Salesforce org to another"
- "Help me set up sandbox seeding with realistic test data"
- "Bulk upsert Contact records using an external ID"
- "Export all Opportunity records with their line items for backup"
- "Write a data migration plan for moving from classic to a new data model"
- "Delete all records from a custom object in my sandbox"
- "Help me use Data Loader to bulk update Account ownership"
- "Create a script to anonymize production data for sandbox use"
- "My bulk API job is failing with ALLOTMENT_EXCEEDED, how do I fix it?"
- "Transform and load data from an external system into Salesforce"
- "Generate sample data for my demo org with realistic relationships"

## Should NOT Trigger
- "Write an Apex class that processes imported records" (expected: sf-apex)
- "Write tests for my data import trigger" (expected: sf-test)
- "Build a Flow that creates records when a file is uploaded" (expected: sf-flow)
- "Create an LWC file upload component for CSV imports" (expected: sf-lwc)
- "Write a SOQL query to verify the imported data" (expected: sf-soql)
- "Check if my data migration script respects sharing rules" (expected: sf-security)
- "Deploy my data loading scripts to the CI/CD pipeline" (expected: sf-deploy)
- "Create the custom objects I need before importing data" (expected: sf-schema)
- "What's the best way to move data in Salesforce?" (expected: sf-find)
- "Write a batch Apex class to transform records" (expected: sf-apex)
- "Add a new field to store the migration status" (expected: sf-schema)
- "Optimize my SOQL query used during data extraction" (expected: sf-soql)
