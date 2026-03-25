trigger PromotionTestingContactNormalizeTrigger on Contact (after insert, after update) {
    PromotionTestingContactNormalizeHandler.handleAfter(Trigger.new);
}
