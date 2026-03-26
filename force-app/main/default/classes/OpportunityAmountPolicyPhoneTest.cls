/**
 * @description Test class for OpportunityAmountPolicyPhone.
 */
@IsTest
public with sharing class OpportunityAmountPolicyPhoneTest {
    private static final Decimal THRESHOLD = 10000;

    @TestSetup
    static void setupData() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            insert new List<Account>{
                new Account(Name = 'Account With Phone', Phone = '4155550100'),
                new Account(Name = 'Account Without Phone')
            };
        }
    }

    /**
     * @description Verifies high amount opportunities fail when related account phone is blank.
     */
    @IsTest
    static void testEnforce_HighAmountWithoutPhone_AddsError() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Account noPhoneAccount = [
                SELECT Id
                FROM Account
                WHERE Name = 'Account Without Phone'
                LIMIT 1
            ];

            Opportunity testOpportunity = new Opportunity(
                Name = 'High Amount Missing Phone',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 25000,
                AccountId = noPhoneAccount.Id
            );

            Test.startTest();
            OpportunityAmountPolicyPhone.enforce(new List<Opportunity>{ testOpportunity }, THRESHOLD);
            Database.SaveResult saveResult = Database.insert(testOpportunity, false, AccessLevel.USER_MODE);
            Test.stopTest();

            System.assertEquals(false, saveResult.isSuccess(), 'Insert should fail when account phone is missing for high amount.');
            System.assertEquals(true, saveResult.getErrors()[0].getMessage().contains('Account Phone is required'), 'Error message should indicate missing account phone.');
        }
    }

    /**
     * @description Verifies high amount opportunities pass when related account has a phone.
     */
    @IsTest
    static void testEnforce_HighAmountWithPhone_AllowsSave() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Account withPhoneAccount = [
                SELECT Id
                FROM Account
                WHERE Name = 'Account With Phone'
                LIMIT 1
            ];

            Opportunity testOpportunity = new Opportunity(
                Name = 'High Amount With Phone',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 30000,
                AccountId = withPhoneAccount.Id
            );

            Test.startTest();
            OpportunityAmountPolicyPhone.enforce(new List<Opportunity>{ testOpportunity }, THRESHOLD);
            Database.SaveResult saveResult = Database.insert(testOpportunity, false, AccessLevel.USER_MODE);
            Test.stopTest();

            System.assertEquals(true, saveResult.isSuccess(), 'Insert should succeed when account phone is present for high amount.');
        }
    }

    /**
     * @description Verifies low amount opportunities are not blocked by this policy.
     */
    @IsTest
    static void testEnforce_LowAmountWithoutPhone_AllowsSave() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Account noPhoneAccount = [
                SELECT Id
                FROM Account
                WHERE Name = 'Account Without Phone'
                LIMIT 1
            ];

            Opportunity testOpportunity = new Opportunity(
                Name = 'Low Amount Missing Phone',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 5000,
                AccountId = noPhoneAccount.Id
            );

            Test.startTest();
            OpportunityAmountPolicyPhone.enforce(new List<Opportunity>{ testOpportunity }, THRESHOLD);
            Database.SaveResult saveResult = Database.insert(testOpportunity, false, AccessLevel.USER_MODE);
            Test.stopTest();

            System.assertEquals(true, saveResult.isSuccess(), 'Insert should succeed when amount is below threshold.');
        }
    }
}
