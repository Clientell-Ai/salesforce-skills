/**
 * @description Utility methods to normalize Contact field values before DML.
 */
public with sharing class ContactNormalizeUtil_19 {
    /**
     * @description Normalizes a list of Contact records in memory.
     * @param contacts The contacts to normalize.
     */
    public static void normalizeContacts(List<Contact> contacts) {
        if (contacts == null || contacts.isEmpty()) {
            return;
        }

        for (Contact contactRecord : contacts) {
            normalizeContact(contactRecord);
        }
    }

    /**
     * @description Normalizes a single Contact record in memory.
     * @param contactRecord The contact to normalize.
     */
    public static void normalizeContact(Contact contactRecord) {
        if (contactRecord == null) {
            return;
        }

        contactRecord.FirstName = trimIfNotNull(contactRecord.FirstName);
        contactRecord.LastName = trimIfNotNull(contactRecord.LastName);
        contactRecord.Title = trimIfNotNull(contactRecord.Title);
        contactRecord.Department = trimIfNotNull(contactRecord.Department);

        String emailValue = trimIfNotNull(contactRecord.Email);
        contactRecord.Email = emailValue == null ? null : emailValue.toLowerCase();

        contactRecord.Phone = normalizePhone(contactRecord.Phone);
        contactRecord.MobilePhone = normalizePhone(contactRecord.MobilePhone);
        contactRecord.MailingStreet = normalizeStreet(contactRecord.MailingStreet);
    }

    /**
     * @description Trims leading and trailing whitespace if the value is not null.
     * @param value Input text.
     * @return Trimmed text, or null when input is null.
     */
    public static String trimIfNotNull(String value) {
        return value == null ? null : value.trim();
    }

    /**
     * @description Normalizes US-style phone values based on digit count.
     * @param value Input phone value.
     * @return Formatted number for 10 digits; otherwise digits-only, or null for null input.
     */
    public static String normalizePhone(String value) {
        if (value == null) {
            return null;
        }

        String digitsOnly = value.replaceAll('[^0-9]', '');
        if (digitsOnly.length() == 11 && digitsOnly.startsWith('1')) {
            digitsOnly = digitsOnly.substring(1);
        }

        if (digitsOnly.length() == 10) {
            return '(' + digitsOnly.substring(0, 3) + ') ' + digitsOnly.substring(3, 6) + '-' + digitsOnly.substring(6, 10);
        }

        return digitsOnly;
    }

    /**
     * @description Trims street value and collapses internal whitespace runs to a single space.
     * @param value Input street.
     * @return Normalized street, or null when input is null.
     */
    public static String normalizeStreet(String value) {
        if (value == null) {
            return null;
        }

        return value.trim().replaceAll('\\s+', ' ');
    }
}
