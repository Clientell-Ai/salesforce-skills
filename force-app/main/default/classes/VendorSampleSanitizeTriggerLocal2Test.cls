/**
 * @description Test class for VendorSampleSanitizeTriggerLocal2 and its handler.
 */
@IsTest
public with sharing class VendorSampleSanitizeTriggerLocal2Test {

    /**
     * @description Verifies before insert trims FirstName, LastName, and Company values.
     */
    @IsTest
    static void testBeforeInsert_TrimsFields() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Lead leadRecord = new Lead(
                FirstName = '  Ada  ',
                LastName = '  Lovelace  ',
                Company = '  Analytical Engines  '
            );

            Test.startTest();
            insert leadRecord;
            Test.stopTest();

            Lead insertedLead = [
                SELECT FirstName, LastName, Company
                FROM Lead
                WHERE Id = :leadRecord.Id
                WITH USER_MODE
            ];

            System.assertEquals('Ada', insertedLead.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Lovelace', insertedLead.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('Analytical Engines', insertedLead.Company, 'Company should be trimmed on insert.');
        }
    }

    /**
     * @description Verifies before update trims values and handles null safely.
     */
    @IsTest
    static void testBeforeUpdate_TrimsAndHandlesNulls() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Lead leadRecord = new Lead(LastName = 'Initial', Company = 'Initial Company');
            insert leadRecord;

            leadRecord.FirstName = null;
            leadRecord.LastName = '  Hopper  ';
            leadRecord.Company = '  Navy  ';

            Test.startTest();
            update leadRecord;
            Test.stopTest();

            Lead updatedLead = [
                SELECT FirstName, LastName, Company
                FROM Lead
                WHERE Id = :leadRecord.Id
                WITH USER_MODE
            ];

            System.assertEquals(null, updatedLead.FirstName, 'FirstName should remain null when input is null.');
            System.assertEquals('Hopper', updatedLead.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('Navy', updatedLead.Company, 'Company should be trimmed on update.');
        }
    }
}
