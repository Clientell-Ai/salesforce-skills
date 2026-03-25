trigger PromoTestingContactNormalizeTrigger on Contact (after insert, after update) {
    PromoTestingContactNormalizeService.normalizeAfter(
        Trigger.new,
        Trigger.isUpdate ? Trigger.oldMap : null
    );
}
