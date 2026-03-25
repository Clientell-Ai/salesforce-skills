/**
 * @description Tests for DuplicatePhoneBlocker_X96 trigger behavior.
 */
@IsTest
public with sharing class DuplicatePhoneBlocker_X96_Test {
    private static final String DUPLICATE_ERROR = 'Duplicate phone found on another open Lead.';

    /**
     * @description Verifies duplicate phone on insert is blocked for the second open Lead.
     */
    @IsTest
    static void testInsertTwoOpenLeadsSamePhoneSecondFails() {
        User runAsUser = createRunAsUser();
        System.runAs(runAsUser) {
            String openStatus = getOpenStatus();
            List<Lead> leadsToInsert = new List<Lead>{
                new Lead(LastName = 'First Lead', Company = 'Clientell', Status = openStatus, Phone = '(415) 555-1212'),
                new Lead(LastName = 'Second Lead', Company = 'Clientell', Status = openStatus, Phone = '4155551212')
            };

            Test.startTest();
            Database.SaveResult[] results = Database.insert(leadsToInsert, false);
            Test.stopTest();

            System.assertEquals(2, results.size(), 'Two save results are expected.');
            System.assert(results[0].isSuccess(), 'First Lead insert should succeed.');
            System.assert(!results[1].isSuccess(), 'Second Lead insert should fail due to duplicate phone.');
            System.assert(
                results[1].getErrors()[0].getMessage().contains(DUPLICATE_ERROR),
                'Second Lead should fail with duplicate phone message.'
            );
        }
    }

    /**
     * @description Verifies update is blocked when changing phone to match another open Lead.
     */
    @IsTest
    static void testUpdatePhoneToDuplicateOpenLeadFails() {
        User runAsUser = createRunAsUser();
        System.runAs(runAsUser) {
            String openStatus = getOpenStatus();
            Lead leadOne = new Lead(LastName = 'Lead One', Company = 'Clientell', Status = openStatus, Phone = '212-555-9000');
            Lead leadTwo = new Lead(LastName = 'Lead Two', Company = 'Clientell', Status = openStatus, Phone = '212-555-9001');
            insert new List<Lead>{ leadOne, leadTwo };

            leadTwo.Phone = '(212) 555-9000';

            Test.startTest();
            Database.SaveResult updateResult = Database.update(leadTwo, false);
            Test.stopTest();

            System.assert(!updateResult.isSuccess(), 'Update should fail due to duplicate phone.');
            System.assert(
                updateResult.getErrors()[0].getMessage().contains(DUPLICATE_ERROR),
                'Update should return duplicate phone message.'
            );
        }
    }

    /**
     * @description Verifies converted Leads do not block duplicate phone checks.
     */
    @IsTest
    static void testConvertedLeadDoesNotBlock() {
        User runAsUser = createRunAsUser();
        System.runAs(runAsUser) {
            String openStatus = getOpenStatus();
            Lead leadToConvert = new Lead(
                LastName = 'To Convert',
                Company = 'Clientell',
                Status = openStatus,
                Phone = '646-555-1000'
            );
            insert leadToConvert;

            Database.LeadConvert conversion = new Database.LeadConvert();
            conversion.setLeadId(leadToConvert.Id);
            conversion.setConvertedStatus(getConvertedStatus());

            Test.startTest();
            Database.LeadConvertResult conversionResult = Database.convertLead(conversion);
            Test.stopTest();

            System.assert(conversionResult.isSuccess(), 'Lead conversion should succeed in test setup.');

            Lead openLead = new Lead(
                LastName = 'Open Lead',
                Company = 'Clientell',
                Status = openStatus,
                Phone = '6465551000'
            );

            Database.SaveResult insertResult = Database.insert(openLead, false);
            System.assert(insertResult.isSuccess(), 'Open Lead insert should succeed because converted Lead must not block.');
        }
    }

    /**
     * @description Verifies differently formatted phones are still treated as duplicates.
     */
    @IsTest
    static void testDifferentFormattingStillMatches() {
        User runAsUser = createRunAsUser();
        System.runAs(runAsUser) {
            String openStatus = getOpenStatus();
            Lead firstLead = new Lead(
                LastName = 'Format One',
                Company = 'Clientell',
                Status = openStatus,
                Phone = '+1 (917) 555-2222'
            );
            Lead secondLead = new Lead(
                LastName = 'Format Two',
                Company = 'Clientell',
                Status = openStatus,
                Phone = '1-917-555-2222'
            );

            Test.startTest();
            Database.SaveResult[] results = Database.insert(new List<Lead>{ firstLead, secondLead }, false);
            Test.stopTest();

            System.assert(results[0].isSuccess(), 'First insert should succeed.');
            System.assert(!results[1].isSuccess(), 'Second insert should fail because normalized phones match.');
            System.assert(
                results[1].getErrors()[0].getMessage().contains(DUPLICATE_ERROR),
                'Second insert should fail with duplicate message.'
            );
        }
    }

    /**
     * @description Returns an open Lead status value for test data.
     * @return A non-converted Lead status value when available.
     */
    private static String getOpenStatus() {
        for (Schema.PicklistEntry entry : Lead.Status.getDescribe().getPicklistValues()) {
            String value = entry.getValue();
            if (value != 'Closed - Converted' && value != 'Closed - Not Converted') {
                return value;
            }
        }
        return Lead.Status.getDescribe().getPicklistValues()[0].getValue();
    }

    /**
     * @description Returns a converted Lead status value required by Database.convertLead.
     * @return Converted status string.
     */
    private static String getConvertedStatus() {
        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            WITH USER_MODE
            LIMIT 1
        ];
        return convertedStatus.MasterLabel;
    }

    /**
     * @description Creates a standard user for System.runAs execution.
     * @return Inserted User record.
     */
    private static User createRunAsUser() {
        Profile standardProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            WITH USER_MODE
            LIMIT 1
        ];

        String unique = String.valueOf(DateTime.now().getTime());
        User userRecord = new User(
            Alias = 'x96usr',
            Email = 'x96user' + unique + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'X96 User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'x96user' + unique + '@example.com'
        );
        insert userRecord;
        return userRecord;
    }
}
