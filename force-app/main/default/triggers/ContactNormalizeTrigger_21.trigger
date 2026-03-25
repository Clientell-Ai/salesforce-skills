trigger ContactNormalizeTrigger_21 on Contact (before insert, before update) {
    ContactNormalizeTriggerHandler.handleBefore(Trigger.new);
}
