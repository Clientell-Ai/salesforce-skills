/**
 * @description Handles Lead email normalization for trigger contexts.
 */
public with sharing class LeadNormalizeTriggerHandler_21 {
    private static Boolean isExecuting = false;

    /**
     * @description Normalizes Lead.Email values in bulk for before insert and before update.
     * @param newLeads Lead records from Trigger.new.
     * @param oldLeadMap Lead records from Trigger.oldMap.
     * @param isInsert Whether the trigger context is before insert.
     * @param isUpdate Whether the trigger context is before update.
     */
    public static void handle(
        List<Lead> newLeads,
        Map<Id, Lead> oldLeadMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        if (isExecuting || newLeads == null || newLeads.isEmpty()) {
            return;
        }

        isExecuting = true;
        try {
            for (Lead currentLead : newLeads) {
                if (currentLead == null) {
                    continue;
                }

                if (isInsert) {
                    normalizeForInsert(currentLead);
                } else if (isUpdate) {
                    normalizeForUpdate(currentLead, oldLeadMap);
                }
            }
        } finally {
            isExecuting = false;
        }
    }

    private static void normalizeForInsert(Lead currentLead) {
        if (currentLead.Email != null) {
            currentLead.Email = normalizeEmail(currentLead.Email);
        }
    }

    private static void normalizeForUpdate(Lead currentLead, Map<Id, Lead> oldLeadMap) {
        if (oldLeadMap == null || !oldLeadMap.containsKey(currentLead.Id)) {
            return;
        }

        Lead oldLead = oldLeadMap.get(currentLead.Id);
        if (oldLead == null || currentLead.Email == oldLead.Email) {
            return;
        }

        if (currentLead.Email != null) {
            currentLead.Email = normalizeEmail(currentLead.Email);
        }
    }

    private static String normalizeEmail(String emailValue) {
        String normalizedEmail = emailValue.trim().toLowerCase();
        return normalizedEmail == '' ? null : normalizedEmail;
    }
}
