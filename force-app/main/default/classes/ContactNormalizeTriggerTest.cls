/**
 * @description Test class for ContactNormalizeTrigger.
 */
@IsTest
public with sharing class ContactNormalizeTriggerTest {

    @IsTest
    static void testSingleInsert_NormalizesWhitespaceAndCase() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Contact c = new Contact(
                FirstName = '   ',
                LastName = '  Doe ',
                Email = ' TeST@Example.COM '
            );

            insert c;

            Contact inserted = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :c.Id
                LIMIT 1
            ];
            System.assertEquals(null, inserted.FirstName, 'FirstName should be null when whitespace-only');
            System.assertEquals('Doe', inserted.LastName, 'LastName should be trimmed');
            System.assertEquals('test@example.com', inserted.Email, 'Email should be trimmed and lowercased');
        }
    }

    @IsTest
    static void testUpdate_NormalizesToNullAndLowercase() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Contact c = new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                Email = ' Jane@Example.COM '
            );
            insert c;

            c.FirstName = '   ';
            c.LastName = '   ';
            c.Email = '   ';
            update c;

            Contact updated = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :c.Id
                LIMIT 1
            ];
            System.assertEquals(null, updated.FirstName, 'FirstName should be null when updated with whitespace-only value');
            System.assertEquals(null, updated.LastName, 'LastName should be null when updated with whitespace-only value');
            System.assertEquals(null, updated.Email, 'Email should be null when updated with whitespace-only value');
        }
    }

    @IsTest
    static void testBulkInsert200_NormalizesAllRecords() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < 200; i++) {
                contactsToInsert.add(new Contact(
                    FirstName = '  First ' + i + '  ',
                    LastName = (Math.mod(i, 2) == 0) ? '   ' : '  Last ' + i + '  ',
                    Email = (Math.mod(i, 3) == 0) ? '   ' : ' USER' + i + '@Example.COM '
                ));
            }

            insert contactsToInsert;

            List<Contact> insertedContacts = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id IN :contactsToInsert
            ];
            System.assertEquals(200, insertedContacts.size(), 'All bulk records should be inserted');

            Integer nullLastNameCount = 0;
            Integer nullEmailCount = 0;
            for (Contact insertedContact : insertedContacts) {
                System.assert(insertedContact.FirstName != null, 'FirstName should be trimmed and populated');
                System.assert(!insertedContact.FirstName.startsWith(' '), 'FirstName should not have leading whitespace');
                System.assert(!insertedContact.FirstName.endsWith(' '), 'FirstName should not have trailing whitespace');

                if (insertedContact.LastName == null) {
                    nullLastNameCount++;
                } else {
                    System.assert(!insertedContact.LastName.startsWith(' '), 'LastName should not have leading whitespace');
                    System.assert(!insertedContact.LastName.endsWith(' '), 'LastName should not have trailing whitespace');
                }

                if (insertedContact.Email == null) {
                    nullEmailCount++;
                } else {
                    System.assertEquals(insertedContact.Email.toLowerCase(), insertedContact.Email, 'Email should be lowercase when present');
                    System.assert(!insertedContact.Email.startsWith(' '), 'Email should not have leading whitespace');
                    System.assert(!insertedContact.Email.endsWith(' '), 'Email should not have trailing whitespace');
                }
            }

            System.assertEquals(100, nullLastNameCount, 'Half of LastName values should normalize to null');
            System.assertEquals(67, nullEmailCount, 'Every third Email value should normalize to null');
        }
    }
}
