trigger LeadNormalizationTrigger on Lead (before insert, before update) {
    LeadNormalizationHandler.normalize(Trigger.new);
}
