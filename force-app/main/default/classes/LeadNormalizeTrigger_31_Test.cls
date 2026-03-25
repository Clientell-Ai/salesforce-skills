/**
 * @description Test class for LeadNormalizeTrigger_31.
 */
@IsTest
public with sharing class LeadNormalizeTrigger_31_Test {

    @IsTest
    static void testBeforeInsertNormalization() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Lead testLead = new Lead(
                FirstName = '  John  ',
                LastName = '  Doe  ',
                Company = '  Acme Corp  ',
                Email = '  John.Doe@Example.COM  ',
                Phone = ' (415) 555-2671 '
            );

            Test.startTest();
            insert testLead;
            Test.stopTest();

            Lead insertedLead = [
                SELECT FirstName, LastName, Company, Email, Phone
                FROM Lead
                WHERE Id = :testLead.Id
                WITH USER_MODE
            ];

            System.assertEquals('John', insertedLead.FirstName, 'FirstName should be trimmed.');
            System.assertEquals('Doe', insertedLead.LastName, 'LastName should be trimmed.');
            System.assertEquals('Acme Corp', insertedLead.Company, 'Company should be trimmed.');
            System.assertEquals('john.doe@example.com', insertedLead.Email, 'Email should be trimmed and lowercased.');
            System.assertEquals('(415) 555-2671', insertedLead.Phone, 'Phone should be formatted as 10-digit US number.');
        }
    }

    @IsTest
    static void testBeforeUpdateNormalization() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Lead testLead = new Lead(
                LastName = 'Original',
                Company = 'Original Co',
                Email = 'orig@example.com',
                Phone = '9999999999'
            );
            insert testLead;

            testLead.FirstName = '  Jane  ';
            testLead.LastName = '  Smith  ';
            testLead.Company = '  Example LLC  ';
            testLead.Email = '  JANE.SMITH@EXAMPLE.COM  ';
            testLead.Phone = ' 1-415-555-2671 ';

            Test.startTest();
            update testLead;
            Test.stopTest();

            Lead updatedLead = [
                SELECT FirstName, LastName, Company, Email, Phone
                FROM Lead
                WHERE Id = :testLead.Id
                WITH USER_MODE
            ];

            System.assertEquals('Jane', updatedLead.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('Smith', updatedLead.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('Example LLC', updatedLead.Company, 'Company should be trimmed on update.');
            System.assertEquals('jane.smith@example.com', updatedLead.Email, 'Email should be lowercased on update.');
            System.assertEquals('+1 (415) 555-2671', updatedLead.Phone, 'Phone should format for 11-digit number starting with 1.');
        }
    }
}
