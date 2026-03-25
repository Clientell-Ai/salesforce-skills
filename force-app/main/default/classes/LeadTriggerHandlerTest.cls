/**
 * @description Test class for LeadTriggerHandler behavior.
 */
@IsTest
public with sharing class LeadTriggerHandlerTest {

    /**
     * @description Verifies insert normalization for name and email fields.
     */
    @IsTest
    static void testBeforeInsert_NormalizesFields() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(
                LastName = '  DOE  ',
                FirstName = '  John ',
                Company = 'Acme',
                Email = '  JOHN.DOE@EXAMPLE.COM  '
            );

            insert l;

            Lead saved = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :l.Id
                WITH USER_MODE
            ];
            System.assertEquals('John', saved.FirstName, 'FirstName should be trimmed on insert');
            System.assertEquals('DOE', saved.LastName, 'LastName should be trimmed on insert');
            System.assertEquals('john.doe@example.com', saved.Email, 'Email should be trimmed and lowercased on insert');
        }
    }

    /**
     * @description Verifies update normalization and null safety for nullable fields.
     */
    @IsTest
    static void testBeforeUpdate_NormalizesAndHandlesNulls() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(
                LastName = 'Smith',
                FirstName = 'Jane',
                Company = 'Acme',
                Email = 'jane@example.com'
            );
            insert l;

            l.FirstName = null;
            l.LastName = null;
            l.Email = '  NEW@EXAMPLE.COM ';

            Test.startTest();
            update l;
            Test.stopTest();

            Lead saved = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :l.Id
                WITH USER_MODE
            ];
            System.assertEquals(null, saved.FirstName, 'FirstName should remain null when set to null');
            System.assertEquals(null, saved.LastName, 'LastName should remain null when set to null');
            System.assertEquals('new@example.com', saved.Email, 'Email should be trimmed and lowercased on update');
        }
    }

    /**
     * @description Verifies bulk insert normalization across 200 records.
     */
    @IsTest
    static void testBeforeInsert_Bulk200() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            List<Lead> leads = new List<Lead>();
            for (Integer i = 0; i < 200; i++) {
                leads.add(new Lead(
                    LastName = '  Last' + i + '  ',
                    FirstName = '  First' + i + ' ',
                    Company = 'Bulk Co',
                    Email = '  USER' + i + '@EXAMPLE.COM '
                ));
            }

            insert leads;

            List<Lead> saved = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Company = 'Bulk Co'
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 200
            ];
            System.assertEquals(200, saved.size(), 'Expected 200 inserted leads');
            for (Lead l : saved) {
                System.assertNotEquals(null, l.FirstName, 'FirstName should be populated');
                System.assertNotEquals(' ', l.FirstName, 'FirstName should not be raw whitespace');
                System.assertNotEquals(null, l.LastName, 'LastName should be populated');
                System.assert(l.Email == l.Email.toLowerCase(), 'Email should be lowercase');
                System.assertEquals(l.Email, l.Email.trim(), 'Email should be trimmed');
            }
        }
    }

    /**
     * @description Verifies null field insert does not throw and values stay null.
     */
    @IsTest
    static void testBeforeInsert_NullHandling_NoException() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(LastName = 'NullCase', Company = 'Acme');

            Test.startTest();
            insert l;
            Test.stopTest();

            Lead saved = [
                SELECT FirstName, LastName, Email
                FROM Lead
                WHERE Id = :l.Id
                WITH USER_MODE
            ];
            System.assertEquals(null, saved.FirstName, 'FirstName should remain null');
            System.assertEquals(null, saved.Email, 'Email should remain null');
            System.assertEquals('NullCase', saved.LastName, 'LastName should persist');
        }
    }
}
