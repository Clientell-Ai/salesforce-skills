trigger VendorSanitizeTrigger_X91 on Lead (before insert, before update) {
    for (Lead leadRecord : Trigger.new) {
        leadRecord.Company = leadRecord.Company == null ? null : leadRecord.Company.trim();
    }
}
