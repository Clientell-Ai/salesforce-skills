trigger TestContactNormalizeTrigger on Contact (before insert, before update) {
    for (Contact contactRecord : Trigger.new) {
        if (contactRecord.Email != null) {
            contactRecord.Email = contactRecord.Email.trim().toLowerCase();
        }
    }
}
