trigger MCP_TEST_LeadNormalizeTrigger on Lead (before insert, before update) {
    MCP_TEST_LeadNormalizeHandler.normalize(Trigger.new);
}
