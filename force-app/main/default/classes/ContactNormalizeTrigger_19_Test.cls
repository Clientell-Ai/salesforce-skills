/**
 * @description Tests for ContactNormalizeTrigger_19 and its handler.
 */
@IsTest
public with sharing class ContactNormalizeTrigger_19_Test {
    @IsTest
    static void testInsert_NormalizesEmail() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Contact con = new Contact(
                LastName = '  Doe  ',
                Email = '  JOHN.DOE@EXAMPLE.COM  '
            );

            insert con;

            Contact inserted = [
                SELECT LastName, Email
                FROM Contact
                WHERE Id = :con.Id
                LIMIT 1
            ];
            System.assertEquals('Doe', inserted.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('john.doe@example.com', inserted.Email, 'Email should be trimmed and lowercased on insert.');
        }
    }

    @IsTest
    static void testUpdate_NormalizesPhone() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Contact con = new Contact(LastName = 'Smith');
            insert con;

            con.Phone = ' +1 (415) 555-1212 ';
            update con;

            Contact updated = [
                SELECT Phone
                FROM Contact
                WHERE Id = :con.Id
                LIMIT 1
            ];
            System.assertEquals('+14155551212', updated.Phone, 'Phone should be normalized on update.');
        }
    }

    @IsTest
    static void testBulkInsert_200Contacts() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            List<Contact> contacts = new List<Contact>();
            for (Integer i = 0; i < 200; i++) {
                contacts.add(new Contact(
                    LastName = '  User ' + i + '  ',
                    Email = '  USER' + i + '@EXAMPLE.COM  '
                ));
            }

            Test.startTest();
            insert contacts;
            Test.stopTest();

            List<Contact> insertedContacts = [
                SELECT LastName, Email
                FROM Contact
                WHERE Id IN :contacts
            ];
            System.assertEquals(200, insertedContacts.size(), 'Bulk insert should create all 200 contacts.');
            System.assertEquals('user0@example.com', insertedContacts[0].Email, 'Emails should be normalized in bulk insert.');
            System.assert(insertedContacts[0].LastName.startsWith('User '), 'LastName should be trimmed in bulk insert.');
        }
    }
}
