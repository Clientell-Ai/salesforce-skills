/**
 * @description Handles Contact field normalization for before-insert and before-update trigger events.
 */
public with sharing class ContactNormalizeTriggerHandler_09 {
    /**
     * @description Normalizes key Contact fields in-memory without SOQL or DML.
     * @param newList Trigger.new records to normalize.
     */
    public static void normalize(List<Contact> newList) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        for (Contact con : newList) {
            if (con == null) {
                continue;
            }

            con.Email = normalizeEmail(con.Email);
            con.Phone = normalizePhone(con.Phone);
            con.MobilePhone = normalizePhone(con.MobilePhone);
            con.FirstName = normalizeName(con.FirstName);
            con.LastName = normalizeName(con.LastName);
        }
    }

    /**
     * @description Trims and lowercases an email value.
     * @param value Raw email.
     * @return Normalized email or null.
     */
    private static String normalizeEmail(String value) {
        if (value == null) {
            return null;
        }
        return value.trim().toLowerCase();
    }

    /**
     * @description Trims and collapses internal whitespace to a single space.
     * @param value Raw name value.
     * @return Normalized name or null.
     */
    private static String normalizeName(String value) {
        if (value == null) {
            return null;
        }
        return value.trim().replaceAll('\\s+', ' ');
    }

    /**
     * @description Removes non-digits while preserving a leading plus sign if present.
     * @param value Raw phone value.
     * @return Normalized phone or null.
     */
    private static String normalizePhone(String value) {
        if (value == null) {
            return null;
        }

        String trimmed = value.trim();
        Boolean hasLeadingPlus = trimmed.startsWith('+');
        String digitsOnly = trimmed.replaceAll('[^0-9]', '');

        if (hasLeadingPlus) {
            return '+' + digitsOnly;
        }

        return digitsOnly;
    }
}
