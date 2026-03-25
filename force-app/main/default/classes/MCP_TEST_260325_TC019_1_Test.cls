/**
 * @description Test class for MCP_TEST_260325_TC019_1 trigger and handler.
 */
@IsTest
public with sharing class MCP_TEST_260325_TC019_1_Test {

    /**
     * @description Retrieves current user for System.runAs.
     * @return Current user record.
     */
    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    @IsTest
    static void testSingleInsert() {
        User runAsUser = getRunAsUser();
        System.runAs(runAsUser) {
            Contact con = new Contact(LastName = 'Single Insert');

            Test.startTest();
            insert con;
            Test.stopTest();

            System.assertNotEquals(null, con.Id, 'Inserted contact should have an Id');
        }
    }

    @IsTest
    static void testBulkInsert() {
        User runAsUser = getRunAsUser();
        System.runAs(runAsUser) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < 200; i++) {
                contactsToInsert.add(new Contact(LastName = 'Bulk Insert ' + i));
            }

            Test.startTest();
            insert contactsToInsert;
            Test.stopTest();

            System.assertEquals(200, contactsToInsert.size(), 'Expected 200 contacts in bulk insert list');
            for (Contact con : contactsToInsert) {
                System.assertNotEquals(null, con.Id, 'Each inserted contact should have an Id');
            }
        }
    }

    @IsTest
    static void testSingleUpdate() {
        User runAsUser = getRunAsUser();
        System.runAs(runAsUser) {
            Contact con = new Contact(LastName = 'Single Update');
            insert con;

            con.FirstName = 'Updated';

            Test.startTest();
            update con;
            Test.stopTest();

            Contact updated = [SELECT Id, FirstName FROM Contact WHERE Id = :con.Id WITH USER_MODE LIMIT 1];
            System.assertEquals('Updated', updated.FirstName, 'Single update should persist FirstName');
        }
    }

    @IsTest
    static void testBulkUpdate() {
        User runAsUser = getRunAsUser();
        System.runAs(runAsUser) {
            List<Contact> contactsToInsert = new List<Contact>();
            for (Integer i = 0; i < 200; i++) {
                contactsToInsert.add(new Contact(LastName = 'Bulk Update ' + i));
            }
            insert contactsToInsert;

            for (Integer i = 0; i < contactsToInsert.size(); i++) {
                contactsToInsert[i].FirstName = 'Updated ' + i;
            }

            Test.startTest();
            update contactsToInsert;
            Test.stopTest();

            Integer updatedCount = [
                SELECT COUNT()
                FROM Contact
                WHERE Id IN :contactsToInsert
                AND FirstName LIKE 'Updated %'
                WITH USER_MODE
            ];
            System.assertEquals(200, updatedCount, 'All 200 contacts should be updated');
        }
    }
}
