/**
 * @description Base trigger handler providing context dispatch and recursion control.
 */
public with sharing virtual class TriggerHandlerBase {
    private static Set<String> executedKeys = new Set<String>();

    /**
     * @description Runs the current handler only once per trigger context key.
     */
    public void run() {
        String contextKey = getHandlerName() + ':' + Trigger.operationType.name();
        if (executedKeys.contains(contextKey)) {
            return;
        }
        executedKeys.add(contextKey);

        if (Trigger.isBefore && Trigger.isInsert) {
            beforeInsert(Trigger.new);
            return;
        }
        if (Trigger.isBefore && Trigger.isUpdate) {
            beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    /**
     * @description Returns a stable handler name for recursion keying.
     * @return Handler name.
     */
    protected virtual String getHandlerName() {
        return 'TriggerHandlerBase';
    }

    /**
     * @description Hook for before insert behavior.
     * @param newRecords Trigger new records.
     */
    protected virtual void beforeInsert(List<SObject> newRecords) {
    }

    /**
     * @description Hook for before update behavior.
     * @param newRecords Trigger new records.
     * @param oldMap Trigger old map.
     */
    protected virtual void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
    }
}
