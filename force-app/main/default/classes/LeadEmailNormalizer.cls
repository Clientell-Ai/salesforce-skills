/**
 * @description Normalizes Lead email values by trimming whitespace and converting to lowercase.
 */
public with sharing class LeadEmailNormalizer {

    /**
     * @description Normalizes the Email field on each Lead in the provided list.
     *              Blank email values are set to null.
     * @param leads The Lead records to normalize. Null records are ignored.
     */
    public static void normalizeLeadEmails(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        for (Lead leadRecord : leads) {
            if (leadRecord == null) {
                continue;
            }

            if (String.isBlank(leadRecord.Email)) {
                leadRecord.Email = null;
                continue;
            }

            leadRecord.Email = leadRecord.Email.trim().toLowerCase();
        }
    }
}
