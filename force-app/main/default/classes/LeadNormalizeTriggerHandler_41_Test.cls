/**
 * @description Test class for LeadNormalizeTriggerHandler_41.
 */
@IsTest
public with sharing class LeadNormalizeTriggerHandler_41_Test {

    @IsTest
    static void testSingleInsertNormalizesFields() {
        User currentUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(currentUser) {
            Lead singleLead = new Lead(
                LastName = 'Single',
                Company = '  Acme    Corporation  ',
                Email = '  TeSt.User@Example.COM  ',
                Phone = ' +1 (415) 555-1212 '
            );

            Test.startTest();
            insert singleLead;
            Test.stopTest();

            Lead savedLead = [
                SELECT Email, Phone, Company
                FROM Lead
                WHERE Id = :singleLead.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('test.user@example.com', savedLead.Email, 'Email should be trimmed and lowercased.');
            System.assertEquals('4155551212', savedLead.Phone, 'Phone should remove non-digits and drop leading country code 1.');
            System.assertEquals('Acme Corporation', savedLead.Company, 'Company should be trimmed and internal whitespace collapsed.');
        }
    }

    @IsTest
    static void testBulkInsertNormalizesFields() {
        User currentUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(currentUser) {
            List<Lead> leadsToInsert = new List<Lead>();
            for (Integer i = 0; i < 50; i++) {
                leadsToInsert.add(new Lead(
                    LastName = 'Bulk ' + i,
                    Company = '  Bulk    Company   ' + i + '  ',
                    Email = '  USER' + i + '@Example.COM  ',
                    Phone = '1-(212)-555-' + String.valueOf(1000 + i)
                ));
            }

            Test.startTest();
            insert leadsToInsert;
            Test.stopTest();

            List<Lead> savedLeads = [
                SELECT Email, Phone, Company
                FROM Lead
                WHERE Id IN :leadsToInsert
                WITH USER_MODE
                ORDER BY CreatedDate ASC
            ];

            System.assertEquals(50, savedLeads.size(), 'Expected all bulk leads to be inserted.');
            for (Integer i = 0; i < savedLeads.size(); i++) {
                Lead savedLead = savedLeads[i];
                System.assertEquals('user' + i + '@example.com', savedLead.Email, 'Bulk email should be normalized for record index ' + i + '.');
                System.assertEquals('212555' + String.valueOf(1000 + i), savedLead.Phone, 'Bulk phone should be normalized for record index ' + i + '.');
                System.assertEquals('Bulk Company ' + i, savedLead.Company, 'Bulk company should be normalized for record index ' + i + '.');
            }
        }
    }

    @IsTest
    static void testUpdateNormalizesFields() {
        User currentUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(currentUser) {
            Lead updatableLead = new Lead(
                LastName = 'Update',
                Company = 'Initial Co',
                Email = 'initial@example.com',
                Phone = '9999999999'
            );
            insert updatableLead;

            updatableLead.Email = '  UPDATED.User@Example.COM ';
            updatableLead.Phone = ' (1) 646-555-2020 ';
            updatableLead.Company = '  Updated     Company   Name  ';

            Test.startTest();
            update updatableLead;
            Test.stopTest();

            Lead savedLead = [
                SELECT Email, Phone, Company
                FROM Lead
                WHERE Id = :updatableLead.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('updated.user@example.com', savedLead.Email, 'Updated email should be normalized.');
            System.assertEquals('6465552020', savedLead.Phone, 'Updated phone should be normalized.');
            System.assertEquals('Updated Company Name', savedLead.Company, 'Updated company should be normalized.');
        }
    }
}
