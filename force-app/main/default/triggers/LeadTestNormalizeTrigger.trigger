trigger LeadTestNormalizeTrigger on Lead (before insert, before update) {
    LeadTestNormalizeTriggerHandler.normalize(
        Trigger.new,
        Trigger.oldMap,
        Trigger.isInsert,
        Trigger.isUpdate
    );
}
