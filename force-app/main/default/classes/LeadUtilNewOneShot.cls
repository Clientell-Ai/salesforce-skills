/**
 * @description Utility methods for Lead normalization without DML.
 */
public with sharing class LeadUtilNewOneShot {

    /**
     * @description Normalizes common Lead fields (trim, lowercase email, normalize phone).
     * Safe for null input and does not perform DML.
     * @param leadRecord The Lead record to normalize.
     * @return The normalized Lead record, or null if input is null.
     */
    public static Lead normalize(Lead leadRecord) {
        if (leadRecord == null) {
            return null;
        }

        leadRecord.FirstName = normalizeString(leadRecord.FirstName);
        leadRecord.LastName = normalizeString(leadRecord.LastName);
        leadRecord.Company = normalizeString(leadRecord.Company);
        leadRecord.Title = normalizeString(leadRecord.Title);
        leadRecord.Email = normalizeEmail(leadRecord.Email);
        leadRecord.Phone = normalizePhone(leadRecord.Phone);
        leadRecord.MobilePhone = normalizePhone(leadRecord.MobilePhone);

        return leadRecord;
    }

    private static String normalizeString(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.trim();
    }

    private static String normalizeEmail(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.trim().toLowerCase();
    }

    private static String normalizePhone(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        String digits = '';
        for (Integer i = 0; i < value.length(); i++) {
            String ch = value.substring(i, i + 1);
            if (ch >= '0' && ch <= '9') {
                digits += ch;
            }
        }
        return digits;
    }
}
