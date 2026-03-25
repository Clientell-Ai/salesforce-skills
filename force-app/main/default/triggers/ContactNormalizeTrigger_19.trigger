trigger ContactNormalizeTrigger_19 on Contact (before insert, before update) {
    ContactNormalizeUtil_19.normalizeContacts(Trigger.new);
}
