# sf-soql Evaluation

## Should Trigger
- "Write a SOQL query to get all Opportunities closing this quarter with their line items"
- "Optimize this query, it's too slow: SELECT Id FROM Account WHERE Name LIKE '%tech%'"
- "How do I write a SOQL query with a subquery on Contacts?"
- "Convert this SQL query to SOQL for Salesforce"
- "Write a SOSL query to search across Accounts, Contacts, and Leads"
- "My SOQL query is hitting the 50,000 row limit, help me add filters"
- "Write an aggregate SOQL query to count Opportunities by Stage"
- "How do I query polymorphic fields like WhoId on Task?"
- "Help me write a SOQL query with date literals like LAST_N_DAYS:30"
- "Create a SOQL query that joins Account to its child Cases and Contacts"
- "Write a dynamic SOQL query string in Apex for flexible filtering"
- "My query returns too many records, help me make it selective"

## Should NOT Trigger
- "Write an Apex class that processes the query results" (expected: sf-apex)
- "Write a test for my method that runs a SOQL query" (expected: sf-test)
- "Build a Flow that queries records and updates them" (expected: sf-flow)
- "Display query results in a Lightning datatable component" (expected: sf-lwc)
- "Check if my SOQL query respects field-level security" (expected: sf-security)
- "Deploy my Apex class that contains SOQL queries" (expected: sf-deploy)
- "Export all Account records using Data Loader" (expected: sf-data)
- "Create the custom fields I need before I can query them" (expected: sf-schema)
- "I need to get data from Salesforce but I'm not sure how" (expected: sf-find)
- "Bulk load query results into another org" (expected: sf-data)
- "Create a report type for the objects I want to query" (expected: sf-schema)
- "Write a batch Apex class that queries and updates millions of records" (expected: sf-apex)
