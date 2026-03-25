trigger PromttTestingContactNormalizeTrigger on Contact (after insert, after update) {
    PromttTestingContactNormalizeHelper.normalizeAfter(Trigger.new, Trigger.oldMap);
}
