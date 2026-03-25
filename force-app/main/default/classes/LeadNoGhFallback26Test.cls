/**
 * @description Tests LeadNoGhFallback26 trigger and LeadNoGhFallback26Handler normalization behavior.
 */
@IsTest
public with sharing class LeadNoGhFallback26Test {
    /**
     * @description Validates insert normalization for leading/trailing spaces in names and email casing.
     */
    @IsTest
    static void testInsert_NormalizesWhitespaceAndEmailCase() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                FirstName = '  Alice  ',
                LastName = '  Johnson  ',
                Company = 'Acme',
                Email = '  ALICE.JOHNSON@EXAMPLE.COM  '
            );

            Test.startTest();
            insert testLead;
            Test.stopTest();

            Lead insertedLead = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :testLead.Id
                LIMIT 1
            ];

            System.assertEquals('Alice', insertedLead.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Johnson', insertedLead.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('alice.johnson@example.com', insertedLead.Email, 'Email should be trimmed and lowercased on insert.');
        }
    }

    /**
     * @description Validates update normalization when user changes names and email.
     */
    @IsTest
    static void testUpdate_NormalizesChangedValues() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead testLead = new Lead(
                FirstName = 'John',
                LastName = 'Smith',
                Company = 'Acme',
                Email = 'john.smith@example.com'
            );
            insert testLead;

            testLead.FirstName = '  Johnny  ';
            testLead.LastName = '  Appleseed  ';
            testLead.Email = '  JOHNNY.APPLESEED@EXAMPLE.COM  ';

            Test.startTest();
            update testLead;
            Test.stopTest();

            Lead updatedLead = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :testLead.Id
                LIMIT 1
            ];

            System.assertEquals('Johnny', updatedLead.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('Appleseed', updatedLead.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('johnny.appleseed@example.com', updatedLead.Email, 'Email should be trimmed and lowercased on update.');
        }
    }

    /**
     * @description Validates null handling for FirstName, LastName, and Email.
     */
    @IsTest
    static void testNullValues_AreHandledSafely() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead nullLead = new Lead(
                FirstName = null,
                LastName = null,
                Company = 'Acme',
                Email = null
            );

            Test.startTest();
            insert nullLead;
            Test.stopTest();

            Lead insertedNullLead = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :nullLead.Id
                LIMIT 1
            ];

            System.assertEquals(null, insertedNullLead.FirstName, 'FirstName should remain null.');
            System.assertEquals(null, insertedNullLead.LastName, 'LastName should remain null.');
            System.assertEquals(null, insertedNullLead.Email, 'Email should remain null.');
        }
    }

    /**
     * @description Validates normalization for multiple records in one transaction.
     */
    @IsTest
    static void testBulkInsert_NormalizesMultipleRecords() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            List<Lead> leadList = new List<Lead>{
                new Lead(
                    FirstName = '  One  ',
                    LastName = '  Alpha  ',
                    Company = 'Acme',
                    Email = '  ONE.ALPHA@EXAMPLE.COM  '
                ),
                new Lead(
                    FirstName = '  Two  ',
                    LastName = '  Beta  ',
                    Company = 'Acme',
                    Email = '  TWO.BETA@EXAMPLE.COM  '
                ),
                new Lead(
                    FirstName = null,
                    LastName = '  Gamma  ',
                    Company = 'Acme',
                    Email = null
                )
            };

            Test.startTest();
            insert leadList;
            Test.stopTest();

            List<Lead> insertedLeads = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id IN :leadList
                ORDER BY LastName ASC
            ];

            System.assertEquals(3, insertedLeads.size(), 'Three leads should be inserted.');

            Lead alphaLead = insertedLeads[0];
            Lead betaLead = insertedLeads[1];
            Lead gammaLead = insertedLeads[2];

            System.assertEquals('One', alphaLead.FirstName, 'First lead FirstName should be trimmed.');
            System.assertEquals('Alpha', alphaLead.LastName, 'First lead LastName should be trimmed.');
            System.assertEquals('one.alpha@example.com', alphaLead.Email, 'First lead Email should be normalized.');

            System.assertEquals('Two', betaLead.FirstName, 'Second lead FirstName should be trimmed.');
            System.assertEquals('Beta', betaLead.LastName, 'Second lead LastName should be trimmed.');
            System.assertEquals('two.beta@example.com', betaLead.Email, 'Second lead Email should be normalized.');

            System.assertEquals(null, gammaLead.FirstName, 'Third lead FirstName should remain null.');
            System.assertEquals('Gamma', gammaLead.LastName, 'Third lead LastName should be trimmed.');
            System.assertEquals(null, gammaLead.Email, 'Third lead Email should remain null.');
        }
    }
}
