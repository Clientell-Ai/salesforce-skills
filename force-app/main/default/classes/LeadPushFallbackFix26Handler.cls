/**
 * @description Normalizes Lead name/email fields in before insert/update context.
 */
public with sharing class LeadPushFallbackFix26Handler {

    /**
     * @description Trims FirstName and LastName, and trims+lowercases Email.
     * @param leads Incoming trigger records from Trigger.new.
     */
    public static void handleBeforeInsertUpdate(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        for (Lead leadRecord : leads) {
            if (leadRecord.FirstName != null) {
                String trimmedFirstName = leadRecord.FirstName.trim();
                if (trimmedFirstName != leadRecord.FirstName) {
                    leadRecord.FirstName = trimmedFirstName;
                }
            }

            if (leadRecord.LastName != null) {
                String trimmedLastName = leadRecord.LastName.trim();
                if (trimmedLastName != leadRecord.LastName) {
                    leadRecord.LastName = trimmedLastName;
                }
            }

            if (leadRecord.Email != null) {
                String normalizedEmail = leadRecord.Email.trim().toLowerCase();
                if (normalizedEmail != leadRecord.Email) {
                    leadRecord.Email = normalizedEmail;
                }
            }
        }
    }
}
