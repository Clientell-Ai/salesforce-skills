/**
 * @description Normalizes Contact email and phone fields for before insert and before update trigger events.
 */
public with sharing class ContactNormalizeTriggerHandler_09 {
    private static final List<String> PHONE_FIELDS = new List<String>{
        'Phone',
        'MobilePhone',
        'HomePhone',
        'OtherPhone',
        'AssistantPhone',
        'Fax'
    };

    /**
     * @description Normalizes email and phone values on Contact records.
     * @param contacts Trigger.new Contact records.
     */
    public static void handleBeforeInsertUpdate(List<Contact> contacts) {
        if (contacts == null || contacts.isEmpty()) {
            return;
        }

        for (Contact contactRecord : contacts) {
            contactRecord.Email = normalizeEmail(contactRecord.Email);

            for (String fieldApiName : PHONE_FIELDS) {
                String rawValue = (String) contactRecord.get(fieldApiName);
                contactRecord.put(fieldApiName, normalizePhone(rawValue));
            }
        }
    }

    private static String normalizeEmail(String emailValue) {
        if (String.isBlank(emailValue)) {
            return emailValue;
        }
        return emailValue.trim().toLowerCase();
    }

    private static String normalizePhone(String phoneValue) {
        if (String.isBlank(phoneValue)) {
            return phoneValue;
        }

        String trimmedValue = phoneValue.trim();
        Boolean hasLeadingPlus = trimmedValue.startsWith('+');

        String valueToNormalize = hasLeadingPlus
            ? trimmedValue.substring(1)
            : trimmedValue;

        String digitsOnly = valueToNormalize.replaceAll('[^0-9]', '');
        if (String.isBlank(digitsOnly)) {
            return null;
        }

        return hasLeadingPlus ? '+' + digitsOnly : digitsOnly;
    }
}
