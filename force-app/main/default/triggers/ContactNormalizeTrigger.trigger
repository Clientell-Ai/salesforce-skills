trigger ContactNormalizeTrigger on Contact (before insert, before update) {
    for (Contact recordItem : Trigger.new) {
        if (recordItem.FirstName != null) {
            recordItem.FirstName = recordItem.FirstName.trim();
        }
        if (recordItem.LastName != null) {
            recordItem.LastName = recordItem.LastName.trim();
        }
        if (recordItem.Email != null) {
            recordItem.Email = recordItem.Email.trim().toLowerCase();
        }
    }
}
