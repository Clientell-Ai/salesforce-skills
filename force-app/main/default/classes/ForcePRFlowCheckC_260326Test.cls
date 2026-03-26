/**
 * @description Tests for ForcePRFlowCheckC_260326 account normalization behavior.
 */
@IsTest
public with sharing class ForcePRFlowCheckC_260326Test {

    /**
     * @description Verifies Name is trimmed and Website is lowercased/trimmed on insert.
     */
    @IsTest
    static void testNormalizeBeforeInsert() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Account acc = new Account(
                Name = '  Acme Incorporated  ',
                Website = '  WWW.Example.COM  '
            );

            Test.startTest();
            insert acc;
            Test.stopTest();

            Account inserted = [
                SELECT Name, Website
                FROM Account
                WHERE Id = :acc.Id
                LIMIT 1
            ];

            System.assertEquals('Acme Incorporated', inserted.Name, 'Name should be trimmed on insert.');
            System.assertEquals('www.example.com', inserted.Website, 'Website should be trimmed and lowercased on insert.');
        }
    }

    /**
     * @description Verifies Name is trimmed and Website is lowercased/trimmed on update.
     */
    @IsTest
    static void testNormalizeBeforeUpdate() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Account acc = new Account(
                Name = 'Original Name',
                Website = 'initial.example.com'
            );
            insert acc;

            acc.Name = '  Updated Account Name  ';
            acc.Website = '  Portal.NEWExample.ORG  ';

            Test.startTest();
            update acc;
            Test.stopTest();

            Account updated = [
                SELECT Name, Website
                FROM Account
                WHERE Id = :acc.Id
                LIMIT 1
            ];

            System.assertEquals('Updated Account Name', updated.Name, 'Name should be trimmed on update.');
            System.assertEquals('portal.newexample.org', updated.Website, 'Website should be trimmed and lowercased on update.');
        }
    }
}
