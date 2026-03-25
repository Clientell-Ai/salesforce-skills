/*
 * Purpose: Delegates Lead email normalization for before insert and before update events.
 */
trigger LeadNormalizeTrigger_21 on Lead (before insert, before update) {
    LeadNormalizeTriggerHandler_21.handle(
        Trigger.new,
        Trigger.oldMap,
        Trigger.isInsert,
        Trigger.isUpdate
    );
}
