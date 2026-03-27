/**
 * @description Utility methods for Lead records.
 */
public with sharing class LeadUtilNewOneBt {

    /**
     * @description Builds a Map of Lead Id to Lead for the provided Lead list.
     * @param leads The Lead records to index.
     * @return Map<Id, Lead> keyed by Lead Id.
     */
    public static Map<Id, Lead> mapById(List<Lead> leads) {
        Map<Id, Lead> result = new Map<Id, Lead>();
        if (leads == null || leads.isEmpty()) {
            return result;
        }
        if (!Schema.sObjectType.Lead.isAccessible()) {
            throw new AuraHandledException('Insufficient access to Lead');
        }
        for (Lead l : leads) {
            if (l != null && l.Id != null) {
                result.put(l.Id, l);
            }
        }
        return result;
    }
}
