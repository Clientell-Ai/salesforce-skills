/**
 * @description Minimal test class for Account helper behavior.
 */
@IsTest
public with sharing class AccountHelperTest {

    @IsTest
    static void testAccountInsert_Minimal() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            // Arrange
            Account acc = new Account(Name = 'Test Account');

            // Act
            Test.startTest();
            insert acc;
            Test.stopTest();

            // Assert
            Account inserted = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :acc.Id
                WITH USER_MODE
                LIMIT 1
            ];
            System.assertEquals('Test Account', inserted.Name, 'Account Name should match');
        }
    }
}
