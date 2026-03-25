/**
 * @description Handler for ContactNormalizeTrigger_29 normalization logic.
 */
public with sharing class ContactNormalizeTriggerHandler_29 {

    /**
     * @description Normalizes Contact fields in bulk for before-insert and before-update contexts.
     * @param contacts Incoming trigger context records.
     */
    public static void normalizeContacts(List<Contact> contacts) {
        if (contacts == null || contacts.isEmpty()) {
            return;
        }

        for (Contact contactRecord : contacts) {
            if (contactRecord == null) {
                continue;
            }

            String normalizedEmail = normalizeEmail(contactRecord.Email);
            if (normalizedEmail != contactRecord.Email) {
                contactRecord.Email = normalizedEmail;
            }

            String normalizedPhone = normalizePhone(contactRecord.Phone);
            if (normalizedPhone != contactRecord.Phone) {
                contactRecord.Phone = normalizedPhone;
            }

            String normalizedFirstName = normalizeName(contactRecord.FirstName);
            if (normalizedFirstName != contactRecord.FirstName) {
                contactRecord.FirstName = normalizedFirstName;
            }

            String normalizedLastName = normalizeName(contactRecord.LastName);
            if (normalizedLastName != contactRecord.LastName) {
                contactRecord.LastName = normalizedLastName;
            }

            String normalizedMailingStreet = normalizeWhitespace(contactRecord.MailingStreet);
            if (normalizedMailingStreet != contactRecord.MailingStreet) {
                contactRecord.MailingStreet = normalizedMailingStreet;
            }
        }
    }

    /**
     * @description Trims and lowercases email values.
     * @param emailValue Raw email value.
     * @return Normalized email value.
     */
    public static String normalizeEmail(String emailValue) {
        String cleaned = normalizeWhitespace(emailValue);
        return cleaned == null ? null : cleaned.toLowerCase();
    }

    /**
     * @description Normalizes phone values by removing non-digits, handling leading country code 1, and formatting 10-digit values.
     * @param phoneValue Raw phone value.
     * @return Normalized phone value.
     */
    public static String normalizePhone(String phoneValue) {
        if (phoneValue == null) {
            return null;
        }

        String digitsOnly = phoneValue.replaceAll('[^0-9]', '');
        if (String.isBlank(digitsOnly)) {
            return '';
        }

        if (digitsOnly.length() == 11 && digitsOnly.startsWith('1')) {
            digitsOnly = digitsOnly.substring(1);
        }

        if (digitsOnly.length() == 10) {
            return '(' + digitsOnly.substring(0, 3) + ') ' + digitsOnly.substring(3, 6) + '-' + digitsOnly.substring(6, 10);
        }

        return digitsOnly;
    }

    /**
     * @description Trims, collapses spaces, and proper-cases each word for name fields.
     * @param rawName Raw name value.
     * @return Normalized name value.
     */
    public static String normalizeName(String rawName) {
        String collapsed = normalizeWhitespace(rawName);
        if (collapsed == null) {
            return null;
        }
        if (collapsed == '') {
            return '';
        }

        List<String> words = collapsed.split(' ');
        List<String> normalizedWords = new List<String>();
        for (String word : words) {
            if (word == null || word == '') {
                continue;
            }
            normalizedWords.add(word.substring(0, 1).toUpperCase() + (word.length() > 1 ? word.substring(1).toLowerCase() : ''));
        }
        return String.join(normalizedWords, ' ');
    }

    /**
     * @description Trims and collapses multiple whitespace characters to a single space.
     * @param rawValue Input string.
     * @return Normalized whitespace string.
     */
    public static String normalizeWhitespace(String rawValue) {
        if (rawValue == null) {
            return null;
        }
        return rawValue.trim().replaceAll('\\s+', ' ');
    }
}
