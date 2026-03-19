# sf-apex Evaluation

## Should Trigger
- "Write an Apex class that sends email notifications when an Opportunity closes"
- "Create a trigger on Account that prevents deletion if it has related Contacts"
- "Generate a batch Apex job to update all Lead records older than 90 days"
- "Review my Apex code for best practices"
- "Write a schedulable class that runs every night to clean up old log records"
- "Help me build an Apex REST API endpoint for external integrations"
- "Create a queueable Apex class to process large record sets"
- "Refactor this trigger to use a handler pattern"
- "Write an after-insert trigger on Case that auto-assigns to a queue"
- "Generate an Apex utility class for currency conversion"
- "My Apex trigger is hitting governor limits, help me fix it"
- "Create an invocable Apex method I can call from a Flow"

## Should NOT Trigger
- "Write a test class for my AccountTrigger" (expected: sf-test)
- "Query all Accounts where Industry is Technology" (expected: sf-soql)
- "Check my Apex code for CRUD/FLS violations" (expected: sf-security)
- "Deploy my Apex classes to production" (expected: sf-deploy)
- "Create a Lightning Web Component that displays Account details" (expected: sf-lwc)
- "Build a Screen Flow for case creation" (expected: sf-flow)
- "Create a custom object called Invoice__c" (expected: sf-schema)
- "Load 50,000 Account records into my sandbox" (expected: sf-data)
- "I need help with Salesforce but I'm not sure where to start" (expected: sf-find)
- "Write a Jest test for my LWC component" (expected: sf-lwc)
- "How do I optimize this SOQL query with selective filters?" (expected: sf-soql)
- "Audit my trigger for sharing rule violations" (expected: sf-security)
