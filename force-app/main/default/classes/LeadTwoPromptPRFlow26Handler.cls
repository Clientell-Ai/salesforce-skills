/**
 * @description Trigger handler for normalizing Lead name and email fields.
 */
public with sharing class LeadTwoPromptPRFlow26Handler {

    /**
     * @description Normalizes Lead fields in before-trigger context.
     * @param leads Incoming trigger records from Trigger.new.
     */
    public static void handleBefore(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        for (Lead leadRecord : leads) {
            normalizeLeadFields(leadRecord);
        }
    }

    /**
     * @description Applies trim/lowercase rules only when a value actually changes.
     * @param leadRecord Lead record to normalize.
     */
    private static void normalizeLeadFields(Lead leadRecord) {
        if (leadRecord == null) {
            return;
        }

        // Normalize first and last names by trimming only.
        String normalizedFirstName = normalizeTrimmed(leadRecord.FirstName);
        if (normalizedFirstName != null && normalizedFirstName != leadRecord.FirstName) {
            leadRecord.FirstName = normalizedFirstName;
        }

        String normalizedLastName = normalizeTrimmed(leadRecord.LastName);
        if (normalizedLastName != null && normalizedLastName != leadRecord.LastName) {
            leadRecord.LastName = normalizedLastName;
        }

        // Normalize email by trimming and lowercasing.
        String normalizedEmail = normalizeEmail(leadRecord.Email);
        if (normalizedEmail != null && normalizedEmail != leadRecord.Email) {
            leadRecord.Email = normalizedEmail;
        }
    }

    /**
     * @description Trims a string value and preserves nulls.
     * @param value Input value.
     * @return Trimmed value or null.
     */
    private static String normalizeTrimmed(String value) {
        if (value == null) {
            return null;
        }
        return value.trim();
    }

    /**
     * @description Trims and lowercases an email value and preserves nulls.
     * @param email Input email value.
     * @return Normalized email or null.
     */
    private static String normalizeEmail(String email) {
        if (email == null) {
            return null;
        }
        return email.trim().toLowerCase();
    }
}
