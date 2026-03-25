trigger ContactNormalizeTrigger_29 on Contact (before insert, before update) {
    ContactNormalizeTriggerHandler_29.normalizeContacts(Trigger.new);
}
