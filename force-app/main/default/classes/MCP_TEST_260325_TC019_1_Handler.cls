/**
 * @description Handler class for Contact trigger MCP_TEST_260325_TC019_1.
 */
public with sharing class MCP_TEST_260325_TC019_1_Handler {
    @TestVisible
    private static Set<String> recursionGuardKeys = new Set<String>();

    /**
     * @description Handles before insert events for Contact.
     * @param newContacts Contacts from Trigger.new.
     */
    public static void beforeInsert(List<Contact> newContacts) {
        if (newContacts == null || newContacts.isEmpty()) {
            return;
        }

        if (!enterGuard('beforeInsert')) {
            return;
        }

        try {
            // Placeholder for future before-insert business logic.
        } finally {
            exitGuard('beforeInsert');
        }
    }

    /**
     * @description Handles before update events for Contact.
     * @param newContacts Contacts from Trigger.new.
     * @param oldMap Contacts from Trigger.oldMap.
     */
    public static void beforeUpdate(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        if (newContacts == null || newContacts.isEmpty() || oldMap == null) {
            return;
        }

        if (!enterGuard('beforeUpdate')) {
            return;
        }

        try {
            // Placeholder for future before-update business logic.
        } finally {
            exitGuard('beforeUpdate');
        }
    }

    /**
     * @description Adds a context key to recursion guard if absent.
     * @param contextKey Context identifier for guard tracking.
     * @return True when processing should continue, false when recursion detected.
     */
    private static Boolean enterGuard(String contextKey) {
        if (recursionGuardKeys.contains(contextKey)) {
            return false;
        }
        recursionGuardKeys.add(contextKey);
        return true;
    }

    /**
     * @description Removes a context key from recursion guard.
     * @param contextKey Context identifier for guard tracking.
     */
    private static void exitGuard(String contextKey) {
        recursionGuardKeys.remove(contextKey);
    }
}
