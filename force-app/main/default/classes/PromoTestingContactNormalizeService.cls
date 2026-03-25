/**
 * @description Normalizes Contact name and email values in after-trigger contexts.
 */
public with sharing class PromoTestingContactNormalizeService {
    private static Boolean isProcessing = false;

    /**
     * @description Normalizes Contact fields after insert/update and updates only changed rows.
     * @param newList Trigger.new records.
     * @param oldMap Trigger.oldMap records for update context, null for insert context.
     */
    public static void normalizeAfter(List<Contact> newList, Map<Id, Contact> oldMap) {
        if (isProcessing || newList == null || newList.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Contact.isUpdateable()
            || !Schema.sObjectType.Contact.fields.FirstName.isUpdateable()
            || !Schema.sObjectType.Contact.fields.LastName.isUpdateable()
            || !Schema.sObjectType.Contact.fields.Email.isUpdateable()) {
            return;
        }

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact currentContact : newList) {
            String normalizedFirstName = currentContact.FirstName == null
                ? null
                : currentContact.FirstName.trim();
            String normalizedLastName = currentContact.LastName == null
                ? null
                : currentContact.LastName.trim();
            String normalizedEmail = currentContact.Email == null
                ? null
                : currentContact.Email.toUpperCase();

            Contact oldContact = oldMap == null ? null : oldMap.get(currentContact.Id);

            Boolean hasChanges = normalizedFirstName != currentContact.FirstName
                || normalizedLastName != currentContact.LastName
                || normalizedEmail != currentContact.Email;

            if (oldContact != null) {
                hasChanges = hasChanges
                    || normalizedFirstName != oldContact.FirstName
                    || normalizedLastName != oldContact.LastName
                    || normalizedEmail != oldContact.Email;
            }

            if (hasChanges) {
                contactsToUpdate.add(new Contact(
                    Id = currentContact.Id,
                    FirstName = normalizedFirstName,
                    LastName = normalizedLastName,
                    Email = normalizedEmail
                ));
            }
        }

        if (contactsToUpdate.isEmpty()) {
            return;
        }

        isProcessing = true;
        try {
            Database.update(contactsToUpdate, AccessLevel.USER_MODE);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Contact normalization failed: ' + ex.getMessage());
            throw ex;
        } finally {
            isProcessing = false;
        }
    }
}
