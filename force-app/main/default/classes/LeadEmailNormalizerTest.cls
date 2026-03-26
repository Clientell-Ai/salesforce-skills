/**
 * @description Test class for LeadEmailNormalizer.
 */
@IsTest
public with sharing class LeadEmailNormalizerTest {

    /**
     * @description Verifies normalization trims and lowercases email values.
     */
    @IsTest
    static void testNormalizeEmails_ValidAndNullInputs_ExpectedResults() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Lead leadWithEmail = new Lead(
                LastName = 'Test Lead',
                Company = 'Clientell',
                Email = '  USER.Name+Alias@Example.COM  '
            );
            Lead leadWithNullEmail = new Lead(
                LastName = 'Null Email Lead',
                Company = 'Clientell'
            );

            List<Lead> leadsToNormalize = new List<Lead>{
                leadWithEmail,
                leadWithNullEmail,
                null
            };

            Test.startTest();
            LeadEmailNormalizer.normalizeEmails(leadsToNormalize);
            LeadEmailNormalizer.normalizeEmails(null);
            LeadEmailNormalizer.normalizeEmails(new List<Lead>());
            Test.stopTest();

            System.assertEquals(
                'user.name+alias@example.com',
                leadWithEmail.Email,
                'Email should be trimmed and converted to lowercase.'
            );
            System.assertEquals(
                null,
                leadWithNullEmail.Email,
                'Null email value should remain null.'
            );
        }
    }
}
