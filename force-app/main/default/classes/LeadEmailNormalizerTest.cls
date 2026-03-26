/**
 * @description Test coverage for LeadEmailNormalizer.
 */
@IsTest
public with sharing class LeadEmailNormalizerTest {

    @IsTest
    static void testNormalizeLeadEmails_MixedInputs_ExpectedNormalization() {
        User runAsUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        System.runAs(runAsUser) {
            List<Lead> leads = new List<Lead>{
                new Lead(LastName = 'One', Company = 'Acme', Email = '  Test.User@Example.COM  '),
                new Lead(LastName = 'Two', Company = 'Acme', Email = '   '),
                new Lead(LastName = 'Three', Company = 'Acme'),
                null
            };

            Test.startTest();
            LeadEmailNormalizer.normalizeLeadEmails(leads);
            Test.stopTest();

            System.assertEquals('test.user@example.com', leads[0].Email, 'Email should be trimmed and lowercased.');
            System.assertEquals(null, leads[1].Email, 'Blank email should become null.');
            System.assertEquals(null, leads[2].Email, 'Null email should remain null.');
            System.assertEquals(4, leads.size(), 'List size should remain unchanged.');
        }
    }
}
