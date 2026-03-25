/**
 * @description Normalizes Contact fields before insert and update.
 */
public with sharing class ContactNormalizeTrigger_39_Handler {
    /**
     * @description Executes normalization logic for Contacts.
     * @param newList Incoming records from Trigger.new.
     * @param oldMap Existing records from Trigger.oldMap.
     * @param isInsert True when the trigger context is before insert.
     * @param isUpdate True when the trigger context is before update.
     */
    public static void run(
        List<Contact> newList,
        Map<Id, Contact> oldMap,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        if (newList == null || newList.isEmpty() || (!isInsert && !isUpdate)) {
            return;
        }

        for (Contact con : newList) {
            if (con == null) {
                continue;
            }

            String normalizedEmail = normalizeEmail(con.Email);
            if (con.Email != normalizedEmail) {
                con.Email = normalizedEmail;
            }

            String normalizedPhone = normalizePhone(con.Phone);
            if (con.Phone != normalizedPhone) {
                con.Phone = normalizedPhone;
            }

            String normalizedFirstName = normalizeName(con.FirstName);
            if (con.FirstName != normalizedFirstName) {
                con.FirstName = normalizedFirstName;
            }

            String normalizedLastName = normalizeName(con.LastName);
            if (con.LastName != normalizedLastName) {
                con.LastName = normalizedLastName;
            }

            String normalizedStreet = normalizeStreet(con.MailingStreet);
            if (con.MailingStreet != normalizedStreet) {
                con.MailingStreet = normalizedStreet;
            }
        }
    }

    private static String normalizeEmail(String emailValue) {
        String normalized = cleanWhitespace(emailValue);
        return normalized == null ? null : normalized.toLowerCase();
    }

    private static String normalizePhone(String phoneValue) {
        if (phoneValue == null) {
            return null;
        }

        String digitsOnly = phoneValue.replaceAll('[^0-9]', '');
        if (String.isBlank(digitsOnly)) {
            return null;
        }

        if (digitsOnly.length() == 10) {
            return '(' + digitsOnly.substring(0, 3) + ') ' + digitsOnly.substring(3, 6) + '-' + digitsOnly.substring(6, 10);
        }
        if (digitsOnly.length() == 11 && digitsOnly.startsWith('1')) {
            return '+1 (' + digitsOnly.substring(1, 4) + ') ' + digitsOnly.substring(4, 7) + '-' + digitsOnly.substring(7, 11);
        }
        return digitsOnly;
    }

    private static String normalizeName(String nameValue) {
        String normalized = cleanWhitespace(nameValue);
        if (normalized == null) {
            return null;
        }

        String lower = normalized.toLowerCase();
        String result = '';
        Boolean capitalizeNext = true;

        for (Integer i = 0; i < lower.length(); i++) {
            String ch = lower.substring(i, i + 1);
            if (capitalizeNext && ch >= 'a' && ch <= 'z') {
                result += ch.toUpperCase();
                capitalizeNext = false;
            } else {
                result += ch;
                capitalizeNext = (ch == ' ' || ch == '-' || ch == '\'');
            }
        }
        return result;
    }

    private static String normalizeStreet(String streetValue) {
        return cleanWhitespace(streetValue);
    }

    private static String cleanWhitespace(String inputValue) {
        if (inputValue == null) {
            return null;
        }
        String trimmed = inputValue.trim();
        if (trimmed == '') {
            return null;
        }
        return trimmed.replaceAll('\\s+', ' ');
    }
}
