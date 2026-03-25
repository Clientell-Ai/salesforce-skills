/**
 * @description Tests for ContactNormalizeTriggerHandler_09.
 */
@IsTest
public with sharing class ContactNormalizeTriggerHandler_09_Test {

    @IsTest
    static void testInsertSingleContact_NormalizesEmailAndPhones() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Contact contactRecord = new Contact(
                LastName = 'Insert Normalize',
                Email = '  TEST.User+Tag@Example.COM  ',
                Phone = '  +1 (415) 555-1212  ',
                MobilePhone = ' (555) 888-0000 ',
                HomePhone = '  --  ',
                OtherPhone = ' ext 123 ',
                AssistantPhone = ' +44 20 7946 0958 ',
                Fax = ' ### '
            );

            Test.startTest();
            insert contactRecord;
            Test.stopTest();

            Contact insertedContact = [
                SELECT Email, Phone, MobilePhone, HomePhone, OtherPhone, AssistantPhone, Fax
                FROM Contact
                WHERE Id = :contactRecord.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('test.user+tag@example.com', insertedContact.Email, 'Email should be trimmed and lowercased.');
            System.assertEquals('+14155551212', insertedContact.Phone, 'Phone should preserve leading plus and keep digits only.');
            System.assertEquals('5558880000', insertedContact.MobilePhone, 'MobilePhone should keep digits only.');
            System.assertEquals(null, insertedContact.HomePhone, 'HomePhone should be null when no digits exist.');
            System.assertEquals('123', insertedContact.OtherPhone, 'OtherPhone should keep digits only.');
            System.assertEquals('+442079460958', insertedContact.AssistantPhone, 'AssistantPhone should preserve leading plus and digits.');
            System.assertEquals(null, insertedContact.Fax, 'Fax should be null when no digits exist.');
        }
    }

    @IsTest
    static void testUpdateContact_NormalizesEmailAndPhones() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runningUser) {
            Contact contactRecord = new Contact(
                LastName = 'Update Normalize',
                Email = 'initial@example.com',
                Phone = '1234567890'
            );
            insert contactRecord;

            contactRecord.Email = '  NEW.Email@Example.ORG  ';
            contactRecord.Phone = ' +91-(987) 654-3210 ';
            contactRecord.MobilePhone = '  abc  ';

            Test.startTest();
            update contactRecord;
            Test.stopTest();

            Contact updatedContact = [
                SELECT Email, Phone, MobilePhone
                FROM Contact
                WHERE Id = :contactRecord.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('new.email@example.org', updatedContact.Email, 'Updated Email should be trimmed and lowercased.');
            System.assertEquals('+919876543210', updatedContact.Phone, 'Updated Phone should preserve plus and digits only.');
            System.assertEquals(null, updatedContact.MobilePhone, 'Updated MobilePhone should be null when no digits exist.');
        }
    }

    @IsTest
    static void testBulkInsert200Contacts_NormalizesSample() {
        User runningUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runningUser) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer indexValue = 0; indexValue < 200; indexValue++) {
                contactsToInsert.add(new Contact(
                    LastName = 'Bulk Normalize ' + indexValue,
                    Email = '  USER' + indexValue + '@Example.COM  ',
                    Phone = ' +(123) 000-' + String.valueOf(indexValue).leftPad(4, '0') + ' ',
                    Fax = ' --- '
                ));
            }

            Test.startTest();
            insert contactsToInsert;
            Test.stopTest();

            Contact sampleContact = [
                SELECT Email, Phone, Fax
                FROM Contact
                WHERE Id = :contactsToInsert[199].Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('user199@example.com', sampleContact.Email, 'Bulk sample Email should be normalized.');
            System.assertEquals('+1230000199', sampleContact.Phone, 'Bulk sample Phone should be normalized.');
            System.assertEquals(null, sampleContact.Fax, 'Bulk sample Fax should be null when no digits exist.');
        }
    }
}
