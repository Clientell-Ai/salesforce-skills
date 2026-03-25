/**
 * @description Test class for AccountValidatorClass_42.
 */
@IsTest
private with sharing class AccountValidatorClass_42Test {
    /**
     * @description Verifies that a valid account passes validation.
     */
    @IsTest
    static void testValidAccountPasses() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Account validAccount = new Account(
                Name = 'Acme Corp',
                Phone = '(415) 555-1212',
                Website = 'https://example.com'
            );

            Test.startTest();
            AccountValidatorClass_42.validate(new List<Account>{ validAccount });
            Test.stopTest();

            System.assert(true, 'Validation should pass for a valid account.');
        }
    }

    /**
     * @description Verifies blank name fails validation.
     */
    @IsTest
    static void testBlankNameFails() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Account invalidAccount = new Account(
                Name = '   ',
                Phone = '4155551212',
                Website = 'https://example.com'
            );

            Test.startTest();
            try {
                AccountValidatorClass_42.validate(new List<Account>{ invalidAccount });
                System.assert(false, 'Expected validation exception for blank account name.');
            } catch (AccountValidatorClass_42.AccountValidationException ex) {
                System.assert(
                    ex.getMessage().contains('Name cannot be blank'),
                    'Exception message should mention blank name. Message: ' + ex.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description Verifies short phone number fails validation.
     */
    @IsTest
    static void testPhoneUnderTenDigitsFails() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Account invalidAccount = new Account(
                Name = 'Acme Corp',
                Phone = '123-456',
                Website = 'https://example.com'
            );

            Test.startTest();
            try {
                AccountValidatorClass_42.validate(new List<Account>{ invalidAccount });
                System.assert(false, 'Expected validation exception for phone with fewer than 10 digits.');
            } catch (AccountValidatorClass_42.AccountValidationException ex) {
                System.assert(
                    ex.getMessage().contains('at least 10 digits'),
                    'Exception message should mention minimum phone digits. Message: ' + ex.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description Verifies website without required scheme fails validation.
     */
    @IsTest
    static void testWebsiteWithoutSchemeFails() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Account invalidAccount = new Account(
                Name = 'Acme Corp',
                Phone = '4155551212',
                Website = 'example.com'
            );

            Test.startTest();
            try {
                AccountValidatorClass_42.validate(new List<Account>{ invalidAccount });
                System.assert(false, 'Expected validation exception for website without scheme.');
            } catch (AccountValidatorClass_42.AccountValidationException ex) {
                System.assert(
                    ex.getMessage().contains('must start with http:// or https://'),
                    'Exception message should mention website scheme requirement. Message: ' + ex.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description Verifies bulk validation fails when one record is invalid.
     */
    @IsTest
    static void testBulkValidationOneFails() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Account validOne = new Account(
                Name = 'Valid One',
                Phone = '4155551111',
                Website = 'http://valid-one.example'
            );
            Account invalidMid = new Account(
                Name = 'Invalid Mid',
                Phone = '9999',
                Website = 'https://valid.example'
            );
            Account validTwo = new Account(
                Name = 'Valid Two',
                Phone = '4155552222',
                Website = 'https://valid-two.example'
            );

            List<Account> accounts = new List<Account>{ validOne, invalidMid, validTwo };

            Test.startTest();
            try {
                AccountValidatorClass_42.validate(accounts);
                System.assert(false, 'Expected validation exception for bulk list containing invalid phone.');
            } catch (AccountValidatorClass_42.AccountValidationException ex) {
                System.assert(
                    ex.getMessage().contains('at least 10 digits'),
                    'Exception should indicate phone digit failure in bulk validation. Message: ' + ex.getMessage()
                );
            }
            Test.stopTest();
        }
    }
}
