/**
 * @description Normalizes Lead name and email fields in before-trigger context.
 */
public with sharing class LeadNormalizationHandler {
    /**
     * @description Trims FirstName and LastName and lowercases Email when values are present.
     * @param leads The Lead records from Trigger.new.
     */
    public static void normalize(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        for (Lead leadRecord : leads) {
            if (leadRecord.FirstName != null) {
                leadRecord.FirstName = leadRecord.FirstName.trim();
            }
            if (leadRecord.LastName != null) {
                leadRecord.LastName = leadRecord.LastName.trim();
            }
            if (leadRecord.Email != null) {
                leadRecord.Email = leadRecord.Email.trim().toLowerCase();
            }
        }
    }
}
