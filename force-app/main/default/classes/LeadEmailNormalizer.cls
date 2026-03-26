/**
 * @description Normalizes Lead email values before persistence.
 */
public with sharing class LeadEmailNormalizer {
    /**
     * @description Normalizes the Lead Email field by trimming whitespace and converting to lowercase.
     * @param leadRecord The Lead record to normalize.
     */
    public static void normalizeEmail(Lead leadRecord) {
        if (leadRecord == null || String.isBlank(leadRecord.Email)) {
            return;
        }

        leadRecord.Email = leadRecord.Email.trim().toLowerCase();
    }
}
