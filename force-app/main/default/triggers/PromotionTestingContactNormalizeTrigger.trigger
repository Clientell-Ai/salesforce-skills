trigger PromotionTestingContactNormalizeTrigger on Contact (after insert, after update) {
    PromotionTestingContactNormalizeHelper.normalizeContacts(Trigger.new);
}
