/**
 * @description Normalizes Lead name and email fields before insert and update.
 */
public with sharing class LeadNoGhFallback26Handler {
    /**
     * @description Trims FirstName/LastName and lowercases Email for each Lead in the transaction.
     * @param newList Trigger.new records from before insert/before update context.
     */
    public static void beforeInsertUpdate(List<Lead> newList) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        for (Lead leadRecord : newList) {
            if (leadRecord.FirstName != null) {
                leadRecord.FirstName = leadRecord.FirstName.trim();
            }
            if (leadRecord.LastName != null) {
                leadRecord.LastName = leadRecord.LastName.trim();
            }
            if (leadRecord.Email != null) {
                leadRecord.Email = leadRecord.Email.trim().toLowerCase();
            }
        }
    }
}
