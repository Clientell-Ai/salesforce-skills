/**
 * @description Tests ContactNormalizeTrigger_39 and its handler behavior.
 */
@IsTest
public with sharing class ContactNormalizeTrigger_39_Test {
    @IsTest
    static void testInsertNormalization() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Contact con = new Contact(
                LastName = '  o\'CONNOR-smith  ',
                FirstName = '  mARY   jANE  ',
                Email = '  TEst.User@Example.COM  ',
                Phone = '  (415) 555-1234  ',
                MailingStreet = '  123   Main   ST   Apt  2B  '
            );

            Test.startTest();
            insert con;
            Test.stopTest();

            Contact inserted = [
                SELECT FirstName, LastName, Email, Phone, MailingStreet
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
            ];

            System.assertEquals('Mary Jane', inserted.FirstName, 'FirstName should be proper-cased and whitespace-normalized.');
            System.assertEquals('O\'Connor-Smith', inserted.LastName, 'LastName should preserve apostrophes/hyphens with proper casing.');
            System.assertEquals('test.user@example.com', inserted.Email, 'Email should be trimmed and lowercased.');
            System.assertEquals('(415) 555-1234', inserted.Phone, 'Phone should be formatted for 10-digit US value.');
            System.assertEquals('123 Main ST Apt 2B', inserted.MailingStreet, 'Street should collapse internal whitespace.');
        }
    }

    @IsTest
    static void testUpdateNormalization() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Contact con = new Contact(
                LastName = 'Doe',
                FirstName = 'Jane',
                Email = 'jane@example.com',
                Phone = '1112223333',
                MailingStreet = '1 King Road'
            );
            insert con;

            con.FirstName = '  aNNE-mARIE  ';
            con.LastName = '  d\'ANGELO  ';
            con.Email = '  NEW.Email@EXAMPLE.ORG  ';
            con.Phone = '1 (650) 555-0099';
            con.MailingStreet = '  500   market    street ';

            Test.startTest();
            update con;
            Test.stopTest();

            Contact updated = [
                SELECT FirstName, LastName, Email, Phone, MailingStreet
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
            ];

            System.assertEquals('Anne-Marie', updated.FirstName, 'Hyphenated first name should be normalized.');
            System.assertEquals('D\'Angelo', updated.LastName, 'Apostrophe last name should be normalized.');
            System.assertEquals('new.email@example.org', updated.Email, 'Updated email should be normalized.');
            System.assertEquals('+1 (650) 555-0099', updated.Phone, '11-digit leading 1 phone should be formatted.');
            System.assertEquals('500 market street', updated.MailingStreet, 'Street whitespace should be normalized.');
        }
    }

    @IsTest
    static void testNullBlankHandling() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Contact con = new Contact(
                LastName = '   ',
                FirstName = '   ',
                Email = '   ',
                Phone = '  abc---  ',
                MailingStreet = '   '
            );

            Test.startTest();
            insert con;
            Test.stopTest();

            Contact inserted = [
                SELECT FirstName, LastName, Email, Phone, MailingStreet
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
            ];

            System.assertEquals(null, inserted.FirstName, 'Blank first name should become null.');
            System.assertEquals(null, inserted.LastName, 'Blank last name should become null.');
            System.assertEquals(null, inserted.Email, 'Blank email should become null.');
            System.assertEquals(null, inserted.Phone, 'Non-digit phone should become null.');
            System.assertEquals(null, inserted.MailingStreet, 'Blank mailing street should become null.');

            inserted.Phone = '+44 20 7946 0958';
            update inserted;

            Contact updated = [
                SELECT Phone
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
            ];
            System.assertEquals('442079460958', updated.Phone, 'Non-US phone should remain digits-only.');
        }
    }
}
