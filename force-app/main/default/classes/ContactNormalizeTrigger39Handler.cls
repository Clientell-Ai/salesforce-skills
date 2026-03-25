/**
 * @description Handler for ContactNormalizeTrigger_39. Normalizes Contact name and email fields.
 */
public with sharing class ContactNormalizeTrigger39Handler {
    private static Boolean isExecuting = false;

    /**
     * @description Normalizes Contact fields for before insert and before update operations.
     * @param records Trigger.new records to normalize.
     */
    public static void handle(List<Contact> records) {
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
