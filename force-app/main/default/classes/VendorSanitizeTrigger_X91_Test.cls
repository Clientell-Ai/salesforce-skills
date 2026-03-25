/**
 * @description Tests VendorSanitizeTrigger_X91 behavior on Lead.Company trimming.
 */
@IsTest
public with sharing class VendorSanitizeTrigger_X91_Test {

    @IsTest
    static void testInsertSingleLeadCompanyTrimmed() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                LastName = 'Insert Case',
                Company = '  ACME Corp  '
            );

            Test.startTest();
            insert testLead;
            Test.stopTest();

            Lead insertedLead = [
                SELECT Company
                FROM Lead
                WHERE Id = :testLead.Id
                WITH USER_MODE
                LIMIT 1
            ];
            System.assertEquals('ACME Corp', insertedLead.Company, 'Company should be trimmed on insert.');
        }
    }

    @IsTest
    static void testUpdateLeadCompanyTrimmed() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                LastName = 'Update Case',
                Company = 'OriginalCo'
            );
            insert testLead;

            testLead.Company = '  Updated Co  ';

            Test.startTest();
            update testLead;
            Test.stopTest();

            Lead updatedLead = [
                SELECT Company
                FROM Lead
                WHERE Id = :testLead.Id
                WITH USER_MODE
                LIMIT 1
            ];
            System.assertEquals('Updated Co', updatedLead.Company, 'Company should be trimmed on update.');
        }
    }

    @IsTest
    static void testBulkInsertLeadCompanyTrimmed() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            List<Lead> leadsToInsert = new List<Lead>();
            for (Integer indexValue = 0; indexValue < 50; indexValue++) {
                leadsToInsert.add(new Lead(
                    LastName = 'Bulk ' + indexValue,
                    Company = '  BulkCompany' + indexValue + '  '
                ));
            }

            Test.startTest();
            insert leadsToInsert;
            Test.stopTest();

            Set<Id> leadIds = new Set<Id>();
            for (Lead leadRecord : leadsToInsert) {
                leadIds.add(leadRecord.Id);
            }

            List<Lead> insertedLeads = [
                SELECT Company
                FROM Lead
                WHERE Id IN :leadIds
                WITH USER_MODE
            ];

            System.assertEquals(50, insertedLeads.size(), 'Expected 50 leads from bulk insert.');
            for (Lead leadRecord : insertedLeads) {
                System.assert(!leadRecord.Company.startsWith(' '), 'Company should not start with whitespace.');
                System.assert(!leadRecord.Company.endsWith(' '), 'Company should not end with whitespace.');
            }
        }
    }
}
