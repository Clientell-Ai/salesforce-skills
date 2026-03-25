/**
 * @description Handles trimming of leading and trailing spaces for Lead text fields.
 */
public with sharing class LeadSpaceTrimHandlerX {
    /**
     * @description Trims configured Lead fields for each provided Lead record.
     * @param leads The Lead records to sanitize.
     */
    public static void trimLeadFields(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        for (Lead leadRecord : leads) {
            if (leadRecord == null) {
                continue;
            }

            leadRecord.FirstName = trimValue(leadRecord.FirstName);
            leadRecord.LastName = trimValue(leadRecord.LastName);
            leadRecord.Company = trimValue(leadRecord.Company);
            leadRecord.Email = trimValue(leadRecord.Email);
            leadRecord.Phone = trimValue(leadRecord.Phone);
            leadRecord.MobilePhone = trimValue(leadRecord.MobilePhone);
            leadRecord.Street = trimValue(leadRecord.Street);
            leadRecord.City = trimValue(leadRecord.City);
            leadRecord.State = trimValue(leadRecord.State);
            leadRecord.PostalCode = trimValue(leadRecord.PostalCode);
            leadRecord.Country = trimValue(leadRecord.Country);
        }
    }

    /**
     * @description Trims leading and trailing spaces from a string value.
     * @param value The string value to trim.
     * @return The trimmed value or null when input is null.
     */
    private static String trimValue(String value) {
        if (value == null) {
            return null;
        }
        return value.trim();
    }
}
