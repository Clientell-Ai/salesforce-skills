/**
 * @description Tests for ContactNormalizeTrigger39Handler and ContactNormalizeTrigger_39.
 */
@IsTest
public with sharing class ContactNormalizeTrigger39HandlerTest {
    /**
     * @description Validates single-record insert normalization.
     */
    @IsTest
    static void testInsertSingle_NormalizesFields() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact con = new Contact(
                FirstName = '  Alice  ',
                LastName = '  Smith  ',
                Email = '  Alice.Smith@Example.COM  '
            );

            Test.startTest();
            insert con;
            Test.stopTest();

            Contact insertedCon = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :con.Id
                LIMIT 1
            ];

            System.assertEquals('Alice', insertedCon.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('Smith', insertedCon.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('alice.smith@example.com', insertedCon.Email, 'Email should be trimmed and lowercased on insert.');
        }
    }

    /**
     * @description Validates bulk insert normalization for 200 contacts.
     */
    @IsTest
    static void testInsertBulk_NormalizesFields() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < 200; i++) {
                contactsToInsert.add(new Contact(
                    FirstName = '  First' + i + '  ',
                    LastName = '  Last' + i + '  ',
                    Email = '  USER' + i + '@Example.COM  '
                ));
            }

            Test.startTest();
            insert contactsToInsert;
            Test.stopTest();

            for (Integer i = 0; i < contactsToInsert.size(); i++) {
                Contact insertedCon = contactsToInsert[i];
                System.assertEquals('First' + i, insertedCon.FirstName, 'FirstName should be trimmed for bulk insert records.');
                System.assertEquals('Last' + i, insertedCon.LastName, 'LastName should be trimmed for bulk insert records.');
                System.assertEquals('user' + i + '@example.com', insertedCon.Email, 'Email should be trimmed and lowercased for bulk insert records.');
            }
        }
    }

    /**
     * @description Validates single-record update normalization.
     */
    @IsTest
    static void testUpdateSingle_NormalizesFields() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            Contact con = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@example.com'
            );
            insert con;

            con.FirstName = '  Johnny  ';
            con.LastName = '  Doer  ';
            con.Email = '  Johnny.Doer@Example.COM  ';

            Test.startTest();
            update con;
            Test.stopTest();

            Contact updatedCon = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :con.Id
                LIMIT 1
            ];

            System.assertEquals('Johnny', updatedCon.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('Doer', updatedCon.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('johnny.doer@example.com', updatedCon.Email, 'Email should be trimmed and lowercased on update.');
        }
    }

    /**
     * @description Validates bulk update normalization for 200 contacts.
     */
    @IsTest
    static void testUpdateBulk_NormalizesFields() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runningUser) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < 200; i++) {
                contactsToInsert.add(new Contact(
                    FirstName = 'Initial' + i,
                    LastName = 'Value' + i,
                    Email = 'initial' + i + '@example.com'
                ));
            }
            insert contactsToInsert;

            for (Integer i = 0; i < contactsToInsert.size(); i++) {
                Contact con = contactsToInsert[i];
                con.FirstName = '  UpdatedFirst' + i + '  ';
                con.LastName = '  UpdatedLast' + i + '  ';
                con.Email = '  UPDATED' + i + '@Example.COM  ';
            }

            Test.startTest();
            update contactsToInsert;
            Test.stopTest();

            for (Integer i = 0; i < contactsToInsert.size(); i++) {
                Contact updatedCon = contactsToInsert[i];
                System.assertEquals('UpdatedFirst' + i, updatedCon.FirstName, 'FirstName should be trimmed for bulk update records.');
                System.assertEquals('UpdatedLast' + i, updatedCon.LastName, 'LastName should be trimmed for bulk update records.');
                System.assertEquals('updated' + i + '@example.com', updatedCon.Email, 'Email should be trimmed and lowercased for bulk update records.');
            }
        }
    }
}
