# Salesforce Deployment Patterns Reference

## 1. Scratch Org Definition File

### Complete project-scratch-def.json Template
```json
{
  "orgName": "My Scratch Org",
  "edition": "Enterprise",
  "description": "Scratch org for feature development",
  "hasSampleData": false,
  "language": "en_US",
  "country": "US",
  "features": [
    "EnableSetPasswordInApi",
    "Communities",
    "ServiceCloud",
    "SalesCloud",
    "StateAndCountryPicklist",
    "PersonAccounts",
    "MultiCurrency",
    "AuthorApex",
    "API",
    "LightningSalesConsole",
    "LightningServiceConsole",
    "ContactsToMultipleAccounts"
  ],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    },
    "securitySettings": {
      "sessionSettings": {
        "forceRelogin": false
      },
      "passwordPolicies": {
        "enableSetPasswordInApi": true
      }
    },
    "chatterSettings": {
      "enableChatter": true
    },
    "communitiesSettings": {
      "enableNetworksEnabled": true
    },
    "omniChannelSettings": {
      "enableOmniChannel": true
    },
    "caseSettings": {
      "systemUserEmail": "admin@example.com"
    },
    "pathAssistantSettings": {
      "pathAssistantEnabled": true
    },
    "opportunitySettings": {
      "enableOpportunityTeam": true
    }
  },
  "objectSettings": {
    "opportunity": {
      "sharingModel": "Private"
    },
    "case": {
      "sharingModel": "Private"
    }
  }
}
```

---

## 2. Scratch Org Lifecycle

### Create Scratch Org
```bash
# Basic creation
sf org create scratch -f config/project-scratch-def.json -a my-scratch -d -y 30

# With specific Dev Hub
sf org create scratch -f config/project-scratch-def.json -a my-scratch -v MyDevHub -y 7

# Options
# -a : alias
# -d : set as default org
# -y : duration in days (1-30)
# -v : target Dev Hub
# -w : wait time in minutes
```

### Push/Pull Source
```bash
# Push source to scratch org
sf project deploy start

# Pull changes from scratch org
sf project retrieve start

# With conflict detection
sf project deploy start --ignore-conflicts
```

### Delete Scratch Org
```bash
sf org delete scratch -o my-scratch -p
# -p : no prompt for confirmation
```

### Org Shape
```bash
# Create shape from a source org (sandbox or production)
sf org create shape -o SourceOrgAlias

# List available shapes
sf org list shape

# Create scratch org from shape
sf org create scratch -f config/project-scratch-def.json -a shaped-scratch --source-org SourceOrgAlias
```

### Snapshot Orgs
```bash
# Create snapshot from scratch org
sf org create snapshot -o MyScratchOrg -n MySnapshot -d "Baseline config snapshot"

# Create scratch org from snapshot
sf org create scratch --snapshot MySnapshot -a from-snapshot -y 7

# List snapshots
sf org list snapshot

# Delete snapshot
sf org delete snapshot -s MySnapshot
```

---

## 3. Unlocked Package Lifecycle

### sfdx-project.json with Packages
```json
{
  "packageDirectories": [
    {
      "path": "force-app/main/default",
      "default": true,
      "package": "MyUnlockedPackage",
      "versionName": "Spring Release",
      "versionNumber": "1.2.0.NEXT",
      "versionDescription": "Spring feature release",
      "dependencies": [
        {
          "package": "DependencyPackage",
          "versionNumber": "2.0.0.LATEST"
        },
        {
          "package": "04t000000000000AAA"
        }
      ]
    },
    {
      "path": "force-app/unpackaged",
      "default": false
    }
  ],
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "60.0",
  "packageAliases": {
    "MyUnlockedPackage": "0Ho000000000000AAA",
    "MyUnlockedPackage@1.0.0-1": "04t000000000000AAA",
    "MyUnlockedPackage@1.1.0-1": "04t000000000001AAA",
    "DependencyPackage": "0Ho000000000001AAA",
    "DependencyPackage@2.0.0-1": "04t000000000002AAA"
  }
}
```

### Create Package
```bash
sf package create -n MyUnlockedPackage -t Unlocked -r force-app/main/default -v DevHub

# Options:
# -t : Managed | Unlocked
# -r : path
# -e : no namespace (org-dependent)
```

### Create Package Version
```bash
# Create beta version
sf package version create -p MyUnlockedPackage -d force-app/main/default -x -w 30 -v DevHub

# Create released version
sf package version create -p MyUnlockedPackage -d force-app/main/default -x -w 30 --code-coverage -v DevHub

# Options:
# -x : install key bypass (no password)
# -k : install key (password protect)
# -c : code coverage calculation
# --code-coverage : require 75% coverage for release
# -w : wait time in minutes
```

