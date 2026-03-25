/**
 * @description Tests for ContactNormalizeTrigger_29 and ContactNormalizeTriggerHandler_29.
 */
@IsTest
public with sharing class ContactNormalizeTrigger_29_Test {

    /**
     * @description Verifies insert normalization, including null and already-normalized edge cases.
     */
    @IsTest
    static void testBeforeInsertNormalization() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact c1 = new Contact(
                LastName = '  mARY   ann  ',
                FirstName = '  joHN   DOE  ',
                Email = '  John.DOE@Example.COM  ',
                Phone = ' +1 (415) 555-1212 ',
                MailingStreet = '  123   Main   St  '
            );

            Contact c2 = new Contact(
                LastName = 'Smith',
                FirstName = null,
                Email = null,
                Phone = null,
                MailingStreet = null
            );

            Contact c3 = new Contact(
                LastName = 'Already Normalized',
                FirstName = 'Alice',
                Email = 'alice@example.com',
                Phone = '(212) 555-9999',
                MailingStreet = '500 Market St'
            );

            Test.startTest();
            insert new List<Contact>{ c1, c2, c3 };
            Test.stopTest();

            List<Contact> insertedContacts = [
                SELECT FirstName, LastName, Email, Phone, MailingStreet
                FROM Contact
                WHERE Id IN :new List<Id>{ c1.Id, c2.Id, c3.Id }
                WITH USER_MODE
            ];

            Map<Id, Contact> byId = new Map<Id, Contact>(insertedContacts);

            System.assertEquals('John Doe', byId.get(c1.Id).FirstName, 'FirstName should be proper-cased and collapsed.');
            System.assertEquals('Mary Ann', byId.get(c1.Id).LastName, 'LastName should be proper-cased and collapsed.');
            System.assertEquals('john.doe@example.com', byId.get(c1.Id).Email, 'Email should be trimmed and lowercased.');
            System.assertEquals('(415) 555-1212', byId.get(c1.Id).Phone, 'Phone should normalize to 10-digit display format.');
            System.assertEquals('123 Main St', byId.get(c1.Id).MailingStreet, 'MailingStreet should be trimmed and collapsed.');

            System.assertEquals(null, byId.get(c2.Id).FirstName, 'Null FirstName should remain null.');
            System.assertEquals('Smith', byId.get(c2.Id).LastName, 'Already normalized LastName should remain unchanged.');
            System.assertEquals(null, byId.get(c2.Id).Email, 'Null Email should remain null.');
            System.assertEquals(null, byId.get(c2.Id).Phone, 'Null Phone should remain null.');
            System.assertEquals(null, byId.get(c2.Id).MailingStreet, 'Null MailingStreet should remain null.');

            System.assertEquals('alice@example.com', byId.get(c3.Id).Email, 'Already normalized Email should remain unchanged.');
            System.assertEquals('(212) 555-9999', byId.get(c3.Id).Phone, 'Already normalized 10-digit phone should remain formatted.');
        }
    }

    /**
     * @description Verifies update normalization for phone variants and name whitespace cleanup.
     */
    @IsTest
    static void testBeforeUpdateNormalizationAndEdgePhones() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact c = new Contact(
                LastName = 'Initial',
                FirstName = 'Initial',
                Email = 'init@example.com',
                Phone = '9999999999',
                MailingStreet = '10 A St'
            );
            insert c;

            c.FirstName = '  sARAh   '; 
            c.LastName = '  oCONNOR   jr  ';
            c.Email = '  SARAH@Example.ORG ';
            c.Phone = '1-650-555-0000';
            c.MailingStreet = '  77   Sunset   Blvd  ';
            update c;

            Contact updated = [
                SELECT FirstName, LastName, Email, Phone, MailingStreet
                FROM Contact
                WHERE Id = :c.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('Sarah', updated.FirstName, 'FirstName should be normalized on update.');
            System.assertEquals('Oconnor Jr', updated.LastName, 'LastName should be normalized on update.');
            System.assertEquals('sarah@example.org', updated.Email, 'Email should be trimmed/lowercased on update.');
            System.assertEquals('(650) 555-0000', updated.Phone, '11-digit phone with leading 1 should drop country code and format.');
            System.assertEquals('77 Sunset Blvd', updated.MailingStreet, 'MailingStreet should be trimmed/collapsed on update.');

            c.Phone = '44 20 7946 0958';
            update c;

            Contact internationalUpdated = [SELECT Phone FROM Contact WHERE Id = :c.Id WITH USER_MODE LIMIT 1];
            System.assertEquals('442079460958', internationalUpdated.Phone, 'Non-10-digit phone should remain digits-only.');
        }
    }
}
