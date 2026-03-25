trigger LeadRegionSanitizeRun26 on Lead (before insert, before update) {
    LeadRegionSanitizeRun26Handler.sanitizeLeads(Trigger.new);
}
