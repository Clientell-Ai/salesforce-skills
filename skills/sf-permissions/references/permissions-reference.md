# Permissions Reference

## Complete Permission Set XML

All possible elements in a Permission Set metadata file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Complete Example</label>
    <description>Shows all available permission set elements</description>
    <hasActivationRequired>false</hasActivationRequired>
    <license>Salesforce</license>
    <objectPermissions>
        <object>Account</object>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <fieldPermissions>
        <field>Account.AnnualRevenue</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <tabSettings>
        <tab>standard-Account</tab>
        <visibility>Visible</visibility>
        <!-- Options: DefaultOn, DefaultOff, Hidden, Visible -->
    </tabSettings>
    <classAccesses>
        <apexClass>AccountService</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <pageAccesses>
        <apexPage>AccountOverview</apexPage>
        <enabled>true</enabled>
    </pageAccesses>
    <customPermissions>
        <name>Can_Export_Data</name>
        <enabled>true</enabled>
    </customPermissions>
    <customMetadataTypeAccesses>
        <name>App_Config__mdt</name>
        <enabled>true</enabled>
    </customMetadataTypeAccesses>
    <customSettingAccesses>
        <name>Feature_Flags__c</name>
        <enabled>true</enabled>
    </customSettingAccesses>
    <externalDataSourceAccesses>
        <externalDataSource>ERP_System</externalDataSource>
        <enabled>true</enabled>
    </externalDataSourceAccesses>
    <flowAccesses>
        <flow>Order_Approval_Process</flow>
        <enabled>true</enabled>
    </flowAccesses>
    <recordTypeVisibilities>
        <recordType>Account.Enterprise</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <userPermissions>
        <name>RunReports</name>
        <enabled>true</enabled>
    </userPermissions>
    <applicationVisibilities>
        <application>Sales_Console</application>
        <visible>true</visible>
    </applicationVisibilities>
</PermissionSet>
```

## Permission Set Group with Muting

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSetGroup xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Support Agent</label>
    <description>Permissions for tier-1 support agents</description>
    <status>Updated</status>
    <permissionSets>
        <permissionSet>Case_Manager</permissionSet>
        <permissionSet>Knowledge_Reader</permissionSet>
        <permissionSet>Account_Reader</permissionSet>
    </permissionSets>
    <mutingPermissionSet>Support_Agent_Muting</mutingPermissionSet>
</PermissionSetGroup>
```

Muting permission set (revokes Case delete granted by Case_Manager):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Support Agent Muting</label>
    <objectPermissions>
        <object>Case</object>
        <allowDelete>true</allowDelete>
        <!-- true = MUTED in the group context -->
    </objectPermissions>
</PermissionSet>
```

## Access Audit SOQL Queries

### User Permission Summary

```sql
-- Permission sets assigned to a user (excluding profile-based)
SELECT PermissionSet.Label, PermissionSet.Name, PermissionSetGroup.MasterLabel
FROM PermissionSetAssignment
WHERE AssigneeId = '005xx000001234AAA'
AND PermissionSet.IsOwnedByProfile = false

-- Users with Modify All Data
SELECT Assignee.Name, Assignee.Username
FROM PermissionSetAssignment
WHERE PermissionSetId IN (
    SELECT Id FROM PermissionSet WHERE PermissionsModifyAllData = true
) AND Assignee.IsActive = true

-- Permission set count per user
SELECT Assignee.Name, COUNT(Id) permSetCount
FROM PermissionSetAssignment
WHERE Assignee.IsActive = true AND PermissionSet.IsOwnedByProfile = false
GROUP BY Assignee.Name ORDER BY COUNT(Id) DESC
```

### Object & Field Permission Audit

```sql
-- Permission sets granting Delete on an object
SELECT Parent.Label, Parent.IsOwnedByProfile, PermissionsDelete,
       PermissionsViewAllRecords, PermissionsModifyAllRecords
FROM ObjectPermissions
WHERE SobjectType = 'Opportunity' AND PermissionsDelete = true

-- Over-privileged: ModifyAllRecords on any object
SELECT Parent.Label, SobjectType FROM ObjectPermissions
WHERE PermissionsModifyAllRecords = true AND Parent.IsOwnedByProfile = false

-- Who can edit a sensitive field?
SELECT Parent.Label, Parent.IsOwnedByProfile
FROM FieldPermissions
WHERE Field = 'Contact.SSN__c' AND PermissionsEdit = true

-- Unassigned permission sets (no users)
SELECT Parent.Label, COUNT(Field) FROM FieldPermissions
WHERE ParentId NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment)
AND Parent.IsOwnedByProfile = false
GROUP BY Parent.Label
```

### Setup Entity & Group Queries

```sql
-- Apex class access
SELECT Parent.Label FROM SetupEntityAccess
WHERE SetupEntityType = 'ApexClass'
AND SetupEntityId IN (SELECT Id FROM ApexClass WHERE Name = 'OrderService')

-- Custom permissions granted to a user
SELECT Parent.Label, SetupEntityId FROM SetupEntityAccess
WHERE SetupEntityType = 'CustomPermission'
AND ParentId IN (
    SELECT PermissionSetId FROM PermissionSetAssignment
    WHERE AssigneeId = '005xx000001234AAA'
)

