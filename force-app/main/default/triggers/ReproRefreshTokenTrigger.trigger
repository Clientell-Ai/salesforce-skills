trigger ReproRefreshTokenTrigger on Lead (before insert, before update) {
    for (Lead leadRecord : Trigger.new) {
        if (leadRecord.FirstName != null) {
            leadRecord.FirstName = leadRecord.FirstName.trim();
        }
        if (leadRecord.LastName != null) {
            leadRecord.LastName = leadRecord.LastName.trim();
        }
        if (leadRecord.Company != null) {
            leadRecord.Company = leadRecord.Company.trim();
        }
    }
}
