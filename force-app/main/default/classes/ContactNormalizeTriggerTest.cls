/**
 * @description Tests ContactNormalizeTrigger normalization behavior on insert and update.
 */
@IsTest
public with sharing class ContactNormalizeTriggerTest {

    @IsTest
    static void testInsertAndUpdate_NormalizesContactFields() {
        User currentUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        System.runAs(currentUser) {
            Contact contactRecord = new Contact(
                FirstName = '  Jane  ',
                LastName = '  DOE  ',
                Email = '  Jane.DOE@Example.COM  '
            );

            insert contactRecord;

            Contact insertedContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :contactRecord.Id
                LIMIT 1
            ];

            System.assertEquals('Jane', insertedContact.FirstName, 'FirstName should be trimmed on insert.');
            System.assertEquals('DOE', insertedContact.LastName, 'LastName should be trimmed on insert.');
            System.assertEquals('jane.doe@example.com', insertedContact.Email, 'Email should be trimmed and lowercased on insert.');

            insertedContact.FirstName = '  Janet ';
            insertedContact.LastName = '  Smith  ';
            insertedContact.Email = '  NEW.Email@Example.COM ';

            update insertedContact;

            Contact updatedContact = [
                SELECT FirstName, LastName, Email
                FROM Contact
                WHERE Id = :insertedContact.Id
                LIMIT 1
            ];

            System.assertEquals('Janet', updatedContact.FirstName, 'FirstName should be trimmed on update.');
            System.assertEquals('Smith', updatedContact.LastName, 'LastName should be trimmed on update.');
            System.assertEquals('new.email@example.com', updatedContact.Email, 'Email should be trimmed and lowercased on update.');
        }
    }
}
