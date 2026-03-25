trigger LeadEdgeTrimZ2 on Lead (before insert, before update) {
    LeadEdgeTrimZ2Handler.normalize(Trigger.new);
}
