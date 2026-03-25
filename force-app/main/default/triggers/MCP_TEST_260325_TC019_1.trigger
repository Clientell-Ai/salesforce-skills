trigger MCP_TEST_260325_TC019_1 on Contact (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            MCP_TEST_260325_TC019_1_Handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            MCP_TEST_260325_TC019_1_Handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
