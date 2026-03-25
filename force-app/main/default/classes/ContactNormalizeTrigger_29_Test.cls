/**
 * @description Tests for ContactNormalizeTrigger_29.
 */
@IsTest
public with sharing class ContactNormalizeTrigger_29_Test {
    /**
     * @description Verifies insert normalization for trim, email lowercase, and phone formatting.
     */
    @IsTest
    static void testInsert_NormalizesFields() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Contact c = new Contact(
                LastName = '  Doe  ',
                FirstName = '  Jane  ',
                Email = '  Jane.DOE@Example.COM  ',
                Phone = ' (415) 555-1212 ',
                MobilePhone = ' +1-628-555-9999 '
            );

            Test.startTest();
            insert c;
            Test.stopTest();

            Contact inserted = [
                SELECT FirstName, LastName, Email, Phone, MobilePhone
                FROM Contact
                WHERE Id = :c.Id
                LIMIT 1
            ];

            System.assertEquals('Jane', inserted.FirstName, 'FirstName should be trimmed.');
            System.assertEquals('Doe', inserted.LastName, 'LastName should be trimmed.');
            System.assertEquals('jane.doe@example.com', inserted.Email, 'Email should be trimmed and lowercased.');
            System.assertEquals('(415) 555-1212', inserted.Phone, 'Phone should be normalized to 10-digit format.');
            System.assertEquals('+1 (628) 555-9999', inserted.MobilePhone, 'MobilePhone should be normalized to +1 11-digit format.');
        }
    }

    /**
     * @description Verifies normalization occurs in before update.
     */
    @IsTest
    static void testUpdate_NormalizesFields() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Contact c = new Contact(LastName = 'Smith');
            insert c;

            c.FirstName = '  John  ';
            c.Email = '  JOHN.SMITH@Example.COM  ';
            c.Phone = '1 (510) 777-2222';
            c.MobilePhone = ' ext 89 / 510-333-4444 ';

            Test.startTest();
            update c;
            Test.stopTest();

            Contact updated = [
                SELECT FirstName, Email, Phone, MobilePhone
                FROM Contact
                WHERE Id = :c.Id
                LIMIT 1
            ];

            System.assertEquals('John', updated.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('john.smith@example.com', updated.Email, 'Email should be lowercased on update.');
            System.assertEquals('+1 (510) 777-2222', updated.Phone, 'Phone should normalize 11 digits starting with 1.');
            System.assertEquals('(510) 333-4444', updated.MobilePhone, 'MobilePhone should normalize 10 digits after cleanup.');
        }
    }

    /**
     * @description Verifies bulk insert path handles 200 records and normalizes data.
     */
    @IsTest
    static void testBulkInsert_Handles200Records() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            List<Contact> contacts = new List<Contact>();
            for (Integer i = 0; i < 200; i++) {
                contacts.add(new Contact(
                    LastName = '  User ' + i + '  ',
                    FirstName = '  First ' + i + '  ',
                    Email = '  USER' + i + '@Example.COM  ',
                    Phone = ' (415) 555-' + String.valueOf(1000 + i),
                    MobilePhone = ' +1 (628) 555-' + String.valueOf(1000 + i)
                ));
            }

            Test.startTest();
            insert contacts;
            Test.stopTest();

            System.assertEquals(200, contacts.size(), 'Should insert all 200 contacts without exceptions.');

            List<Contact> sample = [
                SELECT FirstName, LastName, Email, Phone, MobilePhone
                FROM Contact
                WHERE Id IN :new List<Id>{contacts[0].Id, contacts[50].Id, contacts[199].Id}
            ];

            System.assertEquals(3, sample.size(), 'Should query three sample contacts.');
            for (Contact c : sample) {
                System.assert(c.FirstName != null && !c.FirstName.startsWith(' '), 'FirstName should be normalized in bulk.');
                System.assert(c.LastName != null && !c.LastName.endsWith(' '), 'LastName should be normalized in bulk.');
                System.assert(c.Email != null && c.Email == c.Email.toLowerCase(), 'Email should be lowercased in bulk.');
                System.assert(c.Phone != null && c.Phone.startsWith('(415)') , 'Phone should be formatted in bulk.');
            }
        }
    }
}
