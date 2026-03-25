/**
 * @description Tests for TestContactNormalizeTrigger.
 */
@IsTest
public with sharing class TestContactNormalizeTriggerTest {

    /**
     * @description Verifies email is normalized before insert.
     */
    @IsTest
    static void testBeforeInsertNormalizesEmail() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact testContact = new Contact(
                LastName = 'Insert Case',
                Email = '  Mixed.Case@Example.COM  '
            );

            Test.startTest();
            insert testContact;
            Test.stopTest();

            Contact inserted = [
                SELECT Email
                FROM Contact
                WHERE Id = :testContact.Id
                LIMIT 1
            ];
            System.assertEquals(
                'mixed.case@example.com',
                inserted.Email,
                'Before insert should trim whitespace and lowercase Email.'
            );
        }
    }

    /**
     * @description Verifies email is normalized before update.
     */
    @IsTest
    static void testBeforeUpdateNormalizesEmail() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact testContact = new Contact(
                LastName = 'Update Case',
                Email = 'normal@example.com'
            );
            insert testContact;

            testContact.Email = '  Updated.Email@Example.COM  ';

            Test.startTest();
            update testContact;
            Test.stopTest();

            Contact updated = [
                SELECT Email
                FROM Contact
                WHERE Id = :testContact.Id
                LIMIT 1
            ];
            System.assertEquals(
                'updated.email@example.com',
                updated.Email,
                'Before update should trim whitespace and lowercase Email.'
            );
        }
    }

    /**
     * @description Verifies null email remains null.
     */
    @IsTest
    static void testNullEmailRemainsNull() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact testContact = new Contact(
                LastName = 'Null Email Case',
                Email = null
            );

            Test.startTest();
            insert testContact;
            Test.stopTest();

            Contact inserted = [
                SELECT Email
                FROM Contact
                WHERE Id = :testContact.Id
                LIMIT 1
            ];
            System.assertEquals(
                null,
                inserted.Email,
                'Null Email should remain null.'
            );
        }
    }
}
