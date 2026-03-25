/**
 * @description Tests LeadNormalizeTriggerHandler_31 behavior.
 */
@IsTest
public with sharing class LeadNormalizeTriggerHandler_31_Test {

    @IsTest
    static void testInsertSingleLead_NormalizesFields() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            List<Lead> newLeads = new List<Lead>{
                new Lead(
                    Company = 'Acme Inc',
                    LastName = '  Doe  ',
                    FirstName = '  John  ',
                    Email = '  John.DOE@Example.COM  '
                )
            };

            Test.startTest();
            LeadNormalizeTriggerHandler_31.handleBeforeInsertUpdate(newLeads);
            Test.stopTest();

            System.assertEquals('John', newLeads[0].FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Doe', newLeads[0].LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('john.doe@example.com', newLeads[0].Email, 'Email should be trimmed and lowercased on insert.');
        }
    }

    @IsTest
    static void testUpdateLead_NormalizesEmail() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            List<Lead> updatedLeads = new List<Lead>{
                new Lead(
                    Id = '00Q000000000001AAA',
                    Company = 'Acme Inc',
                    LastName = 'Smith',
                    FirstName = 'Jane',
                    Email = '  JANE.NEW@Example.COM  '
                )
            };

            Test.startTest();
            LeadNormalizeTriggerHandler_31.handleBeforeInsertUpdate(updatedLeads);
            Test.stopTest();

            System.assertEquals('jane.new@example.com', updatedLeads[0].Email, 'Email should be trimmed and lowercased on update.');
        }
    }

    @IsTest
    static void testBulkInsert200Leads_NormalizesSample() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            List<Lead> leadsToInsert = new List<Lead>();
            for (Integer indexValue = 0; indexValue < 200; indexValue++) {
                leadsToInsert.add(new Lead(
                    Company = 'Bulk Co ' + indexValue,
                    LastName = '  Last' + indexValue + '  ',
                    FirstName = '  First' + indexValue + '  ',
                    Email = '  USER' + indexValue + '@Example.COM  '
                ));
            }

            Test.startTest();
            LeadNormalizeTriggerHandler_31.handleBeforeInsertUpdate(leadsToInsert);
            Test.stopTest();

            System.assertEquals(200, leadsToInsert.size(), 'Bulk list should retain all records.');
            System.assertEquals('First0', leadsToInsert[0].FirstName, 'Sample FirstName should be trimmed in bulk.');
            System.assertEquals('Last0', leadsToInsert[0].LastName, 'Sample LastName should be trimmed in bulk.');
            System.assertEquals('user0@example.com', leadsToInsert[0].Email, 'Sample Email should be trimmed and lowercased in bulk.');
        }
    }
}
