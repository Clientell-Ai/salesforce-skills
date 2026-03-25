/**
 * @description Utility methods to normalize Contact name, email, and phone fields in bulk.
 */
public with sharing class ContactNormalizeUtil_29 {
    /**
     * @description Normalizes key fields on incoming Contact records.
     * @param contacts The contacts to normalize.
     */
    public static void normalizeContacts(List<Contact> contacts) {
        if (contacts == null || contacts.isEmpty()) {
            return;
        }

        for (Contact con : contacts) {
            if (con == null) {
                continue;
            }

            con.FirstName = trimIfNotBlank(con.FirstName);
            con.LastName = trimIfNotBlank(con.LastName);
            con.Email = normalizeEmail(con.Email);
            con.Phone = normalizePhone(con.Phone);
            con.MobilePhone = normalizePhone(con.MobilePhone);
        }
    }

    /**
     * @description Trims leading and trailing whitespace when value is not blank.
     * @param value Input value.
     * @return Trimmed value or original value when null/blank.
     */
    public static String trimIfNotBlank(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.trim();
    }

    /**
     * @description Trims and lowercases email when value is not blank.
     * @param email Input email.
     * @return Normalized email or original value when null/blank.
     */
    public static String normalizeEmail(String email) {
        if (String.isBlank(email)) {
            return email;
        }
        return email.trim().toLowerCase();
    }

    /**
     * @description Normalizes phone text to US display format when 10/11 digits, else digits-only.
     * @param phone Input phone value.
     * @return Normalized phone or original value when null/blank.
     */
    public static String normalizePhone(String phone) {
        if (String.isBlank(phone)) {
            return phone;
        }

        String digitsOnly = phone.trim().replaceAll('[^0-9]', '');

        if (digitsOnly.length() == 10) {
            return '(' + digitsOnly.substring(0, 3) + ') ' + digitsOnly.substring(3, 6) + '-' + digitsOnly.substring(6, 10);
        }

        if (digitsOnly.length() == 11 && digitsOnly.startsWith('1')) {
            return '+1 (' + digitsOnly.substring(1, 4) + ') ' + digitsOnly.substring(4, 7) + '-' + digitsOnly.substring(7, 11);
        }

        return digitsOnly;
    }
}
