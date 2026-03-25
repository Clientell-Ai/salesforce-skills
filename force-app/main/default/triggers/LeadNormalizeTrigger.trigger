/**
 * @description Trigger to normalize Lead fields before insert and before update.
 */
trigger LeadNormalizeTrigger on Lead (before insert, before update) {
    if (LeadNormalizeTriggerHandler.isRunning) {
        return;
    }
    LeadNormalizeTriggerHandler.isRunning = true;
    try {
        for (Lead l : Trigger.new) {
            l.Email = LeadNormalizeUtil.normalizeEmail(l.Email);
            l.Phone = LeadNormalizeUtil.normalizePhone(l.Phone);
            l.Company = LeadNormalizeUtil.normalizeCompany(l.Company);
            l.FirstName = LeadNormalizeUtil.normalizeFirstName(l.FirstName);
            l.LastName = LeadNormalizeUtil.normalizeLastName(l.LastName);
        }
    } finally {
        LeadNormalizeTriggerHandler.isRunning = false;
    }
}