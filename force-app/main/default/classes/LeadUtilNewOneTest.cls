/**
 * @description Test class for LeadUtilNewOne.
 */
@IsTest
public with sharing class LeadUtilNewOneTest {

    @IsTest
    static void testFormatLeadName_WithCompany_ReturnsExpected() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(
                FirstName = 'Jane',
                LastName = 'Doe',
                Company = 'Acme'
            );
            insert l;

            Test.startTest();
            String result = LeadUtilNewOne.formatLeadName(l);
            Test.stopTest();

            System.assertEquals('Jane Doe (Acme)', result, 'Formatted lead name should include full name and company.');
        }
    }

    @IsTest
    static void testFormatLeadName_NoCompany_ReturnsNameOnly() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(
                FirstName = 'Sam',
                LastName = 'Hill',
                Company = ' '
            );
            insert l;

            Test.startTest();
            String result = LeadUtilNewOne.formatLeadName(l);
            Test.stopTest();

            System.assertEquals('Sam Hill', result, 'Formatted lead name should omit company when blank.');
        }
    }
}
