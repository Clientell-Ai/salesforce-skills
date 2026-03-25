/**
 * @description Tests for HelloClientell.
 */
@IsTest
public with sharing class HelloClientellTest {
    /**
     * @description Verifies null and blank input return the default greeting.
     */
    @IsTest
    static void testHello_NullAndBlank_ReturnsDefaultGreeting() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Test.startTest();
            String nullResult = HelloClientell.hello(null);
            String blankResult = HelloClientell.hello('   ');
            Test.stopTest();

            System.assertEquals('Hello, Clientell!', nullResult, 'Null input should return default greeting.');
            System.assertEquals('Hello, Clientell!', blankResult, 'Blank input should return default greeting.');
        }
    }

    /**
     * @description Verifies non-blank input is trimmed and used in greeting.
     */
    @IsTest
    static void testHello_ValidName_ReturnsTrimmedGreeting() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Test.startTest();
            String result = HelloClientell.hello('  Sampat  ');
            Test.stopTest();

            System.assertEquals('Hello, Sampat!', result, 'Valid input should be trimmed and included in greeting.');
        }
    }
}
