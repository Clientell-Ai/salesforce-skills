/**
 * @description Tests for ContactNormalizeTrigger_19.
 */
@IsTest
public with sharing class ContactNormalizeTrigger_19_Test {
    /**
     * @description Verifies normalization on before insert in bulk with edge cases.
     */
    @IsTest
    static void testBeforeInsertBulkNormalization() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            List<Contact> contactsToInsert = new List<Contact>{
                new Contact(
                    LastName = '  Doe  ',
                    FirstName = '  John  ',
                    Email = '  JOHN.DOE@EXAMPLE.COM  ',
                    Title = '  Sr Manager  ',
                    Department = '  Sales  ',
                    Phone = '+1 (415) 555-1212',
                    MobilePhone = '415.555.9898',
                    MailingStreet = '  123   Main    St  '
                ),
                new Contact(
                    LastName = '  Smith  ',
                    Phone = '(212) 555-0000',
                    Email = '  Mixed.Case@Example.ORG '
                ),
                new Contact(
                    LastName = 'NullCase',
                    Phone = null,
                    MobilePhone = null,
                    Email = null,
                    MailingStreet = null,
                    FirstName = null,
                    Title = null,
                    Department = null
                ),
                new Contact(
                    LastName = 'DigitsOnly',
                    Phone = '12345',
                    MobilePhone = '+1-999-888-7777',
                    Email = ' DIGITS@Example.com '
                ),
                new Contact(
                    LastName = 'Spaces',
                    MailingStreet = '  Apt   4B   Building   2  '
                )
            };

            Test.startTest();
            insert contactsToInsert;
            Test.stopTest();

            List<Contact> insertedContacts = [
                SELECT FirstName, LastName, Email, Title, Department, Phone, MobilePhone, MailingStreet
                FROM Contact
                WHERE Id IN :contactsToInsert
                WITH USER_MODE
                ORDER BY LastName ASC
            ];

            Map<String, Contact> byLastName = new Map<String, Contact>();
            for (Contact contactRecord : insertedContacts) {
                byLastName.put(contactRecord.LastName, contactRecord);
            }

            Contact doe = byLastName.get('Doe');
            System.assertNotEquals(null, doe, 'Doe record should exist after insert.');
            System.assertEquals('John', doe.FirstName, 'FirstName should be trimmed.');
            System.assertEquals('john.doe@example.com', doe.Email, 'Email should be trimmed and lowercased.');
            System.assertEquals('Sr Manager', doe.Title, 'Title should be trimmed.');
            System.assertEquals('Sales', doe.Department, 'Department should be trimmed.');
            System.assertEquals('(415) 555-1212', doe.Phone, 'Phone should remove +1 and format to 10-digit style.');
            System.assertEquals('(415) 555-9898', doe.MobilePhone, 'MobilePhone should format from digits.');
            System.assertEquals('123 Main St', doe.MailingStreet, 'MailingStreet should collapse internal spaces.');

            Contact smith = byLastName.get('Smith');
            System.assertNotEquals(null, smith, 'Smith record should exist after insert.');
            System.assertEquals('(212) 555-0000', smith.Phone, 'Already formatted 10-digit phone should remain in canonical format.');
            System.assertEquals('mixed.case@example.org', smith.Email, 'Uppercase email should be lowercased.');

            Contact nullCase = byLastName.get('NullCase');
            System.assertNotEquals(null, nullCase, 'NullCase record should exist after insert.');
            System.assertEquals(null, nullCase.Phone, 'Null phone should remain null.');
            System.assertEquals(null, nullCase.MobilePhone, 'Null mobile should remain null.');
            System.assertEquals(null, nullCase.Email, 'Null email should remain null.');
            System.assertEquals(null, nullCase.MailingStreet, 'Null street should remain null.');

            Contact digitsOnly = byLastName.get('DigitsOnly');
            System.assertNotEquals(null, digitsOnly, 'DigitsOnly record should exist after insert.');
            System.assertEquals('12345', digitsOnly.Phone, 'Non-10-digit values should be digits-only.');
            System.assertEquals('(999) 888-7777', digitsOnly.MobilePhone, 'MobilePhone with +1 should remove prefix and format.');
            System.assertEquals('digits@example.com', digitsOnly.Email, 'Email should be normalized to lowercase.');

            Contact spaces = byLastName.get('Spaces');
            System.assertNotEquals(null, spaces, 'Spaces record should exist after insert.');
            System.assertEquals('Apt 4B Building 2', spaces.MailingStreet, 'Street spaces should collapse to one.');
        }
    }

    /**
     * @description Verifies normalization on before update.
     */
    @IsTest
    static void testBeforeUpdateNormalization() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Contact contactToUpdate = new Contact(
                LastName = 'UpdateCase',
                Phone = '4155551212',
                Email = 'initial@example.com'
            );
            insert contactToUpdate;

            contactToUpdate.FirstName = '  Alice  ';
            contactToUpdate.Email = '  ALICE.UPDATE@EXAMPLE.COM ';
            contactToUpdate.Phone = '+1 650 444 9999';
            contactToUpdate.MobilePhone = '333-444-5555';
            contactToUpdate.Title = '  Director  ';
            contactToUpdate.Department = '  Operations  ';
            contactToUpdate.MailingStreet = '  400   Market   St  ';

            Test.startTest();
            update contactToUpdate;
            Test.stopTest();

            Contact updated = [
                SELECT FirstName, LastName, Email, Phone, MobilePhone, Title, Department, MailingStreet
                FROM Contact
                WHERE Id = :contactToUpdate.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('Alice', updated.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('alice.update@example.com', updated.Email, 'Email should be normalized on update.');
            System.assertEquals('(650) 444-9999', updated.Phone, 'Phone should remove leading country code and format.');
            System.assertEquals('(333) 444-5555', updated.MobilePhone, 'MobilePhone should format on update.');
            System.assertEquals('Director', updated.Title, 'Title should trim on update.');
            System.assertEquals('Operations', updated.Department, 'Department should trim on update.');
            System.assertEquals('400 Market St', updated.MailingStreet, 'Street should collapse spaces on update.');
        }
    }
}
