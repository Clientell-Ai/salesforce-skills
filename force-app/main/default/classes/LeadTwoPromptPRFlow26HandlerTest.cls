/**
 * @description Tests for LeadTwoPromptPRFlow26Handler trigger behavior.
 */
@IsTest
public with sharing class LeadTwoPromptPRFlow26HandlerTest {

    /**
     * @description Verifies insert normalization trims names and lowercases email.
     */
    @IsTest
    static void testBeforeInsert_NormalizesLeadFields() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Lead leadToInsert = new Lead(
                FirstName = '  Jane  ',
                LastName = '  DOE  ',
                Company = 'Acme Inc',
                Email = '  Jane.DOE@Example.COM  '
            );

            Test.startTest();
            Database.insert(leadToInsert, AccessLevel.USER_MODE);
            Test.stopTest();

            Lead insertedLead = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :leadToInsert.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('Jane', insertedLead.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('DOE', insertedLead.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('jane.doe@example.com', insertedLead.Email, 'Email should be trimmed and lowercased on insert.');
        }
    }

    /**
     * @description Verifies update normalization and idempotent behavior for already normalized values.
     */
    @IsTest
    static void testBeforeUpdate_NormalizesAndDoesNotOverChange() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Lead leadToUpdate = new Lead(
                FirstName = 'John',
                LastName = 'Smith',
                Company = 'Global Corp',
                Email = 'john.smith@example.com'
            );
            Database.insert(leadToUpdate, AccessLevel.USER_MODE);

            leadToUpdate.FirstName = '  John  ';
            leadToUpdate.LastName = '  Smith  ';
            leadToUpdate.Email = '  JOHN.SMITH@EXAMPLE.COM  ';

            Test.startTest();
            Database.update(leadToUpdate, AccessLevel.USER_MODE);
            Test.stopTest();

            Lead normalizedLead = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :leadToUpdate.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('John', normalizedLead.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('Smith', normalizedLead.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('john.smith@example.com', normalizedLead.Email, 'Email should be trimmed and lowercased on update.');

            // Update unrelated field while values are already normalized; values should remain unchanged.
            leadToUpdate = [
                SELECT Id, FirstName, LastName, Email, Company
                FROM Lead
                WHERE Id = :leadToUpdate.Id
                WITH USER_MODE
                LIMIT 1
            ];
            leadToUpdate.Company = 'Global Corp Updated';
            Database.update(leadToUpdate, AccessLevel.USER_MODE);

            Lead unchangedLead = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :leadToUpdate.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('John', unchangedLead.FirstName, 'FirstName should remain unchanged when already normalized.');
            System.assertEquals('Smith', unchangedLead.LastName, 'LastName should remain unchanged when already normalized.');
            System.assertEquals('john.smith@example.com', unchangedLead.Email, 'Email should remain unchanged when already normalized.');
        }
    }
}
