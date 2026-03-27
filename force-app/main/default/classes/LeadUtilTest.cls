/**
 * @description Test class for LeadUtil.
 */
@IsTest
public with sharing class LeadUtilTest {

    @IsTest
    static void testBuildLeadSummary_NullInput_ReturnsNull() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            String result = LeadUtil.buildLeadSummary(null);
            Test.stopTest();

            System.assertEquals(null, result, 'Expected null when input Lead is null');
        }
    }

    @IsTest
    static void testBuildLeadSummary_FieldsProvided_JoinsNonBlank() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead leadRecord = new Lead(
                Company = 'Acme Inc',
                Email = 'test@example.com',
                Status = 'Open - Not Contacted',
                LastName = 'Doe'
            );

            Test.startTest();
            String result = LeadUtil.buildLeadSummary(leadRecord);
            Test.stopTest();

            System.assertEquals('Acme Inc | test@example.com | Open - Not Contacted', result,
                'Expected summary to join non-blank fields in order');
        }
    }
}
