trigger LeadNormalizeTrigger_31 on Lead (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        if (!LeadNormalizeService_31.isInProgress()) {
            LeadNormalizeService_31.setInProgress(true);
            try {
                LeadNormalizeService_31.normalize(Trigger.new);
            } finally {
                LeadNormalizeService_31.setInProgress(false);
            }
        }
    }
}
