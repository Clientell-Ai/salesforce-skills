/**
 * @description Test class for AccountValidatorClass_22.
 */
@IsTest
public with sharing class AccountValidatorClass_22_Test {

    /**
     * @description Valid account should return no errors and valid result.
     */
    @IsTest
    static void testValidate_ValidAccount_NoErrors() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            List<Account> accounts = new List<Account>{
                new Account(
                    Name = 'Acme Corp',
                    Industry = 'Technology',
                    Phone = '(415) 555-1234'
                )
            };

            Test.startTest();
            List<String> errors = AccountValidatorClass_22.validateForInsert(accounts);
            AccountValidatorClass_22.ValidationResult result = AccountValidatorClass_22.validate(accounts);
            Test.stopTest();

            System.assertEquals(0, errors.size(), 'Valid account should not produce errors.');
            System.assertEquals(true, result.isValid, 'Result should be valid for a valid account.');
            System.assertEquals(0, result.errors.size(), 'ValidationResult should have no errors for valid input.');
        }
    }

    /**
     * @description Missing name should produce a required-name error.
     */
    @IsTest
    static void testValidate_MissingName_HasError() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            List<Account> accounts = new List<Account>{
                new Account(
                    Name = ' ',
                    Industry = 'Technology',
                    Phone = '4155551234'
                )
            };

            Test.startTest();
            List<String> errors = AccountValidatorClass_22.validateForInsert(accounts);
            AccountValidatorClass_22.ValidationResult result = AccountValidatorClass_22.validate(accounts);
            Test.stopTest();

            System.assertEquals(1, errors.size(), 'Missing name should produce exactly one error.');
            System.assert(errors[0].contains('Name is required'), 'Error should indicate that Name is required.');
            System.assertEquals(false, result.isValid, 'ValidationResult should be invalid when name is missing.');
        }
    }

    /**
     * @description Industry of Other should produce a business-rule error.
     */
    @IsTest
    static void testValidate_IndustryOther_HasError() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            List<Account> accounts = new List<Account>{
                new Account(
                    Name = 'Globex',
                    Industry = 'Other',
                    Phone = '4155551234'
                )
            };

            Test.startTest();
            List<String> errors = AccountValidatorClass_22.validateForInsert(accounts);
            AccountValidatorClass_22.ValidationResult result = AccountValidatorClass_22.validate(accounts);
            Test.stopTest();

            System.assertEquals(1, errors.size(), 'Industry Other should produce exactly one error.');
            System.assert(errors[0].contains('Industry cannot be Other'), 'Error should indicate Industry cannot be Other.');
            System.assertEquals(false, result.isValid, 'ValidationResult should be invalid when Industry is Other.');
        }
    }

    /**
     * @description Phone with fewer than 10 digits should produce a phone-length error.
     */
    @IsTest
    static void testValidate_ShortPhone_HasError() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            List<Account> accounts = new List<Account>{
                new Account(
                    Name = 'Initech',
                    Industry = 'Finance',
                    Phone = '123-45'
                )
            };

            Test.startTest();
            List<String> errors = AccountValidatorClass_22.validateForInsert(accounts);
            AccountValidatorClass_22.ValidationResult result = AccountValidatorClass_22.validate(accounts);
            Test.stopTest();

            System.assertEquals(1, errors.size(), 'Short phone should produce exactly one error.');
            System.assert(errors[0].contains('at least 10 digits'), 'Error should indicate phone length requirement.');
            System.assertEquals(false, result.isValid, 'ValidationResult should be invalid for short phone.');
        }
    }
}
