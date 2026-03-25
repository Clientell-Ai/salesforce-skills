/**
 * @description Test coverage for ContactNormalizeTrigger_09 and ContactNormalizeTriggerHandler_09.
 */
@IsTest
public with sharing class ContactNormalizeTrigger_09_Test {

    /**
     * @description Verifies normalization behavior on before insert.
     */
    @IsTest
    static void testBeforeInsert_NormalizesFields() {
        User runAsUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runAsUser) {
            Contact con = new Contact(
                LastName = '  Doe   Smith  ',
                FirstName = '  Jane   Ann  ',
                Email = '  Jane.Doe@Example.COM  ',
                Phone = ' +1 (415) 555-1212 ',
                MobilePhone = ' (415) 777-9999 ext 42 '
            );

            Test.startTest();
            insert con;
            Test.stopTest();

            Contact insertedContact = [
                SELECT FirstName, LastName, Email, Phone, MobilePhone
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('Jane Ann', insertedContact.FirstName, 'FirstName should be trimmed and collapsed.');
            System.assertEquals('Doe Smith', insertedContact.LastName, 'LastName should be trimmed and collapsed.');
            System.assertEquals('jane.doe@example.com', insertedContact.Email, 'Email should be trimmed and lowercased.');
            System.assertEquals('+14155551212', insertedContact.Phone, 'Phone should keep leading plus and remove non-digits.');
            System.assertEquals('415777999942', insertedContact.MobilePhone, 'MobilePhone should remove non-digits.');
        }
    }

    /**
     * @description Verifies normalization behavior on before update.
     */
    @IsTest
    static void testBeforeUpdate_NormalizesFields() {
        User runAsUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(runAsUser) {
            Contact con = new Contact(
                LastName = 'Original',
                FirstName = 'Original',
                Email = 'original@example.com',
                Phone = '1234567',
                MobilePhone = '7654321'
            );
            insert con;

            con.FirstName = '  John     Q  ';
            con.LastName = '  Public    Jr   ';
            con.Email = '  JOHN.PUBLIC@Example.COM   ';
            con.Phone = ' +(44) 20-1234-5678 ';
            con.MobilePhone = ' 555-000-1111 abc ';

            Test.startTest();
            update con;
            Test.stopTest();

            Contact updatedContact = [
                SELECT FirstName, LastName, Email, Phone, MobilePhone
                FROM Contact
                WHERE Id = :con.Id
                WITH USER_MODE
                LIMIT 1
            ];

            System.assertEquals('John Q', updatedContact.FirstName, 'FirstName should be normalized on update.');
            System.assertEquals('Public Jr', updatedContact.LastName, 'LastName should be normalized on update.');
            System.assertEquals('john.public@example.com', updatedContact.Email, 'Email should be normalized on update.');
            System.assertEquals('+442012345678', updatedContact.Phone, 'Phone should preserve leading plus and keep digits only.');
            System.assertEquals('5550001111', updatedContact.MobilePhone, 'MobilePhone should keep digits only.');
        }
    }
}