-- Permission sets in a group
SELECT PermissionSetGroup.MasterLabel, PermissionSet.Label
FROM PermissionSetGroupComponent ORDER BY PermissionSetGroup.MasterLabel
```

## Apex Permission Checking Patterns

### Schema Describe for CRUD/FLS

```apex
public with sharing class PermissionChecker {
    public static void checkObjectAccess(String objectName, String accessType) {
        Schema.DescribeSObjectResult objDescribe =
            Schema.getGlobalDescribe().get(objectName).getDescribe();
        Map<String, Boolean> accessMap = new Map<String, Boolean>{
            'create' => objDescribe.isCreateable(),
            'read'   => objDescribe.isAccessible(),
            'update' => objDescribe.isUpdateable(),
            'delete' => objDescribe.isDeletable()
        };
        if (!accessMap.get(accessType.toLowerCase())) {
            throw new InsufficientAccessException(
                'No ' + accessType + ' access on ' + objectName);
        }
    }

    public static void checkFieldAccess(String objectName, String fieldName, String accessType) {
        Schema.DescribeFieldResult fieldDescribe =
            Schema.getGlobalDescribe().get(objectName)
                .getDescribe().fields.getMap().get(fieldName).getDescribe();
        Boolean hasAccess = accessType == 'read'
            ? fieldDescribe.isAccessible() : fieldDescribe.isUpdateable();
        if (!hasAccess) {
            throw new InsufficientAccessException(
                'No ' + accessType + ' access on ' + objectName + '.' + fieldName);
        }
    }
}
```

### FeatureManagement for Custom Permissions

```apex
public with sharing class FeatureGate {
    public static Boolean canExportData() {
        return FeatureManagement.checkPermission('Can_Export_Data');
    }

    public static void exportData(List<SObject> records) {
        if (!FeatureManagement.checkPermission('Can_Export_Data')) {
            throw new FeatureDisabledException('Data export is not enabled');
        }
        // proceed with export logic
    }
}
```

### Security.stripInaccessible

```apex
public with sharing class SecureDataService {
    public static void updateAccounts(List<Account> accounts) {
        SObjectAccessDecision decision =
            Security.stripInaccessible(AccessType.UPDATABLE, accounts);
        update decision.getRecords();
        // Check stripped fields
        Map<String, Set<String>> removed = decision.getRemovedFields();
    }
}
```

## LWC Permission Imports

```javascript
// Standard user permissions
import hasModifyAllData from '@salesforce/userPermission/ModifyAllData';
import hasViewSetup from '@salesforce/userPermission/ViewSetup';
import hasRunReports from '@salesforce/userPermission/RunReports';

// Custom permissions
import canExportData from '@salesforce/customPermission/Can_Export_Data';
import canBypassValidation from '@salesforce/customPermission/Bypass_Validation';

export default class FeaturePanel extends LightningElement {
    get isAdmin() { return hasModifyAllData; }
    get showExportButton() { return canExportData; }
}
```

## Flow Permission Checks

| Variable | Returns | Use Case |
|----------|---------|----------|
| `$Permission.Custom_Permission_Name` | Boolean | Check custom permission |
| `$Profile.Name` | String | Check profile (avoid; use custom permissions instead) |
| `$User.Id` | String | Current user for permission queries |
| `$UserRole.Name` | String | Current user's role |

Use custom permissions in Flow Decision elements instead of profile name checks. Profiles change; permissions are stable.

## Permission Comparison Queries

```sql
-- Object permissions in PS_A but not PS_B
SELECT SobjectType, PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete
FROM ObjectPermissions WHERE Parent.Name = 'Permission_Set_A'
AND SobjectType NOT IN (
    SELECT SobjectType FROM ObjectPermissions WHERE Parent.Name = 'Permission_Set_B'
)

-- Full access picture for a user on a specific object
SELECT Parent.Label, Parent.IsOwnedByProfile,
       PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete
FROM ObjectPermissions WHERE SobjectType = 'Case'
AND ParentId IN (
    SELECT PermissionSetId FROM PermissionSetAssignment
    WHERE Assignee.Username = 'user@example.com'
)
```

## Permission Matrix Template

| Access | Reader PS | Editor PS | Manager PS | Admin PS |
|--------|-----------|-----------|------------|----------|
| **Order__c** | | | | |
| Create | - | Yes | Yes | Yes |
| Read | Yes | Yes | Yes | Yes |
| Edit | - | Yes | Yes | Yes |
| Delete | - | - | Yes | Yes |
| View All | - | - | Yes | Yes |
| **Fields** | | | | |
| Amount__c | Read | Read/Edit | Read/Edit | Read/Edit |
| InternalNotes__c | - | - | Read/Edit | Read/Edit |
| **Apex Classes** | | | | |
| OrderService | - | Yes | Yes | Yes |
| **Custom Permissions** | | | | |
| Can_Export_Data | - | - | Yes | Yes |

## Permission Deployment Best Practices

### Deploy Order (dependencies)

```
1. Custom Objects & Fields
2. Custom Permissions
3. Apex Classes & VF Pages
4. Permission Sets
5. Permission Set Groups
6. Permission Set Assignments
```

### CLI Commands

```bash
# Deploy permissions
sf project deploy start -d force-app/main/default/permissionsets \
  -d force-app/main/default/permissionsetgroups \
  -d force-app/main/default/customPermissions --target-org myOrg

# Retrieve permission sets
sf project retrieve start -m PermissionSet:Order_Manager --target-org myOrg
sf project retrieve start -m PermissionSetGroup:Sales_Team --target-org myOrg

# Assign
sf org assign permset --name Order_Manager --target-org myOrg
sf org assign permset --name Order_Manager \
  --on-behalf-of user@example.com --target-org myOrg
sf org assign permsetgroup --name Sales_Team --target-org myOrg
```

### Source Control Tips

- Exclude profiles via `.forceignore` (`**/profiles/**`) to avoid merge conflicts
- One permission set per functional area; name descriptively (`Object_Action`)
- Document purpose in `<description>`; version control muting sets alongside their group
- Review permission changes in PRs like code changes
