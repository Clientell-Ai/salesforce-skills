/**
 * @description Normalizes Lead email values by trimming whitespace and converting to lowercase.
 */
public with sharing class LeadEmailNormalizer {

    /**
     * @description Normalizes the Email field for each Lead in the provided list.
     * @param leadsToNormalize The Lead records to normalize.
     */
    public static void normalizeEmails(List<Lead> leadsToNormalize) {
        if (leadsToNormalize == null || leadsToNormalize.isEmpty()) {
            return;
        }

        for (Lead leadRecord : leadsToNormalize) {
            if (leadRecord == null || leadRecord.Email == null) {
                continue;
            }

            leadRecord.Email = leadRecord.Email.trim().toLowerCase();
        }
    }
}
