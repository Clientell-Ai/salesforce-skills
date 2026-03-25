/**
 * @description Tests for MCP_TEST_260325_TC019_1 trigger and handler.
 */
@IsTest
public with sharing class MCP_TEST_260325_TC019_1_Test {
    /**
     * @description Verifies before insert and before update trigger paths execute.
     */
    @IsTest
    static void testBeforeInsertAndBeforeUpdate() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(runningUser) {
            Contact con = new Contact(LastName = 'Trigger Test');

            Test.startTest();
            insert con;

            con.FirstName = 'Updated';
            update con;
            Test.stopTest();

            Contact stored = [
                SELECT Id, FirstName, LastName
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertNotEquals(null, stored.Id, 'Inserted contact should exist.');
            System.assertEquals('Updated', stored.FirstName, 'Updated first name should persist.');
            System.assertEquals('Trigger Test', stored.LastName, 'Last name should remain unchanged.');
        }
    }
}
