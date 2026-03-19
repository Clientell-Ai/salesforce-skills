# sf-deploy Evaluation

## Should Trigger
- "Deploy my Apex classes and triggers to production"
- "My deployment is failing with a test coverage error"
- "Set up a CI/CD pipeline for Salesforce using GitHub Actions"
- "How do I create a package.xml for selective deployment?"
- "Troubleshoot this deployment error: Cannot deploy to production org"
- "Set up scratch org creation as part of my dev workflow"
- "My changeset deployment keeps failing with a dependency error"
- "How do I do a destructive deployment to remove old classes?"
- "Configure sfdx-project.json for my Salesforce DX project"
- "My deployment validation passed but the quick deploy failed"
- "Set up source tracking between my scratch org and local project"
- "How do I roll back a failed production deployment?"

## Should NOT Trigger
- "Write a new Apex class for the Account object" (expected: sf-apex)
- "Fix my failing test class before I can deploy" (expected: sf-test)
- "Create a Flow I want to deploy later" (expected: sf-flow)
- "Build the LWC I need to include in my deployment" (expected: sf-lwc)
- "Write the SOQL query my deployable Apex class needs" (expected: sf-soql)
- "Audit my code for security before deploying to AppExchange" (expected: sf-security)
- "Load data into my production org after deployment" (expected: sf-data)
- "Create custom fields and objects for my new feature" (expected: sf-schema)
- "I'm new to Salesforce development, where do I start?" (expected: sf-find)
- "Bulk insert records into my newly deployed org" (expected: sf-data)
- "Write a permission set XML file" (expected: sf-schema)
- "My Apex code has governor limit errors in production" (expected: sf-apex)
