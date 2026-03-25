trigger LeadSpaceTrimTriggerX on Lead (before insert, before update) {
    LeadSpaceTrimHandlerX.trimLeadFields(Trigger.new);
}
