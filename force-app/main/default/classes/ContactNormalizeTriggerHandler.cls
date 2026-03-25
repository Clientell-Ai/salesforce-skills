/**
 * @description Normalizes Contact name and email fields for before insert and before update events.
 */
public with sharing class ContactNormalizeTriggerHandler {
    private static Boolean isExecuting = false;

    /**
     * @description Normalizes FirstName, LastName, and Email values in bulk.
     * @param records Contact records from Trigger.new.
     */
    public static void handleBefore(List<Contact> records) {
        if (isExecuting || records == null || records.isEmpty()) {
            return;
        }

        isExecuting = true;
        try {
            for (Contact con : records) {
                if (con.FirstName != null) {
                    con.FirstName = con.FirstName.trim();
                }
                if (con.LastName != null) {
                    con.LastName = con.LastName.trim();
                }
                if (con.Email != null) {
                    con.Email = con.Email.trim().toLowerCase();
                }
            }
        } finally {
            isExecuting = false;
        }
    }
}
