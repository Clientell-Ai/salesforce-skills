/**
 * @description Tests for PromotionTestingContactNormalizeTrigger and handler behavior.
 */
@IsTest
public with sharing class PromotionTestingContactNormalizeTriggerTest {

    @IsTest
    static void testInsertNormalizesWhitespaceAndEmailCase() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Contact c = new Contact(
                LastName = '  Doe  ',
                FirstName = '  Jane  ',
                Email = 'MiXeD.Email@Example.COM'
            );

            insert c;

            Contact inserted = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :c.Id
                LIMIT 1
            ];

            System.assertEquals('Jane', inserted.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Doe', inserted.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('mixed.email@example.com', inserted.Email, 'Email should be lowercased on insert.');
        }
    }

    @IsTest
    static void testUpdateNormalizesWhitespaceAndEmailCase() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Contact c = new Contact(LastName = 'Smith', FirstName = 'John', Email = 'john@example.com');
            insert c;

            c.FirstName = '  John  ';
            c.LastName = '  Smith  ';
            c.Email = 'JoHN.SmIth@Example.COM';

            Test.startTest();
            update c;
            Test.stopTest();

            Contact updated = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :c.Id
                LIMIT 1
            ];

            System.assertEquals('John', updated.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('Smith', updated.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('john.smith@example.com', updated.Email, 'Email should be lowercased on update.');
        }
    }

    @IsTest
    static void testNullHandlingNoExceptions() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Contact c = new Contact(LastName = 'NullCase');

            Test.startTest();
            insert c;
            c.FirstName = null;
            c.LastName = '  NullCase  ';
            c.Email = null;
            update c;
            Test.stopTest();

            Contact resultContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :c.Id
                LIMIT 1
            ];

            System.assertEquals(null, resultContact.FirstName, 'FirstName should remain null.');
            System.assertEquals('NullCase', resultContact.LastName, 'LastName should be trimmed correctly.');
            System.assertEquals(null, resultContact.Email, 'Email should remain null.');
        }
    }
}
