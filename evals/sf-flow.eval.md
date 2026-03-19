# sf-flow Evaluation

## Should Trigger
- "Build a Screen Flow for submitting expense reports"
- "Convert my Process Builder on Lead to a Record-Triggered Flow"
- "Create an autolaunched Flow that assigns Cases based on priority"
- "Migrate my Workflow Rule on Opportunity to a Flow"
- "Design a Flow that walks users through a multi-step approval process"
- "My Flow is hitting a loop limit error, help me optimize it"
- "Create a before-save Flow that validates field combinations on Contact"
- "Build a scheduled Flow that sends reminder emails every Monday"
- "Add a decision element to my Flow that checks record type"
- "Help me create a subflow for address validation I can reuse"
- "Create a Flow that creates child records when a parent is inserted"
- "My Process Builder is deprecated, help me migrate to Flow"

## Should NOT Trigger
- "Write an Apex trigger that fires before insert on Account" (expected: sf-apex)
- "Write a test for my Flow-invocable Apex method" (expected: sf-test)
- "Create a Lightning Web Component with a form" (expected: sf-lwc)
- "Query all FlowDefinition records in my org" (expected: sf-soql)
- "Check my Flow for security issues with record access" (expected: sf-security)
- "Deploy my Flows from sandbox to production" (expected: sf-deploy)
- "Bulk update 10,000 records that my Flow should have processed" (expected: sf-data)
- "Create a custom field that my Flow will reference" (expected: sf-schema)
- "I have a business process to automate but I'm not sure how" (expected: sf-find)
- "Write an invocable method in Apex for my Flow to call" (expected: sf-apex)
- "Create a custom metadata type to configure my Flow behavior" (expected: sf-schema)
- "My deployment failed because of a Flow version conflict" (expected: sf-deploy)
