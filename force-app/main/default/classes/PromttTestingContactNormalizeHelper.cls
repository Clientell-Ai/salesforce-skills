/**
 * @description README: Normalizes Contact FirstName/LastName/Email in after insert/update contexts.
 * It trims leading/trailing whitespace for first/last names and trims + lowercases email,
 * then performs a minimal update only for records that actually need normalization.
 * Includes a static recursion guard to avoid re-entry from the helper's own DML.
 */
public with sharing class PromttTestingContactNormalizeHelper {
    private static Boolean isRunning = false;

    /**
     * @description Normalizes Contact name/email fields after insert or update using minimal DML.
     * @param newList Trigger.new list.
     * @param oldMap Trigger.oldMap (null on insert).
     */
    public static void normalizeAfter(List<Contact> newList, Map<Id, Contact> oldMap) {
        if (isRunning || newList == null || newList.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Contact.isUpdateable()) {
            return;
        }

        Boolean canUpdateFirstName = Schema.sObjectType.Contact.fields.FirstName.isUpdateable();
        Boolean canUpdateLastName = Schema.sObjectType.Contact.fields.LastName.isUpdateable();
        Boolean canUpdateEmail = Schema.sObjectType.Contact.fields.Email.isUpdateable();

        if (!canUpdateFirstName && !canUpdateLastName && !canUpdateEmail) {
            return;
        }

        List<Contact> updates = new List<Contact>();

        for (Contact currentContact : newList) {
            if (currentContact.Id == null) {
                continue;
            }

            String normalizedFirstName = currentContact.FirstName == null ? null : currentContact.FirstName.trim();
            String normalizedLastName = currentContact.LastName == null ? null : currentContact.LastName.trim();
            String normalizedEmail = currentContact.Email == null ? null : currentContact.Email.trim().toLowerCase();

            Contact oldContact = oldMap == null ? null : oldMap.get(currentContact.Id);
            if (
                oldContact != null &&
                normalizedFirstName == oldContact.FirstName &&
                normalizedLastName == oldContact.LastName &&
                normalizedEmail == oldContact.Email
            ) {
                continue;
            }

            Contact updateContact = new Contact(Id = currentContact.Id);
            Boolean hasChanges = false;

            if (canUpdateFirstName && normalizedFirstName != currentContact.FirstName) {
                updateContact.FirstName = normalizedFirstName;
                hasChanges = true;
            }
            if (canUpdateLastName && normalizedLastName != currentContact.LastName) {
                updateContact.LastName = normalizedLastName;
                hasChanges = true;
            }
            if (canUpdateEmail && normalizedEmail != currentContact.Email) {
                updateContact.Email = normalizedEmail;
                hasChanges = true;
            }

            if (hasChanges) {
                updates.add(updateContact);
            }
        }

        if (updates.isEmpty()) {
            return;
        }

        isRunning = true;
        try {
            Database.update(updates, AccessLevel.USER_MODE);
        } catch (Exception ex) {
            throw new DmlException('Failed to normalize Contact fields: ' + ex.getMessage());
        } finally {
            isRunning = false;
        }
    }
}
