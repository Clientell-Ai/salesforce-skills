trigger LeadPushFallbackFix26 on Lead (before insert, before update) {
    LeadPushFallbackFix26Handler.handleBeforeInsertUpdate(Trigger.new);
}
