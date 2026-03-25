/**
 * @description Tests for ReproRefreshTokenTrigger on Lead.
 */
@IsTest
public with sharing class ReproRefreshTokenTriggerTest {

    /**
     * @description Verifies trim behavior on insert and null preservation.
     */
    @IsTest
    static void testBeforeInsert_TrimsAndPreservesNulls() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Lead trimmedLead = new Lead(
                FirstName = '  Jane  ',
                LastName = '  Doe  ',
                Company = '  Acme Corp  '
            );
            Lead nullLead = new Lead(
                LastName = null,
                Company = null
            );

            Test.startTest();
            insert new List<Lead>{ trimmedLead, nullLead };
            Test.stopTest();

            Lead insertedTrimmed = [
                SELECT FirstName, LastName, Company
                FROM Lead
                WHERE Id = :trimmedLead.Id
                LIMIT 1
            ];
            Lead insertedNull = [
                SELECT FirstName, LastName, Company
                FROM Lead
                WHERE Id = :nullLead.Id
                LIMIT 1
            ];

            System.assertEquals('Jane', insertedTrimmed.FirstName, 'FirstName should be trimmed on insert');
            System.assertEquals('Doe', insertedTrimmed.LastName, 'LastName should be trimmed on insert');
            System.assertEquals('Acme Corp', insertedTrimmed.Company, 'Company should be trimmed on insert');

            System.assertEquals(null, insertedNull.FirstName, 'FirstName should remain null when null on insert');
            System.assertEquals(null, insertedNull.LastName, 'LastName should remain null when null on insert');
            System.assertEquals(null, insertedNull.Company, 'Company should remain null when null on insert');
        }
    }

    /**
     * @description Verifies trim behavior on update and null preservation.
     */
    @IsTest
    static void testBeforeUpdate_TrimsAndPreservesNulls() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Lead leadToUpdate = new Lead(
                FirstName = 'Initial',
                LastName = 'Smith',
                Company = 'InitCo'
            );
            insert leadToUpdate;

            leadToUpdate.FirstName = '  Updated  ';
            leadToUpdate.LastName = null;
            leadToUpdate.Company = '  Updated Co  ';

            Test.startTest();
            update leadToUpdate;
            Test.stopTest();

            Lead updatedLead = [
                SELECT FirstName, LastName, Company
                FROM Lead
                WHERE Id = :leadToUpdate.Id
                LIMIT 1
            ];

            System.assertEquals('Updated', updatedLead.FirstName, 'FirstName should be trimmed on update');
            System.assertEquals(null, updatedLead.LastName, 'LastName should remain null when set to null on update');
            System.assertEquals('Updated Co', updatedLead.Company, 'Company should be trimmed on update');
        }
    }
}
