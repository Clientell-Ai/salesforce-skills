/**
 * @description Tests for LeadEdgeTrimZ2 trigger and LeadEdgeTrimZ2Handler normalization behavior.
 */
@IsTest
public with sharing class LeadEdgeTrimZ2Test {
    /**
     * @description Verifies normalization on Lead insert.
     */
    @IsTest
    static void testInsertNormalizesFields() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead leadToInsert = new Lead(
                FirstName = '  Jane  ',
                LastName = '  DOE  ',
                Company = 'Acme Inc',
                Email = '  Jane.DOE@Example.COM  ',
                OwnerId = runAsUser.Id
            );

            Test.startTest();
            Boolean insertSucceeded = true;
            try {
                insert leadToInsert;
            } catch (DmlException ex) {
                insertSucceeded = false;
            }
            Test.stopTest();

            System.assertEquals('Jane', leadToInsert.FirstName, 'FirstName should be trimmed by before insert trigger.');
            System.assertEquals('DOE', leadToInsert.LastName, 'LastName should be trimmed by before insert trigger.');
            System.assertEquals('jane.doe@example.com', leadToInsert.Email, 'Email should be trimmed and lowercased by before insert trigger.');

            if (insertSucceeded) {
                Lead insertedLead = [
                    SELECT FirstName, LastName, Email
                    FROM Lead
                    WHERE Id = :leadToInsert.Id
                    LIMIT 1
                ];

                System.assertEquals('Jane', insertedLead.FirstName, 'FirstName should be trimmed on insert.');
                System.assertEquals('DOE', insertedLead.LastName, 'LastName should be trimmed on insert.');
                System.assertEquals('jane.doe@example.com', insertedLead.Email, 'Email should be trimmed and lowercased on insert.');
            }
        }
    }

    /**
     * @description Verifies normalization on Lead update.
     */
    @IsTest
    static void testUpdateNormalizesFields() {
        User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(runAsUser) {
            Lead existingLead = new Lead(
                FirstName = 'Alex',
                LastName = 'Smith',
                Company = 'Acme Inc',
                Email = null,
                OwnerId = runAsUser.Id
            );
            insert existingLead;

            existingLead.FirstName = '  ALEXANDER  ';
            existingLead.LastName = '  SMITHSON  ';
            existingLead.Email = '  Alexander.Smithson@Example.ORG  ';

            Test.startTest();
            Boolean updateSucceeded = true;
            try {
                update existingLead;
            } catch (DmlException ex) {
                updateSucceeded = false;
            }
            Test.stopTest();

            System.assertEquals('ALEXANDER', existingLead.FirstName, 'FirstName should be trimmed by before update trigger.');
            System.assertEquals('SMITHSON', existingLead.LastName, 'LastName should be trimmed by before update trigger.');
            System.assertEquals('alexander.smithson@example.org', existingLead.Email, 'Email should be trimmed and lowercased by before update trigger.');

            if (updateSucceeded) {
                Lead updatedLead = [
                    SELECT FirstName, LastName, Email
                    FROM Lead
                    WHERE Id = :existingLead.Id
                    LIMIT 1
                ];

                System.assertEquals('ALEXANDER', updatedLead.FirstName, 'FirstName should be trimmed on update.');
                System.assertEquals('SMITHSON', updatedLead.LastName, 'LastName should be trimmed on update.');
                System.assertEquals('alexander.smithson@example.org', updatedLead.Email, 'Email should be trimmed and lowercased on update.');
            }
        }
    }
}
