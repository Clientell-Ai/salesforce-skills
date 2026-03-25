/**
 * @description Handles normalization of Lead name and email fields before DML operations.
 */
public with sharing class LeadNormalizeTriggerHandler_31 {
    public static Boolean isRunning = false;

    /**
     * @description Normalizes FirstName, LastName, and Email on Lead records for before insert and before update.
     * @param newList List of Lead records from Trigger.new.
     */
    public static void handleBeforeInsertUpdate(List<Lead> newList) {
        if (isRunning || newList == null || newList.isEmpty()) {
            return;
        }

        isRunning = true;
        try {
            for (Lead leadRecord : newList) {
                if (String.isNotBlank(leadRecord.FirstName)) {
                    leadRecord.FirstName = leadRecord.FirstName.trim();
                }
                if (String.isNotBlank(leadRecord.LastName)) {
                    leadRecord.LastName = leadRecord.LastName.trim();
                }
                if (String.isNotBlank(leadRecord.Email)) {
                    leadRecord.Email = leadRecord.Email.trim().toLowerCase();
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Lead normalization failed: ' + ex.getMessage());
            throw ex;
        } finally {
            isRunning = false;
        }
    }
}
