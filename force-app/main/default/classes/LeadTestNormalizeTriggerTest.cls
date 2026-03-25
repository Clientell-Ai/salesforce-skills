/**
 * @description Tests for LeadTestNormalizeTrigger and LeadTestNormalizeTriggerHandler.
 */
@IsTest
public with sharing class LeadTestNormalizeTriggerTest {

    /**
     * @description Validates normalization for single record insert.
     */
    @IsTest
    static void testInsertSingleLeadNormalizesFields() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                FirstName = '  Jane  ',
                LastName = '  Doe  ',
                Company = '  Acme Corp  ',
                Email = '  Jane.Doe@Example.COM  ',
                Phone = '  123-456-7890  ',
                MobilePhone = '  987-654-3210  '
            );

            Test.startTest();
            insert testLead;
            Test.stopTest();

            Lead insertedLead = [
                SELECT FirstName, LastName, Company, Email, Phone, MobilePhone
                FROM Lead
                WHERE Id = :testLead.Id
                LIMIT 1
            ];

            System.assertEquals('Jane', insertedLead.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Doe', insertedLead.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('Acme Corp', insertedLead.Company, 'Company should be trimmed on insert.');
            System.assertEquals('jane.doe@example.com', insertedLead.Email, 'Email should be trimmed and lowercased on insert.');
            System.assertEquals('123-456-7890', insertedLead.Phone, 'Phone should be trimmed on insert.');
            System.assertEquals('987-654-3210', insertedLead.MobilePhone, 'MobilePhone should be trimmed on insert.');
        }
    }

    /**
     * @description Validates changed fields are normalized on update.
     */
    @IsTest
    static void testUpdateLeadNormalizesChangedFieldsOnly() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                FirstName = 'John',
                LastName = 'Smith',
                Company = 'Clientell',
                Email = 'john.smith@example.com',
                Phone = '555-0100',
                MobilePhone = '555-0199'
            );
            insert testLead;

            testLead.Email = '  John.New@Example.COM  ';
            testLead.Phone = '  555-7777  ';

            Test.startTest();
            update testLead;
            Test.stopTest();

            Lead updatedLead = [
                SELECT FirstName, LastName, Company, Email, Phone, MobilePhone
                FROM Lead
                WHERE Id = :testLead.Id
                LIMIT 1
            ];

            System.assertEquals('john.new@example.com', updatedLead.Email, 'Email should be trimmed and lowercased on update.');
            System.assertEquals('555-7777', updatedLead.Phone, 'Phone should be trimmed on update.');
            System.assertEquals('John', updatedLead.FirstName, 'Unchanged FirstName should remain the same.');
            System.assertEquals('Smith', updatedLead.LastName, 'Unchanged LastName should remain the same.');
            System.assertEquals('Clientell', updatedLead.Company, 'Unchanged Company should remain the same.');
            System.assertEquals('555-0199', updatedLead.MobilePhone, 'Unchanged MobilePhone should remain the same.');
        }
    }

    /**
     * @description Validates bulk insert normalization for trigger bulk safety.
     */
    @IsTest
    static void testBulkInsertNormalizes200Leads() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            List<Lead> leadsToInsert = new List<Lead>();
            for (Integer i = 0; i < 200; i++) {
                leadsToInsert.add(new Lead(
                    FirstName = '  First' + i + '  ',
                    LastName = '  Last' + i + '  ',
                    Company = '  Company' + i + '  ',
                    Email = '  BULK' + i + '@Example.COM  ',
                    Phone = '  1000' + i + '  ',
                    MobilePhone = '  2000' + i + '  '
                ));
            }

            Test.startTest();
            insert leadsToInsert;
            Test.stopTest();

            List<Lead> insertedLeads = [
                SELECT FirstName, LastName, Company, Email, Phone, MobilePhone
                FROM Lead
                WHERE Id IN :leadsToInsert
                ORDER BY CreatedDate ASC
            ];

            System.assertEquals(200, insertedLeads.size(), 'Exactly 200 Leads should be inserted.');
            System.assertEquals('First0', insertedLeads[0].FirstName, 'FirstName should be trimmed in bulk insert.');
            System.assertEquals('Last0', insertedLeads[0].LastName, 'LastName should be trimmed in bulk insert.');
            System.assertEquals('Company0', insertedLeads[0].Company, 'Company should be trimmed in bulk insert.');
            System.assertEquals('bulk0@example.com', insertedLeads[0].Email, 'Email should be trimmed and lowercased in bulk insert.');
            System.assertEquals('10000', insertedLeads[0].Phone, 'Phone should be trimmed in bulk insert.');
            System.assertEquals('20000', insertedLeads[0].MobilePhone, 'MobilePhone should be trimmed in bulk insert.');
        }
    }
}
