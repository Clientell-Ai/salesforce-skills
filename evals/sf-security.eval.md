# sf-security Evaluation

## Should Trigger
- "Audit my Apex class for CRUD and FLS enforcement"
- "Check this trigger for SOQL injection vulnerabilities"
- "Review my code for sharing rule violations"
- "Is my Apex class respecting with sharing keyword correctly?"
- "Scan my Visualforce page for XSS vulnerabilities"
- "Make sure my Lightning component enforces field-level security"
- "Check if my REST API endpoint properly validates user permissions"
- "Review my code for insecure direct object references"
- "Does my batch job need with sharing or without sharing?"
- "Audit my SOQL queries for injection risk from user input"
- "Help me add Security.stripInaccessible to my Apex code"
- "My AppExchange security review failed, help me fix the findings"

## Should NOT Trigger
- "Write an Apex class with proper error handling" (expected: sf-apex)
- "Write tests to verify my security checks work correctly" (expected: sf-test)
- "Create a Flow with permission checks before record updates" (expected: sf-flow)
- "Build an LWC that hides fields based on user profile" (expected: sf-lwc)
- "Write a SOQL query using WITH SECURITY_ENFORCED" (expected: sf-soql)
- "Deploy my security-reviewed code to production" (expected: sf-deploy)
- "Migrate sensitive data between orgs securely" (expected: sf-data)
- "Create a permission set for the sales team" (expected: sf-schema)
- "What tool should I use to secure my Salesforce org?" (expected: sf-find)
- "Set up a profile with restricted object access" (expected: sf-schema)
- "Configure login IP ranges for my org" (expected: sf-find)
- "Add field-level security settings to my custom field metadata" (expected: sf-schema)
