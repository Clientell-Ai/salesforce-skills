# sf-test Evaluation

## Should Trigger
- "Write a test class for my OpportunityTrigger"
- "My test coverage is at 68%, help me get it above 75%"
- "Generate unit tests for the AccountService class"
- "This test class is failing with MIXED_DML_OPERATION, fix it"
- "Create test data factory methods for my custom objects"
- "Help me write negative test cases for my validation rules"
- "My test is failing because of a missing required field, how do I fix it?"
- "Add assertions to verify my trigger correctly updates the related Contact"
- "Write a test that covers the bulk insert path in my trigger"
- "Generate a test class with @testSetup method for Case-related tests"
- "How do I mock an HTTP callout in my test class?"
- "Improve coverage for the catch block in my Apex class"

## Should NOT Trigger
- "Write an Apex trigger on Opportunity" (expected: sf-apex)
- "Create a Jest test file for my contactList LWC" (expected: sf-lwc)
- "Query the ApexTestResult object for recent failures" (expected: sf-soql)
- "Deploy my test classes to the QA sandbox" (expected: sf-deploy)
- "Build a Flow that validates required fields on Lead" (expected: sf-flow)
- "Check if my test class follows security best practices" (expected: sf-security)
- "Create a TestData__c custom object to store test configurations" (expected: sf-schema)
- "Seed my sandbox with realistic test data for UAT" (expected: sf-data)
- "What Salesforce tool should I use to validate my code?" (expected: sf-find)
- "Write a batch Apex class that processes Account records" (expected: sf-apex)
- "Review my Apex class for governor limit issues" (expected: sf-apex)
- "Add a permission set for the QA team" (expected: sf-schema)
