/**
 * @description Test coverage for LeadNormalizationHandler and LeadNormalizationTrigger.
 */
@IsTest
public with sharing class LeadNormalizationHandlerTest {
    /**
     * @description Returns the current user for System.runAs usage.
     * @return A valid User record.
     */
    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    @IsTest
    static void testInsertContext_TrimsAndLowercases_ExpectedValues() {
        User runAsUser = getRunAsUser();
        System.runAs(runAsUser) {
            Lead leadRecord = new Lead(
                Company = 'Clientell',
                FirstName = '  Jane  ',
                LastName = '  DOE  ',
                Email = '  Jane.DOE@Example.COM  '
            );

            Test.startTest();
            LeadNormalizationHandler.normalize(new List<Lead>{ leadRecord });
            Test.stopTest();

            System.assertEquals('Jane', leadRecord.FirstName, 'FirstName should be trimmed in before-insert context.');
            System.assertEquals('DOE', leadRecord.LastName, 'LastName should be trimmed in before-insert context.');
            System.assertEquals('jane.doe@example.com', leadRecord.Email, 'Email should be trimmed and lowercased in before-insert context.');
        }
    }

    @IsTest
    static void testUpdateContext_ChangingValues_NormalizesAgain() {
        User runAsUser = getRunAsUser();
        System.runAs(runAsUser) {
            Lead leadRecord = new Lead(
                Company = 'Clientell',
                FirstName = 'Ava',
                LastName = 'Stone',
                Email = 'AVA@EXAMPLE.COM'
            );

            LeadNormalizationHandler.normalize(new List<Lead>{ leadRecord });

            leadRecord.FirstName = '  Ava-Marie  ';
            leadRecord.LastName = '  Stone Jr  ';
            leadRecord.Email = '  AVA.MARIE@EXAMPLE.COM  ';

            Test.startTest();
            LeadNormalizationHandler.normalize(new List<Lead>{ leadRecord });
            Test.stopTest();

            System.assertEquals('Ava-Marie', leadRecord.FirstName, 'FirstName should be trimmed in before-update context.');
            System.assertEquals('Stone Jr', leadRecord.LastName, 'LastName should be trimmed in before-update context.');
            System.assertEquals('ava.marie@example.com', leadRecord.Email, 'Email should be trimmed and lowercased in before-update context.');
        }
    }

    @IsTest
    static void testNullHandling_NullValues_NoExceptionAndNoMutation() {
        User runAsUser = getRunAsUser();
        System.runAs(runAsUser) {
            Lead leadRecord = new Lead(
                Company = 'Clientell',
                LastName = '  Null Last  '
            );

            Test.startTest();
            LeadNormalizationHandler.normalize(new List<Lead>{ leadRecord });
            Test.stopTest();

            System.assertEquals(null, leadRecord.FirstName, 'FirstName should remain null when null is provided.');
            System.assertEquals('Null Last', leadRecord.LastName, 'LastName should be trimmed when populated.');
            System.assertEquals(null, leadRecord.Email, 'Email should remain null when null is provided.');
        }
    }

    @IsTest
    static void testBulkContext_MultipleRecords_AllNormalized() {
        User runAsUser = getRunAsUser();
        System.runAs(runAsUser) {
            List<Lead> leadsToNormalize = new List<Lead>{
                new Lead(
                    Company = 'Clientell',
                    FirstName = '  One  ',
                    LastName = '  Alpha  ',
                    Email = '  ONE@EXAMPLE.COM  '
                ),
                new Lead(
                    Company = 'Clientell',
                    FirstName = '  Two  ',
                    LastName = '  Beta  ',
                    Email = '  Two.BETA@EXAMPLE.COM '
                )
            };

            Test.startTest();
            LeadNormalizationHandler.normalize(leadsToNormalize);
            Test.stopTest();

            System.assertEquals(2, leadsToNormalize.size(), 'Two leads should be processed in one transaction.');
            System.assertEquals('One', leadsToNormalize[0].FirstName, 'First record FirstName should be trimmed.');
            System.assertEquals('Alpha', leadsToNormalize[0].LastName, 'First record LastName should be trimmed.');
            System.assertEquals('one@example.com', leadsToNormalize[0].Email, 'First record Email should be normalized.');
            System.assertEquals('Two', leadsToNormalize[1].FirstName, 'Second record FirstName should be trimmed.');
            System.assertEquals('Beta', leadsToNormalize[1].LastName, 'Second record LastName should be trimmed.');
            System.assertEquals('two.beta@example.com', leadsToNormalize[1].Email, 'Second record Email should be normalized.');
        }
    }
}
