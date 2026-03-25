/**
 * @description Normalizes Contact name and email fields after DML events.
 */
public with sharing class PromotionTestingContactNormalizeHandler {
    private static Boolean isExecuting = false;

    /**
     * @description Handles after-insert and after-update trigger contexts for Contact normalization.
     * @param newContacts Contacts from Trigger.new.
     */
    public static void handleAfter(List<Contact> newContacts) {
        if (isExecuting || newContacts == null || newContacts.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Contact.isUpdateable()
            || !Schema.sObjectType.Contact.fields.FirstName.isUpdateable()
            || !Schema.sObjectType.Contact.fields.LastName.isUpdateable()
            || !Schema.sObjectType.Contact.fields.Email.isUpdateable()) {
            return;
        }

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact sourceContact : newContacts) {
            String normalizedFirstName = sourceContact.FirstName;
            String normalizedLastName = sourceContact.LastName;
            String normalizedEmail = sourceContact.Email;

            if (normalizedFirstName != null) {
                normalizedFirstName = normalizedFirstName.trim();
            }
            if (normalizedLastName != null) {
                normalizedLastName = normalizedLastName.trim();
            }
            if (normalizedEmail != null) {
                normalizedEmail = normalizedEmail.toLowerCase();
            }

            Boolean firstChanged = normalizedFirstName != sourceContact.FirstName;
            Boolean lastChanged = normalizedLastName != sourceContact.LastName;
            Boolean emailChanged = normalizedEmail != sourceContact.Email;

            if (firstChanged || lastChanged || emailChanged) {
                contactsToUpdate.add(new Contact(
                    Id = sourceContact.Id,
                    FirstName = normalizedFirstName,
                    LastName = normalizedLastName,
                    Email = normalizedEmail
                ));
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            isExecuting = true;
            try {
                Database.update(contactsToUpdate, AccessLevel.USER_MODE);
            } catch (DmlException ex) {
                System.debug(LoggingLevel.ERROR,
                    'Contact normalization failed: ' + ex.getMessage());
                throw ex;
            } finally {
                isExecuting = false;
            }
        }
    }
}
