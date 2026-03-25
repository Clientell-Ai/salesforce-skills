/**
 * @description Normalizes Contact text and phone fields in before-trigger context.
 */
public with sharing class ContactNormalizeTriggerHandler_19 {
    private static final List<String> TEXT_FIELDS = new List<String>{
        'FirstName',
        'LastName',
        'Title',
        'Department',
        'MailingStreet',
        'MailingCity',
        'MailingState',
        'MailingPostalCode',
        'MailingCountry'
    };

    private static final List<String> PHONE_FIELDS = new List<String>{
        'Phone',
        'MobilePhone',
        'HomePhone',
        'OtherPhone',
        'Fax'
    };

    /**
     * @description Normalizes configured Contact fields without performing DML.
     * @param newList Trigger.new records to normalize in place.
     */
    public static void handle(List<Contact> newList) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        for (Contact con : newList) {
            normalizeTextFields(con);
            normalizeEmail(con);
            normalizePhoneFields(con);
        }
    }

    private static void normalizeTextFields(Contact con) {
        for (String fieldName : TEXT_FIELDS) {
            String value = (String) con.get(fieldName);
            if (value != null) {
                con.put(fieldName, value.trim());
            }
        }
    }

    private static void normalizeEmail(Contact con) {
        if (con.Email != null) {
            con.Email = con.Email.trim().toLowerCase();
        }
    }

    private static void normalizePhoneFields(Contact con) {
        for (String fieldName : PHONE_FIELDS) {
            String value = (String) con.get(fieldName);
            if (value != null) {
                con.put(fieldName, normalizePhone(value));
            }
        }
    }

    private static String normalizePhone(String rawValue) {
        String trimmed = rawValue.trim();
        if (Pattern.matches('^\\+?\\d+$', trimmed)) {
            return trimmed;
        }

        Boolean hadLeadingPlus = trimmed.startsWith('+');
        String normalized = trimmed.replaceAll('[\\s().-]', '');
        normalized = normalized.replaceAll('\\+', '');

        if (hadLeadingPlus) {
            return '+' + normalized;
        }
        return normalized;
    }
}
