/**
 * @description Test class for ContactNormalizeTriggerHandler and ContactNormalizeTrigger_21.
 */
@IsTest
public with sharing class ContactNormalizeTriggerHandlerTest {

    /**
     * @description Verifies single-record insert normalization.
     */
    @IsTest
    static void testSingleInsertNormalization() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Contact con = new Contact(
                FirstName = '  John  ',
                LastName = '  Doe  ',
                Email = '  JOHN.DOE@EXAMPLE.COM  '
            );

            Test.startTest();
            insert con;
            Test.stopTest();

            Contact insertedCon = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
            ];
            System.assertEquals('John', insertedCon.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Doe', insertedCon.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('john.doe@example.com', insertedCon.Email, 'Email should be trimmed and lowercased on insert.');
        }
    }

    /**
     * @description Verifies bulk insert normalization for 200 contacts.
     */
    @IsTest
    static void testBulkInsertNormalization() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < 200; i++) {
                contactsToInsert.add(new Contact(
                    FirstName = '  BulkFirst' + i + '  ',
                    LastName = '  BulkLast' + i + '  ',
                    Email = '  USER' + i + '@EXAMPLE.COM  '
                ));
            }

            Test.startTest();
            insert contactsToInsert;
            Test.stopTest();

            List<Contact> insertedContacts = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id IN :contactsToInsert
                WITH USER_MODE
                ORDER BY CreatedDate ASC
            ];

            System.assertEquals(200, insertedContacts.size(), 'Exactly 200 contacts should be inserted.');
            for (Contact con : insertedContacts) {
                System.assert(!con.FirstName.startsWith(' '), 'FirstName should not start with whitespace.');
                System.assert(!con.FirstName.endsWith(' '), 'FirstName should not end with whitespace.');
                System.assert(!con.LastName.startsWith(' '), 'LastName should not start with whitespace.');
                System.assert(!con.LastName.endsWith(' '), 'LastName should not end with whitespace.');
                System.assertEquals(con.Email, con.Email.toLowerCase(), 'Email should be lowercase after normalization.');
                System.assert(!con.Email.startsWith(' '), 'Email should not start with whitespace.');
                System.assert(!con.Email.endsWith(' '), 'Email should not end with whitespace.');
            }
        }
    }

    /**
     * @description Verifies update normalization when values contain surrounding spaces and mixed-case email.
     */
    @IsTest
    static void testUpdateNormalization() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Contact con = new Contact(
                FirstName = 'Initial',
                LastName = 'Person',
                Email = 'initial@example.com'
            );
            insert con;

            con.FirstName = '  Updated  ';
            con.LastName = '  Name  ';
            con.Email = '  UPDATED.EMAIL@EXAMPLE.COM  ';

            Test.startTest();
            update con;
            Test.stopTest();

            Contact updatedCon = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
            ];
            System.assertEquals('Updated', updatedCon.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('Name', updatedCon.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('updated.email@example.com', updatedCon.Email, 'Email should be trimmed and lowercased on update.');
        }
    }
}
