trigger MCP_TEST_260325_TC019_1 on Contact (before insert, before update) {
    MCP_TEST_260325_TC019_1_Handler.handle(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isInsert, Trigger.isUpdate);
}
