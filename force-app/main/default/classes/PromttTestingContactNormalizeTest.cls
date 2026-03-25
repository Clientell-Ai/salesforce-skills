/**
 * @description Tests for PromttTestingContactNormalizeTrigger and helper.
 */
@IsTest
public with sharing class PromttTestingContactNormalizeTest {

    /**
     * @description Verifies insert normalizes whitespace in names and lowercases trimmed email.
     */
    @IsTest
    static void testInsert_NormalizesFields() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(runAsUser) {
            Contact contactToInsert = new Contact(
                FirstName = '  John  ',
                LastName = '  Doe  ',
                Email = '  JoHn.DoE@Example.COM  '
            );

            Test.startTest();
            insert contactToInsert;
            Test.stopTest();

            Contact insertedContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :contactToInsert.Id
                WITH USER_MODE
            ];

            System.assertEquals('John', insertedContact.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Doe', insertedContact.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('john.doe@example.com', insertedContact.Email, 'Email should be trimmed and lowercased on insert.');
        }
    }

    /**
     * @description Verifies update normalizes whitespace in names and lowercases trimmed email.
     */
    @IsTest
    static void testUpdate_NormalizesFields() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(runAsUser) {
            Contact contactToInsert = new Contact(
                FirstName = 'Jane',
                LastName = 'Doe',
                Email = 'jane.doe@example.com'
            );
            insert contactToInsert;

            Contact contactToUpdate = new Contact(
                Id = contactToInsert.Id,
                FirstName = '  Jane  ',
                LastName = '  DOE  ',
                Email = '  JANE.DOE@EXAMPLE.COM  '
            );

            Test.startTest();
            update contactToUpdate;
            Test.stopTest();

            Contact updatedContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :contactToInsert.Id
                WITH USER_MODE
            ];

            System.assertEquals('Jane', updatedContact.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('DOE', updatedContact.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('jane.doe@example.com', updatedContact.Email, 'Email should be trimmed and lowercased on update.');
        }
    }

    /**
     * @description Verifies no extra helper DML occurs when tracked fields are already normalized.
     */
    @IsTest
    static void testUpdate_NoOp_DoesNotPerformExtraDml() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(runAsUser) {
            Contact contactToInsert = new Contact(
                FirstName = 'Alex',
                LastName = 'Brown',
                Email = 'alex.brown@example.com'
            );
            insert contactToInsert;

            Contact noOpUpdate = new Contact(
                Id = contactToInsert.Id,
                FirstName = 'Alex',
                LastName = 'Brown',
                Email = 'alex.brown@example.com'
            );

            Test.startTest();
            Integer dmlBefore = Limits.getDmlStatements();
            update noOpUpdate;
            Integer dmlAfter = Limits.getDmlStatements();
            Test.stopTest();

            System.assertEquals(dmlBefore + 1, dmlAfter, 'Only the explicit test update should run; helper must not issue extra DML.');

            Contact resultingContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :contactToInsert.Id
                WITH USER_MODE
            ];

            System.assertEquals('Alex', resultingContact.FirstName, 'FirstName should remain unchanged.');
            System.assertEquals('Brown', resultingContact.LastName, 'LastName should remain unchanged.');
            System.assertEquals('alex.brown@example.com', resultingContact.Email, 'Email should remain unchanged.');
        }
    }
}