### Promote to Released
```bash
sf package version promote -p MyUnlockedPackage@1.2.0-1 -v DevHub
```

### Install Package
```bash
# Install in target org
sf package install -p MyUnlockedPackage@1.2.0-1 -o TargetOrg -w 15

# With install key
sf package install -p 04t000000000000AAA -k "installPassword" -o TargetOrg -w 15

# Options:
# -r : no prompt
# -a : apex compile (all/package)
# -s : security type (AdminsOnly/AllUsers)
# -b : publish wait time
```

### Uninstall Package
```bash
sf package uninstall -p MyUnlockedPackage@1.2.0-1 -o TargetOrg -w 15
```

---

## 4. 2GP Managed Packages

### Differences from Unlocked Packages

| Feature                 | Unlocked Package      | 2GP Managed Package      |
|-------------------------|-----------------------|--------------------------|
| Namespace               | Optional              | Required                 |
| IP Protection           | No                    | Yes (code obfuscation)   |
| Subscriber upgrades     | Push/pull             | Push upgrades supported  |
| AppExchange listing     | No                    | Yes                      |
| Deprecation of components| Flexible             | Strict deprecation rules |
| Apex access modifiers   | Not enforced          | @namespaceAccessible     |

### Create 2GP Managed Package
```bash
sf package create -n MyManagedPkg -t Managed -r force-app -v DevHub --namespace my_ns
```

### Namespace in sfdx-project.json
```json
{
  "namespace": "my_ns",
  "packageDirectories": [
    {
      "path": "force-app",
      "package": "MyManagedPkg",
      "versionNumber": "1.0.0.NEXT"
    }
  ]
}
```

### Exposing Apex in Managed Packages
```apex
// Make global class accessible
@namespaceAccessible
public class MyService {
    @namespaceAccessible
    public static String doWork(String input) {
        return input.toUpperCase();
    }
}
```

---

## 5. Destructive Changes

### destructiveChangesPre.xml
Runs **before** deployment. Use to remove components that would conflict with deployment.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>OldClassName</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>OldTriggerName</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>OldFlowName</members>
        <name>Flow</name>
    </types>
    <version>60.0</version>
</Package>
```

### destructiveChangesPost.xml
Runs **after** deployment. Use to clean up components no longer referenced.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>DeprecatedClass</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>MyObject__c.Old_Field__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Old_Page_Layout</members>
        <name>Layout</name>
    </types>
    <types>
        <members>OldLwcComponent</members>
        <name>LightningComponentBundle</name>
    </types>
    <version>60.0</version>
</Package>
```

### When to Use Pre vs Post
| Scenario                                   | Use Pre or Post? |
|--------------------------------------------|------------------|
| Removing a class referenced by new code    | N/A (fix first)  |
| Removing an old class replaced by new one  | Post             |
| Removing field used in validation rule being removed | Pre     |
| Removing old trigger being replaced        | Pre              |
| General cleanup of unused components       | Post             |

### Deploy with Destructive Changes
```bash
# Using sf CLI
sf project deploy start --manifest manifest/package.xml \
  --pre-destructive-changes manifest/destructiveChangesPre.xml \
  --post-destructive-changes manifest/destructiveChangesPost.xml \
  -o TargetOrg

# Empty package.xml required if only doing destructive deployment
# Create a package.xml with just the version:
```
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <version>60.0</version>
</Package>
```

### Risk Mitigation
- Always validate before deploying: `sf project deploy start --dry-run`
- Deploy to sandbox first
- Keep destructive changes in version control
- Document why each component is being removed

---

## 6. Sandbox Types Comparison

| Feature               | Developer      | Developer Pro  | Partial Copy   | Full           |
|-----------------------|----------------|----------------|----------------|----------------|
| Storage               | 200 MB         | 1 GB           | 5 GB           | Same as prod   |
| Data                  | No data        | No data        | Sample (template)| Full copy     |
| Metadata              | Full copy      | Full copy      | Full copy      | Full copy      |
| Refresh Interval      | 1 day          | 1 day          | 5 days         | 29 days        |
| Included (EE)         | Up to 25       | 0              | 0              | 0              |
| Use Case              | Dev/unit test  | Dev/integration| UAT/staging    | Performance/UAT|

---

## 7. Sandbox Refresh & Seeding

### Refresh Workflow
```
1. Setup > Sandboxes > select sandbox > Refresh
2. Choose sandbox license type
3. Select Sandbox Template (for Partial Copy)
4. Optionally configure Apex post-refresh class
5. Activate sandbox when refresh completes
```

### Post-Refresh Apex Script
```apex
global class SandboxPostRefresh implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        // Get sandbox info
        String orgId = context.organizationId();
        String sandboxId = context.sandboxId();
        String sandboxName = context.sandboxName();

        // Mask sensitive data
        List<Contact> contacts = [SELECT Id, Email, Phone FROM Contact LIMIT 50000];
        for (Contact c : contacts) {
            c.Email = c.Id + '@test.invalid';
            c.Phone = '555-0000';
        }
        update contacts;

        // Update custom settings
        MySettings__c settings = MySettings__c.getOrgDefaults();
        settings.Integration_Endpoint__c = 'https://sandbox-api.example.com';
        settings.Is_Sandbox__c = true;
        upsert settings;

        // Disable workflows/triggers via custom setting flag
        FeatureFlags__c flags = FeatureFlags__c.getOrgDefaults();
        flags.Disable_Integrations__c = true;
        upsert flags;
    }
}
```

### Data Seeding Strategies
- **Sandbox Template** (Partial Copy): Define which objects/records to copy
- **Post-refresh Apex**: Create test data programmatically
- **Data Loader**: Automated scripts to import CSV data
- **sf data import tree**: Import from JSON plan files (see sf-data reference)

---

## 8. Source Format vs MDAPI Format

### Key Differences

| Aspect         | Source Format                          | MDAPI Format                        |
|----------------|---------------------------------------|-------------------------------------|
| Structure      | Decomposed into small files           | Monolithic XML files                |
| VCS friendly   | Yes (small, granular diffs)           | No (large XML changes)             |
| Custom Object  | Split: fields/, listViews/, etc.      | Single .object file                 |
| Permission Set | Split per object/field                | Single .permissionset file          |
| CLI command    | sf project deploy/retrieve start      | sf project deploy/retrieve start -x |

### Convert Between Formats
```bash
# Source to MDAPI format
sf project convert source -r force-app -d mdapi_output

