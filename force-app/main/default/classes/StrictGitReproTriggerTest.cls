/**
 * @description Tests StrictGitReproTrigger behavior for Contact normalization and validation.
 */
@IsTest
public with sharing class StrictGitReproTriggerTest {

    /**
     * @description Verifies insert/update normalization trims LastName and lowercases Email.
     */
    @IsTest
    static void testInsertAndUpdate_NormalizesFields() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact testContact = new Contact(
                LastName = '  Doe  ',
                Email = '  USER@EXAMPLE.COM  '
            );

            Test.startTest();
            insert testContact;
            testContact = [SELECT LastName, Email FROM Contact WHERE Id = :testContact.Id LIMIT 1];
            testContact.LastName = '  Smith  ';
            testContact.Email = '  SECOND@EXAMPLE.COM  ';
            update testContact;
            Test.stopTest();

            Contact persisted = [SELECT LastName, Email FROM Contact WHERE Id = :testContact.Id LIMIT 1];
            System.assertEquals('Smith', persisted.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('second@example.com', persisted.Email, 'Email should be trimmed and lowercased on update.');
        }
    }

    /**
     * @description Verifies whitespace-only LastName fails with expected validation message.
     */
    @IsTest
    static void testInsert_WhitespaceLastName_Fails() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact invalidContact = new Contact(
                LastName = '   ',
                Email = 'USER@EXAMPLE.COM'
            );

            Test.startTest();
            Database.SaveResult saveResult = Database.insert(invalidContact, false);
            Test.stopTest();

            System.assertEquals(false, saveResult.isSuccess(), 'Insert should fail when LastName is blank after trimming.');
            System.assertEquals(1, saveResult.getErrors().size(), 'Expected exactly one validation error.');
            System.assertEquals('Last Name is required.', saveResult.getErrors()[0].getMessage(), 'Expected trigger validation message.');
        }
    }
}
