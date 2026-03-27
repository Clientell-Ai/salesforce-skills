/**
 * @description Test class for LeadUtilNewOneShot.
 */
@IsTest
public with sharing class LeadUtilNewOneShotTest {

    @IsTest
    static void testNormalize_NullInput_ReturnsNull() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            Lead result = LeadUtilNewOneShot.normalize(null);
            Test.stopTest();

            System.assertEquals(null, result, 'Null input should return null');
        }
    }

    @IsTest
    static void testNormalize_FieldsTrimmedAndLowercased() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(
                FirstName = '  Ada ',
                LastName = '  Lovelace  ',
                Company = '  Analytical Engines  ',
                Title = '  Engineer  ',
                Email = '  ADA@EXAMPLE.COM ',
                Phone = ' (415) 555-1212 ',
                MobilePhone = '+1-415-555-0000'
            );

            Test.startTest();
            Lead result = LeadUtilNewOneShot.normalize(l);
            Test.stopTest();

            System.assertEquals('Ada', result.FirstName, 'FirstName should be trimmed');
            System.assertEquals('Lovelace', result.LastName, 'LastName should be trimmed');
            System.assertEquals('Analytical Engines', result.Company, 'Company should be trimmed');
            System.assertEquals('Engineer', result.Title, 'Title should be trimmed');
            System.assertEquals('ada@example.com', result.Email, 'Email should be trimmed and lowercased');
            System.assertEquals('4155551212', result.Phone, 'Phone should be digits only');
            System.assertEquals('14155550000', result.MobilePhone, 'MobilePhone should be digits only');
        }
    }

    @IsTest
    static void testNormalize_BlankFields_NoChange() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(
                FirstName = '',
                LastName = ' ',
                Company = null,
                Email = null,
                Phone = '   '
            );

            Test.startTest();
            Lead result = LeadUtilNewOneShot.normalize(l);
            Test.stopTest();

            System.assertEquals('', result.FirstName, 'Empty string should remain empty');
            System.assertEquals(' ', result.LastName, 'Whitespace-only should remain unchanged');
            System.assertEquals(null, result.Company, 'Null should remain null');
            System.assertEquals(null, result.Email, 'Null should remain null');
            System.assertEquals('   ', result.Phone, 'Whitespace-only should remain unchanged');
        }
    }
}
