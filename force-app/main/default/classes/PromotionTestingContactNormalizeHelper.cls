/**
 * @description Normalizes Contact names and email after insert/update and prevents recursion.
 */
public with sharing class PromotionTestingContactNormalizeHelper {
    private static Boolean isInProgress = false;

    /**
     * @description Normalizes FirstName/LastName (trim) and Email (lowercase), then updates only changed records.
     * @param triggerContacts Contacts from Trigger.new.
     */
    public static void normalizeContacts(List<Contact> triggerContacts) {
        if (isInProgress || triggerContacts == null || triggerContacts.isEmpty()) {
            return;
        }

        isInProgress = true;
        try {
            List<Contact> contactsToUpdate = new List<Contact>();

            for (Contact recordContact : triggerContacts) {
                String normalizedFirstName = normalizeTrimmed(recordContact.FirstName);
                String normalizedLastName = normalizeTrimmed(recordContact.LastName);
                String normalizedEmail = normalizeLower(recordContact.Email);

                Boolean shouldUpdate =
                    normalizedFirstName != recordContact.FirstName ||
                    normalizedLastName != recordContact.LastName ||
                    normalizedEmail != recordContact.Email;

                if (shouldUpdate) {
                    contactsToUpdate.add(new Contact(
                        Id = recordContact.Id,
                        FirstName = normalizedFirstName,
                        LastName = normalizedLastName,
                        Email = normalizedEmail
                    ));
                }
            }

            if (!contactsToUpdate.isEmpty()) {
                List<Database.SaveResult> saveResults = Database.update(contactsToUpdate, false);
                for (Integer indexPosition = 0; indexPosition < saveResults.size(); indexPosition++) {
                    if (!saveResults[indexPosition].isSuccess()) {
                        for (Database.Error saveError : saveResults[indexPosition].getErrors()) {
                            System.debug(
                                LoggingLevel.ERROR,
                                'Failed to normalize Contact ' + contactsToUpdate[indexPosition].Id + ': ' + saveError.getMessage()
                            );
                        }
                    }
                }
            }
        } finally {
            isInProgress = false;
        }
    }

    /**
     * @description Trims a string; returns null when input is null.
     * @param inputValue Source string.
     * @return Trimmed string or null.
     */
    private static String normalizeTrimmed(String inputValue) {
        return inputValue == null ? null : inputValue.trim();
    }

    /**
     * @description Converts a string to lowercase; returns null when input is null.
     * @param inputValue Source string.
     * @return Lowercase string or null.
     */
    private static String normalizeLower(String inputValue) {
        return inputValue == null ? null : inputValue.toLowerCase();
    }
}
