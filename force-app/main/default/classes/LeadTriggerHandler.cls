/**
 * @description Trigger handler for Lead normalization in before contexts.
 */
public with sharing class LeadTriggerHandler extends TriggerHandlerBase {
    /**
     * @description Returns the handler name used for recursion control.
     * @return Handler name.
     */
    protected override String getHandlerName() {
        return 'LeadTriggerHandler';
    }

    /**
     * @description Normalizes Lead fields before insert.
     * @param newRecords Trigger new records.
     */
    protected override void beforeInsert(List<SObject> newRecords) {
        normalizeLeads((List<Lead>) newRecords);
    }

    /**
     * @description Normalizes Lead fields before update.
     * @param newRecords Trigger new records.
     * @param oldMap Trigger old map.
     */
    protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        normalizeLeads((List<Lead>) newRecords);
    }

    /**
     * @description Applies trim/lowercase normalization to Lead names and email.
     * @param leads Lead records to normalize.
     */
    private static void normalizeLeads(List<Lead> leads) {
        for (Lead l : leads) {
            if (l.FirstName != null) {
                l.FirstName = l.FirstName.trim();
            }
            if (l.LastName != null) {
                l.LastName = l.LastName.trim();
            }
            if (l.Email != null) {
                l.Email = l.Email.trim().toLowerCase();
            }
        }
    }
}
