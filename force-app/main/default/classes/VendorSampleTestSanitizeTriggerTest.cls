/**
 * @description Test class for VendorSampleTestSanitizeTrigger.
 */
@IsTest(SeeAllData=false)
public with sharing class VendorSampleTestSanitizeTriggerTest {

    /**
     * @description Verifies Lead name and company fields are trimmed during before insert.
     */
    @IsTest
    static void testBeforeInsert_TrimsFields() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(currentUser) {
            Lead leadRecord = new Lead(
                FirstName = '  Jane  ',
                LastName = '  Doe  ',
                Company = '  Acme Corp  '
            );

            Test.startTest();
            insert leadRecord;
            Test.stopTest();

            Lead insertedLead = [
                SELECT FirstName, LastName, Company
                FROM Lead
                WHERE Id = :leadRecord.Id
                LIMIT 1
            ];

            System.assertEquals('Jane', insertedLead.FirstName, 'FirstName should be trimmed on insert');
            System.assertEquals('Doe', insertedLead.LastName, 'LastName should be trimmed on insert');
            System.assertEquals('Acme Corp', insertedLead.Company, 'Company should be trimmed on insert');
        }
    }

    /**
     * @description Verifies Lead name and company fields are trimmed during before update.
     */
    @IsTest
    static void testBeforeUpdate_TrimsFields() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(currentUser) {
            Lead leadRecord = new Lead(
                FirstName = 'John',
                LastName = 'Smith',
                Company = 'Global Tech'
            );
            insert leadRecord;

            leadRecord.FirstName = '  John  ';
            leadRecord.LastName = '  Smith  ';
            leadRecord.Company = '  Global Tech  ';

            Test.startTest();
            update leadRecord;
            Test.stopTest();

            Lead updatedLead = [
                SELECT FirstName, LastName, Company
                FROM Lead
                WHERE Id = :leadRecord.Id
                LIMIT 1
            ];

            System.assertEquals('John', updatedLead.FirstName, 'FirstName should be trimmed on update');
            System.assertEquals('Smith', updatedLead.LastName, 'LastName should be trimmed on update');
            System.assertEquals('Global Tech', updatedLead.Company, 'Company should be trimmed on update');
        }
    }
}
