/**
 * @description Tests for LeadPushFallbackFix26Handler trigger behavior.
 */
@IsTest
public with sharing class LeadPushFallbackFix26HandlerTest {

    /**
     * @description Validates before insert cleanup and no-change behavior for clean fields.
     */
    @IsTest
    static void testBeforeInsert_CleansAndKeepsCleanValues() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(runAsUser) {
            Lead dirtyLead = new Lead(
                FirstName = '  Alice  ',
                LastName = '  Smith  ',
                Company = 'Acme',
                Email = '  ALICE.SMITH@EXAMPLE.COM  '
            );

            Lead cleanLead = new Lead(
                FirstName = 'Bob',
                LastName = 'Jones',
                Company = 'Beta',
                Email = 'bob.jones@example.com'
            );

            Lead nullFieldsLead = new Lead(
                FirstName = null,
                LastName = '  NullCase  ',
                Company = 'Gamma',
                Email = null
            );

            Test.startTest();
            insert new List<Lead>{ dirtyLead, cleanLead, nullFieldsLead };
            Test.stopTest();

            List<Lead> insertedLeads = [
                SELECT Id, FirstName, LastName, Email
                FROM Lead
                WHERE Id IN :new List<Id>{ dirtyLead.Id, cleanLead.Id, nullFieldsLead.Id }
            ];

            Map<Id, Lead> byId = new Map<Id, Lead>(insertedLeads);

            System.assertEquals('Alice', byId.get(dirtyLead.Id).FirstName, 'Dirty FirstName should be trimmed on insert.');
            System.assertEquals('Smith', byId.get(dirtyLead.Id).LastName, 'Dirty LastName should be trimmed on insert.');
            System.assertEquals('alice.smith@example.com', byId.get(dirtyLead.Id).Email, 'Dirty Email should be trimmed and lowercased on insert.');

            System.assertEquals('Bob', byId.get(cleanLead.Id).FirstName, 'Clean FirstName should remain unchanged on insert.');
            System.assertEquals('Jones', byId.get(cleanLead.Id).LastName, 'Clean LastName should remain unchanged on insert.');
            System.assertEquals('bob.jones@example.com', byId.get(cleanLead.Id).Email, 'Clean Email should remain unchanged on insert.');

            System.assertEquals(null, byId.get(nullFieldsLead.Id).FirstName, 'Null FirstName should remain null on insert.');
            System.assertEquals('NullCase', byId.get(nullFieldsLead.Id).LastName, 'LastName should still be trimmed when other fields are null.');
            System.assertEquals(null, byId.get(nullFieldsLead.Id).Email, 'Null Email should remain null on insert.');
        }
    }

    /**
     * @description Validates before update cleanup.
     */
    @IsTest
    static void testBeforeUpdate_CleansUpdatedValues() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        System.runAs(runAsUser) {
            Lead leadToUpdate = new Lead(
                FirstName = 'Chris',
                LastName = 'Taylor',
                Company = 'Delta',
                Email = 'chris.taylor@example.com'
            );
            insert leadToUpdate;

            leadToUpdate.FirstName = '  Chris  ';
            leadToUpdate.LastName = '  Taylor  ';
            leadToUpdate.Email = '  CHRIS.NEW@EXAMPLE.COM  ';

            Test.startTest();
            update leadToUpdate;
            Test.stopTest();

            Lead updatedLead = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :leadToUpdate.Id
                LIMIT 1
            ];

            System.assertEquals('Chris', updatedLead.FirstName, 'Updated FirstName should be trimmed.');
            System.assertEquals('Taylor', updatedLead.LastName, 'Updated LastName should be trimmed.');
            System.assertEquals('chris.new@example.com', updatedLead.Email, 'Updated Email should be trimmed and lowercased.');
        }
    }
}
