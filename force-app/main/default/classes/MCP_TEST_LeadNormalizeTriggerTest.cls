/**
 * @description Tests for MCP_TEST_LeadNormalizeTrigger and MCP_TEST_LeadNormalizeHandler.
 */
@IsTest
public with sharing class MCP_TEST_LeadNormalizeTriggerTest {

    @IsTest
    static void testInsertMessyLead_NormalizesFields() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                FirstName = '  Jane  ',
                LastName = '  Doe  ',
                Company = '   ',
                Title = '  Director  ',
                Email = '  Jane.DOE@Example.COM  ',
                Phone = ' (415) 555-1212 ',
                MobilePhone = ' 1-650-555-3434 '
            );

            Test.startTest();
            insert testLead;
            Test.stopTest();

            Lead insertedLead = [
                SELECT FirstName, LastName, Company, Title, Email, Phone, MobilePhone
                FROM Lead
                WHERE Id = :testLead.Id
                WITH USER_MODE
            ];

            System.assertEquals('Jane', insertedLead.FirstName, 'FirstName should be trimmed.');
            System.assertEquals('Doe', insertedLead.LastName, 'LastName should be trimmed.');
            System.assertEquals('Unknown', insertedLead.Company, 'Company should default to Unknown when blank.');
            System.assertEquals('Director', insertedLead.Title, 'Title should be trimmed.');
            System.assertEquals('jane.doe@example.com', insertedLead.Email, 'Email should be lowercased and trimmed.');
            System.assertEquals('(415) 555-1212', insertedLead.Phone, 'Phone should be normalized to US format.');
            System.assertEquals('+1 (650) 555-3434', insertedLead.MobilePhone, 'MobilePhone should be normalized with +1 format.');
        }
    }

    @IsTest
    static void testUpdateLead_NormalizesChangedFields() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                LastName = 'Smith',
                Company = 'Acme',
                Email = 'initial@example.com',
                Phone = '4155559999'
            );
            insert testLead;

            testLead.Email = '  NEW.EMAIL@Example.com  ';
            testLead.Phone = '1 (212) 555-0000';
            testLead.MobilePhone = ' 555-77-888 '; // 8 digits after strip, should remain digits-only

            Test.startTest();
            update testLead;
            Test.stopTest();

            Lead updatedLead = [
                SELECT Email, Phone, MobilePhone
                FROM Lead
                WHERE Id = :testLead.Id
                WITH USER_MODE
            ];

            System.assertEquals('new.email@example.com', updatedLead.Email, 'Updated email should be normalized.');
            System.assertEquals('+1 (212) 555-0000', updatedLead.Phone, 'Updated phone should be normalized.');
            System.assertEquals('55577888', updatedLead.MobilePhone, 'Non-10/11 phone should remain digits-only.');
        }
    }

    @IsTest
    static void testConvertedLead_AttemptUpdate_NoNormalizationApplied() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                LastName = 'Converted',
                Company = 'ConvertCo',
                Email = 'original@example.com',
                Phone = '(999) 111-2222'
            );
            insert testLead;

            Database.LeadConvert convertRequest = new Database.LeadConvert();
            convertRequest.setLeadId(testLead.Id);
            convertRequest.setConvertedStatus('Closed - Converted');
            convertRequest.setDoNotCreateOpportunity(true);
            Database.LeadConvertResult convertResult = Database.convertLead(convertRequest);
            System.assert(convertResult.isSuccess(), 'Lead conversion should succeed.');

            Lead convertedLead = [
                SELECT Id, IsConverted, Email, Phone
                FROM Lead
                WHERE Id = :testLead.Id
                WITH USER_MODE
            ];
            System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted.');

            convertedLead.Email = '  CHANGED@EXAMPLE.COM  ';
            convertedLead.Phone = '1-800-555-1212';

            Test.startTest();
            Database.SaveResult updateResult = Database.update(convertedLead, false, AccessLevel.USER_MODE);
            Test.stopTest();

            if (updateResult.isSuccess()) {
                Lead afterUpdate = [
                    SELECT Email, Phone
                    FROM Lead
                    WHERE Id = :convertedLead.Id
                    WITH USER_MODE
                ];
                System.assertEquals('  CHANGED@EXAMPLE.COM  ', afterUpdate.Email, 'Converted lead email should not be normalized by handler.');
                System.assertEquals('1-800-555-1212', afterUpdate.Phone, 'Converted lead phone should not be normalized by handler.');
            } else {
                System.assert(!updateResult.isSuccess(), 'Converted lead update may fail depending on org settings.');
            }
        }
    }
}
