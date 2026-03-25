trigger ContactNormalizeTrigger_09 on Contact (before insert, before update) {
    ContactNormalizeTriggerHandler_09.normalize(Trigger.new);
}
