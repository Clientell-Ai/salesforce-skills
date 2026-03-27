/**
 * @description Helper methods for Lead operations.
 */
public with sharing class LeadHelper {

    /**
     * @description Gets a Lead by Id using user-mode access.
     * @param leadId The Lead record Id.
     * @return The Lead record, or null when not found or when leadId is null.
     */
    public static Lead getById(Id leadId) {
        if (leadId == null) {
            return null;
        }
        if (!Schema.sObjectType.Lead.isAccessible()) {
            throw new AuraHandledException('Insufficient access to Lead.');
        }
        List<Lead> leads = [
            SELECT Id, FirstName, LastName, Company, Status, Email, Phone
            FROM Lead
            WHERE Id = :leadId
            WITH USER_MODE
            LIMIT 1
        ];
        return leads.isEmpty() ? null : leads[0];
    }
}
