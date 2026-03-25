trigger LeadNormalizeTrigger_31 on Lead (before insert, before update) {
    LeadNormalizeTriggerHandler_31.handleBeforeInsertUpdate(Trigger.new);
}
