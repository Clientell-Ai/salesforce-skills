/**
 * @description Utility methods for working with Lead records.
 */
public with sharing class LeadUtilK {

    /**
     * @description Builds a readable display string for a Lead record.
     * @param leadRecord Lead record to format.
     * @return A formatted string in the form "Full Name | Company | Status", or an empty string when no Lead is provided.
     */
    public static String buildLeadDisplayString(Lead leadRecord) {
        if (leadRecord == null) {
            return '';
        }

        if (!Schema.sObjectType.Lead.isAccessible()) {
            throw new AuraHandledException('Insufficient access to Lead records.');
        }

        List<String> parts = new List<String>();

        String fullName = String.join(
            new List<String>{
                leadRecord.FirstName == null ? '' : leadRecord.FirstName.trim(),
                leadRecord.LastName == null ? '' : leadRecord.LastName.trim()
            },
            ' '
        ).trim();

        parts.add(String.isBlank(fullName) ? 'Unnamed Lead' : fullName);
        parts.add(String.isBlank(leadRecord.Company) ? 'No Company' : leadRecord.Company.trim());
        parts.add(String.isBlank(leadRecord.Status) ? 'No Status' : leadRecord.Status.trim());

        return String.join(parts, ' | ');
    }
}