# MDAPI to Source format
sf project convert mdapi -r mdapi_output -d force-app
```

### When to Use Each
- **Source Format**: Default for all new projects, version control
- **MDAPI Format**: Legacy CI/CD pipelines, package.xml-based deployments, change sets migration

---

## 9. Salesforce Code Analyzer

### Basic Commands
```bash
# Run scanner on a directory
sf scanner run --target force-app --format table

# Run with specific format output
sf scanner run --target force-app --format csv --outfile results.csv

# Run with specific engines
sf scanner run --target force-app --engine pmd,eslint --format table

# Run specific categories
sf scanner run --target force-app --category "Security,Best Practices" --format table

# Run against specific files
sf scanner run --target force-app/main/default/classes/MyClass.cls --format table
```

### PMD Rule Categories

| Category        | Description                                        |
|-----------------|----------------------------------------------------|
| Best Practices  | Naming conventions, empty blocks, unused variables  |
| Code Style      | Formatting, brace usage, one-statement-per-line     |
| Design          | Cyclomatic complexity, deeply nested ifs, god class |
| Documentation   | Missing comments, uncommented empty methods         |
| Error Prone     | Empty catch blocks, null checks, assignment issues  |
| Performance     | Unnecessary object creation, inefficient loops      |
| Security        | CRUD/FLS, SOQL injection, XSS, open redirect       |

### Custom Rule Configuration
```bash
# List available rules
sf scanner rule list

# List rules filtered by category
sf scanner rule list --category Security

# Use custom PMD ruleset
sf scanner run --target force-app --pmdconfig config/pmd-ruleset.xml
```

### Sample PMD Ruleset (config/pmd-ruleset.xml)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ruleset name="Custom Ruleset"
    xmlns="http://pmd.sourceforge.net/ruleset/2.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0
        https://pmd.sourceforge.io/ruleset_2_0_0.xsd">

    <description>Custom PMD Ruleset for Salesforce</description>

    <rule ref="category/apex/security.xml"/>
    <rule ref="category/apex/bestpractices.xml"/>
    <rule ref="category/apex/performance.xml"/>

    <!-- Exclude specific rules -->
    <rule ref="category/apex/codestyle.xml">
        <exclude name="IfStmtsMustUseBraces"/>
    </rule>
</ruleset>
```

---

## 10. sfdx-git-delta Configuration

### Basic Usage
```bash
# Generate delta package between two commits
sgd --from HEAD~1 --to HEAD --repo . --output delta

# Between branches
sgd --from origin/main --to feature-branch --repo . --output delta

# Generate delta package.xml
sgd --from COMMIT_SHA_1 --to COMMIT_SHA_2 --repo . --output delta --generate-delta
```

### Output Structure
```
delta/
  package/
    package.xml           # Components to deploy
  destructiveChanges/
    destructiveChanges.xml # Components to delete
```

### .sgdignore File
```
# Ignore these metadata types from delta
**/profiles/*
**/settings/*
**/dashboards/*
**/reports/*
**/documents/*
force-app/main/default/staticresources/large_file.resource
```

