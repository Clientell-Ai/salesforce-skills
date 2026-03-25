trigger VendorSampleSanitizeTriggerLocal2 on Lead (before insert, before update) {
    VendorSampleSanitizeTriggerLocal2Handler.sanitizeLeads(Trigger.new);
}
