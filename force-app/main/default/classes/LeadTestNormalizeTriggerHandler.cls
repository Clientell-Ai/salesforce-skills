/**
 * @description Normalizes Lead text fields during before insert and before update.
 */
public with sharing class LeadTestNormalizeTriggerHandler {
    public static Boolean isRunning = false;

    /**
     * @description Normalizes selected Lead fields by trimming whitespace and lowercasing email.
     * @param newLeads Trigger.new records.
     * @param oldMap Trigger.oldMap records (null on insert).
     * @param isInsert True when running in before insert context.
     * @param isUpdate True when running in before update context.
     */
    public static void normalize(
        List<Lead> newLeads,
        Map<Id, Lead> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        if (isRunning || newLeads == null || newLeads.isEmpty()) {
            return;
        }

        isRunning = true;
        try {
            for (Lead currentLead : newLeads) {
                if (currentLead == null) {
                    continue;
                }

                Lead oldLead = (isUpdate && oldMap != null) ? oldMap.get(currentLead.Id) : null;

                normalizeTextField(currentLead, oldLead, 'FirstName', isInsert, isUpdate, false);
                normalizeTextField(currentLead, oldLead, 'LastName', isInsert, isUpdate, false);
                normalizeTextField(currentLead, oldLead, 'Company', isInsert, isUpdate, false);
                normalizeTextField(currentLead, oldLead, 'Email', isInsert, isUpdate, true);
                normalizeTextField(currentLead, oldLead, 'Phone', isInsert, isUpdate, false);
                normalizeTextField(currentLead, oldLead, 'MobilePhone', isInsert, isUpdate, false);
            }
        } finally {
            isRunning = false;
        }
    }

    /**
     * @description Normalizes a single Lead text field if applicable for context and change tracking.
     * @param currentLead Current trigger record.
     * @param oldLead Prior record version (null on insert).
     * @param fieldApiName Lead field API name to normalize.
     * @param isInsert True when running in before insert context.
     * @param isUpdate True when running in before update context.
     * @param lowercaseAfterTrim True to lowercase trimmed value (used for Email).
     */
    private static void normalizeTextField(
        Lead currentLead,
        Lead oldLead,
        String fieldApiName,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean lowercaseAfterTrim
    ) {
        Object currentObj = currentLead.get(fieldApiName);
        if (currentObj == null) {
            return;
        }

        String currentValue = String.valueOf(currentObj);

        if (isUpdate) {
            String oldValue = oldLead == null ? null : (String) oldLead.get(fieldApiName);
            if (currentValue == oldValue) {
                return;
            }
        }

        if (!isInsert && !isUpdate) {
            return;
        }

        String normalized = currentValue.trim();
        if (lowercaseAfterTrim) {
            normalized = normalized.toLowerCase();
        }

        currentLead.put(fieldApiName, normalized);
    }
}
