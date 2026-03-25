/**
 * @description Handler for trigger MCP_TEST_260325_TC019_1 on Contact.
 */
public with sharing class MCP_TEST_260325_TC019_1_Handler {
    private static Boolean isExecuting = false;

    /**
     * @description Entry point for trigger context handling.
     * @param newRecords The Trigger.new records.
     * @param oldMapRecords The Trigger.oldMap records.
     * @param isBeforeContext True when running in before context.
     * @param isInsertContext True when running in insert context.
     * @param isUpdateContext True when running in update context.
     */
    public static void handle(
        List<Contact> newRecords,
        Map<Id, Contact> oldMapRecords,
        Boolean isBeforeContext,
        Boolean isInsertContext,
        Boolean isUpdateContext
    ) {
        if (isExecuting) {
            return;
        }

        isExecuting = true;
        try {
            if (isBeforeContext && isInsertContext) {
                beforeInsert(newRecords);
            }
            if (isBeforeContext && isUpdateContext) {
                beforeUpdate(newRecords, oldMapRecords);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'MCP_TEST_260325_TC019_1_Handler error: ' + ex.getMessage());
            throw ex;
        } finally {
            isExecuting = false;
        }
    }

    /**
     * @description Handles before insert logic for Contact.
     * @param newRecords Contacts in Trigger.new.
     */
    private static void beforeInsert(List<Contact> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Contact con : newRecords) {
            // Bulk-safe skeleton: iterate records without SOQL or DML.
            con.Description = con.Description;
        }
    }

    /**
     * @description Handles before update logic for Contact.
     * @param newRecords Contacts in Trigger.new.
     * @param oldMapRecords Contacts in Trigger.oldMap.
     */
    private static void beforeUpdate(List<Contact> newRecords, Map<Id, Contact> oldMapRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Contact con : newRecords) {
            Contact oldCon = oldMapRecords != null ? oldMapRecords.get(con.Id) : null;
            if (oldCon != null) {
                // Bulk-safe skeleton: iterate records without SOQL or DML.
                con.Description = con.Description;
            }
        }
    }
}
