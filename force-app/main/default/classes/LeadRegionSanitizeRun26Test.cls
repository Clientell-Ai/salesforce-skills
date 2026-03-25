/**
 * @description Tests LeadRegionSanitizeRun26 trigger and handler behavior.
 */
@IsTest
public with sharing class LeadRegionSanitizeRun26Test {
    /**
     * @description Verifies insert sanitization and null handling.
     */
    @IsTest
    static void testBeforeInsertSanitizesFieldsAndHandlesNulls() {
        User runAsUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runAsUser) {
            Lead leadWithValues = new Lead(
                Company = 'Acme Inc',
                FirstName = '  Jane  ',
                LastName = '  Doe  ',
                Email = '  Jane.DOE@Example.COM  '
            );

            Lead leadWithNulls = new Lead(
                Company = 'Null Co',
                LastName = '  Smith  ',
                FirstName = null,
                Email = null
            );

            Test.startTest();
            insert new List<Lead>{ leadWithValues, leadWithNulls };
            Test.stopTest();

            List<Lead> insertedLeads = [
                SELECT Id, FirstName, LastName, Email
                FROM Lead
                WHERE Id IN :new Set<Id>{ leadWithValues.Id, leadWithNulls.Id }
                WITH USER_MODE
            ];

            Map<Id, Lead> insertedById = new Map<Id, Lead>(insertedLeads);
            Lead insertedLeadWithValues = insertedById.get(leadWithValues.Id);
            Lead insertedLeadWithNulls = insertedById.get(leadWithNulls.Id);

            System.assertEquals(
                'Jane',
                insertedLeadWithValues.FirstName,
                'FirstName should be trimmed on insert.'
            );
            System.assertEquals(
                'Doe',
                insertedLeadWithValues.LastName,
                'LastName should be trimmed on insert.'
            );
            System.assertEquals(
                'jane.doe@example.com',
                insertedLeadWithValues.Email,
                'Email should be trimmed and lowercased on insert.'
            );
            System.assertEquals(
                null,
                insertedLeadWithNulls.FirstName,
                'FirstName should remain null when input is null.'
            );
            System.assertEquals(
                'Smith',
                insertedLeadWithNulls.LastName,
                'LastName should be trimmed for null-handling scenario.'
            );
            System.assertEquals(
                null,
                insertedLeadWithNulls.Email,
                'Email should remain null when input is null.'
            );
        }
    }

    /**
     * @description Verifies update sanitization behavior.
     */
    @IsTest
    static void testBeforeUpdateSanitizesFields() {
        User runAsUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runAsUser) {
            Lead targetLead = new Lead(
                Company = 'Update Co',
                FirstName = 'Alex',
                LastName = 'Stone',
                Email = 'alex.stone@example.com'
            );
            insert targetLead;

            targetLead.FirstName = '  Alex  ';
            targetLead.LastName = '  STONE  ';
            targetLead.Email = '  Alex.STONE@Example.ORG  ';

            Test.startTest();
            update targetLead;
            Test.stopTest();

            Lead updatedLead = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :targetLead.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals(
                'Alex',
                updatedLead.FirstName,
                'FirstName should be trimmed on update.'
            );
            System.assertEquals(
                'STONE',
                updatedLead.LastName,
                'LastName should be trimmed (case preserved) on update.'
            );
            System.assertEquals(
                'alex.stone@example.org',
                updatedLead.Email,
                'Email should be trimmed and lowercased on update.'
            );
        }
    }
}
