trigger ContactNormalizeTrigger_19 on Contact (before insert, before update) {
    ContactNormalizeTriggerHandler_19.handle(Trigger.new);
}
