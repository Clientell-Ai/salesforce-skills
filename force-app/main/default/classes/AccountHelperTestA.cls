/**
 * @description Minimal test class for Account behavior validation.
 */
@IsTest
public with sharing class AccountHelperTestA {
    /**
     * @description Creates and verifies an Account record.
     */
    @IsTest
    static void testAccountInsertAndVerify() {
        User currentUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(currentUser) {
            Account testAccount = new Account(Name = 'AccountHelperTestA-Account');

            Test.startTest();
            Database.SaveResult insertResult = Database.insert(testAccount, AccessLevel.USER_MODE);
            Test.stopTest();

            System.assert(insertResult.isSuccess(), 'Account insert should succeed.');

            Account insertedAccount = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :testAccount.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertNotEquals(null, insertedAccount.Id, 'Inserted account Id should not be null.');
            System.assertEquals(
                'AccountHelperTestA-Account',
                insertedAccount.Name,
                'Inserted account name should match expected value.'
            );
        }
    }
}
