/**
 * @description Utility methods for Lead.
 */
public with sharing class LeadUtil {

    /**
     * @description Builds a compact summary from non-blank Lead fields.
     * @param leadRecord The Lead record to summarize.
     * @return A summary string or null when input is null.
     */
    public static String buildLeadSummary(Lead leadRecord) {
        if (leadRecord == null) {
            return null;
        }

        List<String> parts = new List<String>();
        if (!String.isBlank(leadRecord.Company)) {
            parts.add(leadRecord.Company.trim());
        }
        if (!String.isBlank(leadRecord.Email)) {
            parts.add(leadRecord.Email.trim());
        }
        if (!String.isBlank(leadRecord.Status)) {
            parts.add(leadRecord.Status.trim());
        }

        return parts.isEmpty() ? '' : String.join(parts, ' | ');
    }
}
