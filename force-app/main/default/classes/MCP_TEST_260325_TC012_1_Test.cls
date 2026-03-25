/**
 * @description Test class for MCP_TEST_260325_TC012_1.
 * @created 2026-03-25
 */
@IsTest
public with sharing class MCP_TEST_260325_TC012_1_Test {
    /**
     * @description Verifies ping returns OK.
     */
    @IsTest
    static void testPingReturnsOk() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Test.startTest();
            String result = MCP_TEST_260325_TC012_1.ping();
            Test.stopTest();

            System.assertEquals('OK', result, 'ping() should return OK');
        }
    }
}
