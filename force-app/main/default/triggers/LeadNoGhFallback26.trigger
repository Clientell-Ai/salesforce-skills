trigger LeadNoGhFallback26 on Lead (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        LeadNoGhFallback26Handler.beforeInsertUpdate(Trigger.new);
    }
}
