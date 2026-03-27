/**
 * @description Utility methods for Lead records.
 */
public with sharing class LeadUtilNewOne {

    /**
     * @description Builds a readable lead display name using available fields.
     * @param leadRecord The Lead record to format.
     * @return A formatted string such as "Jane Doe (Acme)" or "Unknown Lead".
     */
    public static String formatLeadName(Lead leadRecord) {
        if (leadRecord == null) {
            return 'Unknown Lead';
        }
        if (!Schema.sObjectType.Lead.isAccessible()) {
            throw new SecurityException('Insufficient access to Lead.');
        }

        String firstName = String.isBlank(leadRecord.FirstName) ? '' : leadRecord.FirstName.trim();
        String lastName = String.isBlank(leadRecord.LastName) ? '' : leadRecord.LastName.trim();
        String company = String.isBlank(leadRecord.Company) ? '' : leadRecord.Company.trim();

        String fullName;
        if (!String.isBlank(firstName) && !String.isBlank(lastName)) {
            fullName = firstName + ' ' + lastName;
        } else if (!String.isBlank(lastName)) {
            fullName = lastName;
        } else if (!String.isBlank(firstName)) {
            fullName = firstName;
        } else {
            fullName = 'Unknown Lead';
        }

        if (!String.isBlank(company)) {
            return fullName + ' (' + company + ')';
        }
        return fullName;
    }
}
