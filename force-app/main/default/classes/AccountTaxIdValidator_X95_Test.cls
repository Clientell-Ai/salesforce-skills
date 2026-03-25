/**
 * @description Tests for AccountTaxIdValidator_X95.
 */
@IsTest
public with sharing class AccountTaxIdValidator_X95_Test {
    private static final String CHARSET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    /**
     * @description Verifies a valid GSTIN passes validation methods.
     */
    @IsTest
    static void testValidGstin() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            String gstin = buildValidGstin('27ABCDE1234F1Z');

            Test.startTest();
            Boolean isValidValue = AccountTaxIdValidator_X95.isValid(gstin);
            String errorMessage = AccountTaxIdValidator_X95.getValidationError(gstin);
            Test.stopTest();

            System.assertEquals(true, isValidValue, 'Expected valid GSTIN to pass validation');
            System.assertEquals(null, errorMessage, 'Expected null validation error for valid GSTIN');
        }
    }

    /**
     * @description Verifies GSTIN fails when length is not 15.
     */
    @IsTest
    static void testInvalidLength() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            String gstin = '27ABCDE1234F1Z';

            Test.startTest();
            Boolean isValidValue = AccountTaxIdValidator_X95.isValid(gstin);
            String errorMessage = AccountTaxIdValidator_X95.getValidationError(gstin);
            Test.stopTest();

            System.assertEquals(false, isValidValue, 'Expected invalid length GSTIN to fail validation');
            System.assertEquals('GSTIN must be 15 characters', errorMessage, 'Expected invalid length error message');
        }
    }

    /**
     * @description Verifies GSTIN fails when state code has non-digits.
     */
    @IsTest
    static void testInvalidStateCode() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            String gstin = buildValidGstin('2AABCDE1234F1Z');

            Test.startTest();
            Boolean isValidValue = AccountTaxIdValidator_X95.isValid(gstin);
            String errorMessage = AccountTaxIdValidator_X95.getValidationError(gstin);
            Test.stopTest();

            System.assertEquals(false, isValidValue, 'Expected non-digit state code GSTIN to fail validation');
            System.assertEquals('Invalid state code', errorMessage, 'Expected invalid state code error message');
        }
    }

    /**
     * @description Verifies GSTIN fails when PAN segment pattern is invalid.
     */
    @IsTest
    static void testInvalidPanSegment() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            String gstin = buildValidGstin('27AB1DE1234F1Z');

            Test.startTest();
            Boolean isValidValue = AccountTaxIdValidator_X95.isValid(gstin);
            String errorMessage = AccountTaxIdValidator_X95.getValidationError(gstin);
            Test.stopTest();

            System.assertEquals(false, isValidValue, 'Expected invalid PAN segment GSTIN to fail validation');
            System.assertEquals('Invalid PAN segment', errorMessage, 'Expected invalid PAN segment error message');
        }
    }

    /**
     * @description Verifies GSTIN fails when entity code is 0.
     */
    @IsTest
    static void testInvalidEntityCodeZero() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            String gstin = buildValidGstin('27ABCDE1234F0Z');

            Test.startTest();
            Boolean isValidValue = AccountTaxIdValidator_X95.isValid(gstin);
            String errorMessage = AccountTaxIdValidator_X95.getValidationError(gstin);
            Test.stopTest();

            System.assertEquals(false, isValidValue, 'Expected entity code 0 GSTIN to fail validation');
            System.assertEquals('Invalid entity code', errorMessage, 'Expected invalid entity code error message');
        }
    }

    /**
     * @description Verifies GSTIN fails when 14th character is not Z.
     */
    @IsTest
    static void testInvalidFourteenthCharacter() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            String gstin = buildValidGstin('27ABCDE1234F1A');

            Test.startTest();
            Boolean isValidValue = AccountTaxIdValidator_X95.isValid(gstin);
            String errorMessage = AccountTaxIdValidator_X95.getValidationError(gstin);
            Test.stopTest();

            System.assertEquals(false, isValidValue, 'Expected invalid 14th character GSTIN to fail validation');
            System.assertEquals('14th character must be Z', errorMessage, 'Expected 14th character error message');
        }
    }

    /**
     * @description Verifies GSTIN fails when checksum character is altered.
     */
    @IsTest
    static void testInvalidChecksum() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            String validGstin = buildValidGstin('27ABCDE1234F1Z');
            String badCheckChar = (validGstin.endsWith('A')) ? 'B' : 'A';
            String gstin = validGstin.substring(0, 14) + badCheckChar;

            Test.startTest();
            Boolean isValidValue = AccountTaxIdValidator_X95.isValid(gstin);
            String errorMessage = AccountTaxIdValidator_X95.getValidationError(gstin);
            Test.stopTest();

            System.assertEquals(false, isValidValue, 'Expected bad checksum GSTIN to fail validation');
            System.assertEquals('Invalid checksum', errorMessage, 'Expected invalid checksum error message');
        }
    }

    /**
     * @description Verifies normalization handles whitespace and lowercase input.
     */
    @IsTest
    static void testNormalizationLowercaseAndWhitespace() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            String validGstin = buildValidGstin('27ABCDE1234F1Z');
            String noisyInput = '  ' + validGstin.substring(0, 5).toLowerCase() + ' ' +
                validGstin.substring(5, 10).toLowerCase() + '  ' +
                validGstin.substring(10).toLowerCase() + '  ';

            Test.startTest();
            Boolean isValidValue = AccountTaxIdValidator_X95.isValid(noisyInput);
            String errorMessage = AccountTaxIdValidator_X95.getValidationError(noisyInput);
            Test.stopTest();

            System.assertEquals(true, isValidValue, 'Expected normalized GSTIN input to pass validation');
            System.assertEquals(null, errorMessage, 'Expected null validation error after normalization');
        }
    }

    /**
     * @description Builds a valid GSTIN for a 14-character prefix by appending a valid checksum character.
     * @param first14 First 14 GSTIN characters.
     * @return Valid GSTIN string.
     */
    private static String buildValidGstin(String first14) {
        return first14 + computeCheckChar(first14);
    }

    /**
     * @description Computes the GSTIN checksum character for the first 14 characters.
     * @param first14 First 14 GSTIN characters.
     * @return Checksum character.
     */
    private static String computeCheckChar(String first14) {
        Integer sum = 0;
        Integer factor = 2;

        for (Integer i = first14.length() - 1; i >= 0; i--) {
            Integer codePoint = CHARSET.indexOf(first14.substring(i, i + 1));
            Integer product = codePoint * factor;
            Integer addend = (product / 36) + Math.mod(product, 36);
            sum += addend;
            factor = (factor == 2) ? 1 : 2;
        }

        Integer checkCodePoint = Math.mod(36 - Math.mod(sum, 36), 36);
        return CHARSET.substring(checkCodePoint, checkCodePoint + 1);
    }
}
