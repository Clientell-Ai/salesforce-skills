trigger LeadNormalizeTrigger_41 on Lead (before insert, before update) {
    LeadNormalizeTriggerHandler_41.handleBefore(Trigger.new);
}
