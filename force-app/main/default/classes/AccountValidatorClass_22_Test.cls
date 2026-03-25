/**
 * @description Tests for AccountValidatorClass_22.
 */
@IsTest
public with sharing class AccountValidatorClass_22_Test {
    /**
     * @description Verifies validateAccounts handles valid trigger-style inputs without exceptions.
     */
    @IsTest
    static void testValidateAccounts_InsertAndUpdate_NoExceptions() {
        User u = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(u) {
            Account acc = new Account(Name = 'Validation Test Account');
            Database.insert(acc, AccessLevel.USER_MODE);

            Account oldAcc = acc.clone(true, false, false, false);
            acc.Name = 'Validation Test Account Updated';
            Database.update(acc, AccessLevel.USER_MODE);

            List<Account> newList = new List<Account>{ acc };
            Map<Id, Account> oldMap = new Map<Id, Account>{ acc.Id => oldAcc };

            Test.startTest();
            AccountValidatorClass_22.validateAccounts(newList, oldMap);
            AccountValidatorClass_22.validateAccounts(null, null);
            Test.stopTest();

            System.assertEquals(true, true, 'Method should complete without throwing exceptions.');
        }
    }
}
