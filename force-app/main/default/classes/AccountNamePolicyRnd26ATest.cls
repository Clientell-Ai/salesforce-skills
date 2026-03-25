/**
 * @description Tests for AccountNamePolicyRnd26A trigger behavior.
 */
@IsTest
public with sharing class AccountNamePolicyRnd26ATest {

    @IsTest
    static void testInsert_TrimAndLowercase() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Account acc = new Account(
                Name = '  Acme Corp  ',
                Website = 'WWW.Example.COM'
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

            System.assertEquals('Acme Corp', inserted.Name, 'Name should be trimmed on insert');
            System.assertEquals('www.example.com', inserted.Website, 'Website should be lowercased on insert');
        }
    }

    @IsTest
    static void testUpdate_TrimAndLowercase() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Account acc = new Account(Name = 'Initial', Website = 'initial.com');
            insert acc;

            acc.Name = '  Updated Name  ';
            acc.Website = 'MiXeD.Domain.COM';

            Test.startTest();
            update acc;
            Test.stopTest();

            Account updated = [
                SELECT Name, Website
                FROM Account
                WHERE Id = :acc.Id
                LIMIT 1
            ];

            System.assertEquals('Updated Name', updated.Name, 'Name should be trimmed on update');
            System.assertEquals('mixed.domain.com', updated.Website, 'Website should be lowercased on update');
        }
    }

    @IsTest
    static void testNullHandling_NoThrowAndNoChange() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Account acc = new Account(Name = null, Website = null);

            Test.startTest();
            insert acc;
            Test.stopTest();

            Account inserted = [
                SELECT Name, Website
                FROM Account
                WHERE Id = :acc.Id
                LIMIT 1
            ];

            System.assertEquals(null, inserted.Name, 'Name should remain null when input is null');
            System.assertEquals(null, inserted.Website, 'Website should remain null when input is null');

            inserted.Name = null;
            inserted.Website = null;

            Test.startTest();
            update inserted;
            Test.stopTest();

            Account updated = [
                SELECT Name, Website
                FROM Account
                WHERE Id = :inserted.Id
                LIMIT 1
            ];

            System.assertEquals(null, updated.Name, 'Name should remain null after update when input is null');
            System.assertEquals(null, updated.Website, 'Website should remain null after update when input is null');
        }
    }
}
