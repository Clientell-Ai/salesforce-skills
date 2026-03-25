/**
 * @description Tests for PromotionTestingContactNormalizeTrigger.
 */
@IsTest
public with sharing class PromotionTestingContactNormalizeTriggerTest {

    @IsTest
    static void testInsert_WithWhitespaceAndMixedCaseEmail_NormalizesValues() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Contact newContact = new Contact(
                FirstName = '  Jane  ',
                LastName = '  Doe  ',
                Email = 'Jane.DOE@Example.COM'
            );

            Test.startTest();
            insert newContact;
            Test.stopTest();

            Contact savedContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :newContact.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('Jane', savedContact.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Doe', savedContact.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('jane.doe@example.com', savedContact.Email, 'Email should be lowercased on insert.');
        }
    }

    @IsTest
    static void testUpdate_WithWhitespaceAndMixedCaseEmail_NormalizesValues() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Contact existingContact = new Contact(
                FirstName = 'Alex',
                LastName = 'Smith',
                Email = 'alex@example.com'
            );
            insert existingContact;

            existingContact.FirstName = '  Alice  ';
            existingContact.LastName = '  Johnson  ';
            existingContact.Email = 'ALICE.JOHNSON@EXAMPLE.COM';

            Test.startTest();
            update existingContact;
            Test.stopTest();

            Contact updatedContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :existingContact.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('Alice', updatedContact.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('Johnson', updatedContact.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('alice.johnson@example.com', updatedContact.Email, 'Email should be lowercased on update.');
        }
    }

    @IsTest
    static void testUpdate_NoOpWhenAlreadyNormalized_NoAdditionalTriggerDml() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Contact existingContact = new Contact(
                FirstName = 'Casey',
                LastName = 'Miller',
                Email = 'casey.miller@example.com'
            );
            insert existingContact;

            existingContact.Department = 'Sales';

            Test.startTest();
            Integer dmlBefore = Limits.getDmlStatements();
            update existingContact;
            Integer dmlAfter = Limits.getDmlStatements();
            Test.stopTest();

            System.assertEquals(
                dmlBefore + 1,
                dmlAfter,
                'Only the explicit update should execute; trigger should not issue an additional update for normalized values.'
            );
        }
    }
}
