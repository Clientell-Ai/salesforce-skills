/**
 * @description Test class for LeadUtilK.
 */
@IsTest
public with sharing class LeadUtilKTest {

    /**
     * @description Verifies formatted output when Lead fields are populated.
     */
    @IsTest
    static void testBuildLeadDisplayString_WithValues_ReturnsFormattedString() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead leadRecord = new Lead(
                FirstName = 'Ava',
                LastName = 'Lopez',
                Company = 'Acme Inc',
                Status = 'Working - Contacted'
            );

            Test.startTest();
            String result = LeadUtilK.buildLeadDisplayString(leadRecord);
            Test.stopTest();

            System.assertEquals(
                'Ava Lopez | Acme Inc | Working - Contacted',
                result,
                'Display string should include name, company, and status in the expected format.'
            );
        }
    }

    /**
     * @description Verifies null input returns an empty string.
     */
    @IsTest
    static void testBuildLeadDisplayString_NullLead_ReturnsEmptyString() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Test.startTest();
            String result = LeadUtilK.buildLeadDisplayString(null);
            Test.stopTest();

            System.assertEquals('', result, 'Null lead input should return an empty string.');
        }
    }
}
