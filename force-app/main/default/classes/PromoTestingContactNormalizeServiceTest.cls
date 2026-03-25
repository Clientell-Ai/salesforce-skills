/**
 * @description Tests for PromoTestingContactNormalizeService trigger behavior.
 */
@IsTest
public with sharing class PromoTestingContactNormalizeServiceTest {

    /**
     * @description Verifies normalization on insert for whitespace and email casing.
     */
    @IsTest
    static void testInsert_NormalizesNameAndEmail() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            Contact testContact = new Contact(
                FirstName = '  Jane  ',
                LastName = '  Doe  ',
                Email = 'Jane.Doe@Test.com'
            );

            Test.startTest();
            insert testContact;
            Test.stopTest();

            Contact insertedContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :testContact.Id
                WITH USER_MODE
            ];

            System.assertEquals('Jane', insertedContact.FirstName, 'FirstName should be trimmed.');
            System.assertEquals('Doe', insertedContact.LastName, 'LastName should be trimmed.');
            System.assertEquals('JANE.DOE@TEST.COM', insertedContact.Email, 'Email should be uppercase.');
        }
    }

    /**
     * @description Verifies normalization on update and null handling without exceptions.
     */
    @IsTest
    static void testUpdate_EmailCasingAndNullHandling() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            Contact testContact = new Contact(
                LastName = '  Smith  ',
                Email = null,
                FirstName = null
            );
            insert testContact;

            testContact.Email = 'MiXeD.Case@Example.com';
            testContact.FirstName = null;

            Test.startTest();
            update testContact;
            Test.stopTest();

            Contact updatedContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :testContact.Id
                WITH USER_MODE
            ];

            System.assertEquals(null, updatedContact.FirstName, 'FirstName should remain null.');
            System.assertEquals('Smith', updatedContact.LastName, 'LastName should be trimmed.');
            System.assertEquals('MIXED.CASE@EXAMPLE.COM', updatedContact.Email, 'Email should be uppercase after update.');
        }
    }
}
