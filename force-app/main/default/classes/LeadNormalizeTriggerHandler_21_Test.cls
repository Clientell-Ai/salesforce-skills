/**
 * @description Tests for LeadNormalizeTriggerHandler_21 trigger behavior.
 */
@IsTest
public with sharing class LeadNormalizeTriggerHandler_21_Test {

    @IsTest
    static void testBeforeInsert_NormalizesAndNullsEmptyEmail() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Lead leadWithEmail = new Lead(LastName = 'InsertNormalize', Company = 'Acme', Email = '  TEST@Example.COM  ');
            Lead leadWithBlankEmail = new Lead(LastName = 'InsertBlank', Company = 'Acme', Email = '   ');

            Test.startTest();
            insert new List<Lead>{ leadWithEmail, leadWithBlankEmail };
            Test.stopTest();

            List<Lead> insertedLeads = [
                SELECT Id, Email
                FROM Lead
                WHERE Id IN :new List<Id>{ leadWithEmail.Id, leadWithBlankEmail.Id }
                WITH USER_MODE
            ];

            Map<Id, Lead> insertedById = new Map<Id, Lead>(insertedLeads);
            System.assertEquals(
                'test@example.com',
                insertedById.get(leadWithEmail.Id).Email,
                'Insert should trim and lowercase email values.'
            );
            System.assertEquals(
                null,
                insertedById.get(leadWithBlankEmail.Id).Email,
                'Insert should convert blank-trim email values to null.'
            );
        }
    }

    @IsTest
    static void testBeforeUpdate_OnlyNormalizesWhenEmailChanges() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Lead leadRecord = new Lead(LastName = 'UpdateNormalize', Company = 'Acme', Email = 'initial@example.com');
            insert leadRecord;

            leadRecord.Company = 'Acme Updated';
            Test.startTest();
            update leadRecord;
            Test.stopTest();

            Lead unchangedEmailLead = [
                SELECT Id, Email
                FROM Lead
                WHERE Id = :leadRecord.Id
                WITH USER_MODE
                LIMIT 1
            ];
            System.assertEquals(
                'initial@example.com',
                unchangedEmailLead.Email,
                'Update should not alter email when value did not change.'
            );

            leadRecord.Email = '  NEW@Example.COM  ';
            Test.startTest();
            update leadRecord;
            Test.stopTest();

            Lead changedEmailLead = [
                SELECT Id, Email
                FROM Lead
                WHERE Id = :leadRecord.Id
                WITH USER_MODE
                LIMIT 1
            ];
            System.assertEquals(
                'new@example.com',
                changedEmailLead.Email,
                'Update should trim and lowercase when email changes.'
            );

            leadRecord.Email = '   ';
            Test.startTest();
            update leadRecord;
            Test.stopTest();

            Lead blankEmailLead = [
                SELECT Id, Email
                FROM Lead
                WHERE Id = :leadRecord.Id
                WITH USER_MODE
                LIMIT 1
            ];
            System.assertEquals(
                null,
                blankEmailLead.Email,
                'Update should convert blank-trim email values to null.'
            );
        }
    }
}