### CI/CD Integration Example
```yaml
# GitHub Actions example
- name: Install sfdx-git-delta
  run: |
    echo y | sf plugins install sfdx-git-delta

- name: Generate delta
  run: |
    sgd --from origin/main --to HEAD --repo . --output delta

- name: Deploy delta
  run: |
    sf project deploy start --source-dir delta/package \
      --post-destructive-changes delta/destructiveChanges/destructiveChanges.xml \
      -o TargetOrg
```

---

## 11. Authentication Methods

### JWT Bearer Flow Setup
```bash
# 1. Create Connected App in Dev Hub with:
#    - Enable OAuth Settings
#    - Callback: http://localhost:1717/OAuthRedirect
#    - Scopes: api, refresh_token, offline_access
#    - Enable "Use digital signatures" — upload server.crt

# 2. Create certificate and key
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl x509 -req -sha256 -days 365 -in server.csr -signkey server.key -out server.crt

# 3. Authorize with JWT
sf org login jwt \
  --client-id CONSUMER_KEY \
  --jwt-key-file server.key \
  --username admin@example.com \
  --instance-url https://login.salesforce.com \
  --alias MyOrg \
  --set-default
```

### Web Login
```bash
# Interactive browser login
sf org login web -a MyOrg -r https://login.salesforce.com

# Sandbox login
sf org login web -a MySandbox -r https://test.salesforce.com
```

### SFDX Auth URL (for CI)
```bash
# Export auth URL from an already-authenticated org
sf org display -o MyOrg --verbose
# Copy the "Sfdx Auth Url" value

# Store in CI secret, then authenticate:
echo "$SFDX_AUTH_URL" > authfile.txt
sf org login sfdx-url -f authfile.txt -a MyOrg -d
rm authfile.txt
```

### Device Flow
```bash
# For headless environments (no browser)
sf org login device -a MyOrg -r https://login.salesforce.com
# Follow prompts: visit URL, enter code
```

---

## 12. Change Set Workflow

### Outbound Change Set
```
1. Setup > Outbound Change Sets > New
2. Name the change set
3. Add Components:
   - Select component type (Apex Class, Custom Object, etc.)
   - Select individual components
   - "Add to Change Set"
4. Add dependent components:
   - "View/Add Dependencies" to auto-detect
5. Upload:
   - Select target (connected sandbox or production)
   - Click "Upload"
```

### Inbound Change Set
```
1. Setup > Inbound Change Sets
2. Select the uploaded change set
3. Validate:
   - Run specified tests / run all tests
   - Check validation results
4. Deploy:
   - Deploy after successful validation
   - Choose test level for production deployments
```

### Limitations
- Cannot delete/rename components
- One-directional (must re-upload for changes)
- No version control
- Cannot deploy to unconnected orgs
- Limited to 10,000 components

---

## 13. Multi-Package Deployment Ordering

### Dependency Resolution
```bash
# Install packages in dependency order
# 1. Base/shared package first
sf package install -p BasePackage@1.0.0-1 -o TargetOrg -w 15

# 2. Then dependent packages
sf package install -p FeaturePackage@2.0.0-1 -o TargetOrg -w 15

# 3. Finally, top-level package
sf package install -p MainApp@3.0.0-1 -o TargetOrg -w 15
```

### Namespace Dependencies
```json
// sfdx-project.json dependency declaration
{
  "dependencies": [
    {
      "package": "base_ns@1.0.0-1"
    },
    {
      "package": "04tXXXXXXXXXXXXXXX",
      "versionNumber": "2.0.0.LATEST"
    }
  ]
}
```

### Install Key Handling
```bash
# Install with install key
sf package install -p MyPackage@1.0.0-1 -k "s3cureKey!" -o TargetOrg -w 15

# In CI/CD, store install key as secret
sf package install -p MyPackage@1.0.0-1 -k "$PACKAGE_INSTALL_KEY" -o TargetOrg -w 15
```

---

## 14. DevOps Center

### Overview
- Salesforce-native DevOps tool (no external CI/CD required)
- Git-based source tracking
- Built-in pipeline management

### Work Items
```
DevOps Center > Project > Work Items:
- Create work item (linked to user story)
- Assign to developer
- Developer makes changes in scratch org / sandbox
- Commit changes to feature branch
- Submit for review
```

### Branching Model
```
main (production)
  └── release/v1.2 (staging)
       └── feature/WORK-001 (developer branch)
       └── feature/WORK-002 (developer branch)
```

### Deployment Pipeline
```
Development → Integration/Review → Staging → Production

Each stage:
1. Changes promoted from previous stage
2. Validation run (test execution)
3. Approval gate (optional)
4. Deployment
```

### Setup Requirements
- Enable DevOps Center in Setup
- Connect source control (GitHub, GitLab, Bitbucket)
- Configure environments (map orgs to pipeline stages)
- Define named credentials for org authentication
