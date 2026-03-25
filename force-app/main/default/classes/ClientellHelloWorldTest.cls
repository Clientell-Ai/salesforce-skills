/**
 * @description Test class for ClientellHelloWorld.
 */
@IsTest
public with sharing class ClientellHelloWorldTest {
    /**
     * @description Verifies hello returns expected value.
     */
    @IsTest
    static void testHelloReturnsExpectedValue() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Test.startTest();
            String result = ClientellHelloWorld.hello();
            Test.stopTest();

            System.assertEquals('Hello, World', result, 'hello should return the expected greeting.');
        }
    }
}
