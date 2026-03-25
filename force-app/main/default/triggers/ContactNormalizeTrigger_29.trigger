trigger ContactNormalizeTrigger_29 on Contact (before insert, before update) {
    ContactNormalizeUtil_29.normalizeContacts(Trigger.new);
}
