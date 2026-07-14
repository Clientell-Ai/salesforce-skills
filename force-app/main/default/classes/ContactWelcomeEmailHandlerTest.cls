/**
 * @description Test coverage for ContactWelcomeEmailHandler and ContactWelcomeEmailTrigger.
 */
@IsTest
public with sharing class ContactWelcomeEmailHandlerTest {
    /**
     * @description Verifies welcome emails are built only for contacts with email addresses.
     */
    @IsTest
    static void testBuildWelcomeEmails_WithAndWithoutEmail_BuildsOnlyEligibleMessages() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            List<Contact> contacts = new List<Contact>{
                new Contact(FirstName = 'Ada', LastName = 'Lovelace', Email = 'ada@example.com'),
                new Contact(FirstName = 'Grace', LastName = 'Hopper')
            };

            Test.startTest();
            List<Messaging.SingleEmailMessage> messages = ContactWelcomeEmailHandler.buildWelcomeEmails(contacts);
            Test.stopTest();

            System.assertEquals(1, messages.size(), 'Only contacts with an email address should receive welcome emails.');
        }
    }

    /**
     * @description Verifies bulk inserted contacts trigger one email invocation without DML in loops.
     */
    @IsTest
    static void testContactInsert_WithBulkEmailContacts_SendsWelcomeEmails() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            List<Contact> contacts = new List<Contact>();
            for (Integer index = 0; index < 201; index++) {
                contacts.add(new Contact(
                    FirstName = 'Customer' + index,
                    LastName = 'Contact' + index,
                    Email = 'customer' + index + '@example.com',
                    Phone = '415-555-0100'
                ));
            }

            Test.startTest();
            insert contacts;
            Test.stopTest();

            System.assertEquals(1, Limits.getEmailInvocations(), 'Bulk insert should send welcome emails in one email invocation.');
        }
    }

    /**
     * @description Verifies contacts without email addresses do not trigger welcome email delivery.
     */
    @IsTest
    static void testContactInsert_WithoutEmail_DoesNotSendEmail() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            Contact contactWithoutEmail = new Contact(FirstName = 'No', LastName = 'Email', Phone = '415-555-0101');

            Test.startTest();
            insert contactWithoutEmail;
            Test.stopTest();

            System.assertEquals(0, Limits.getEmailInvocations(), 'Contacts without email addresses should not send welcome emails.');
        }
    }

    /**
     * @description Verifies updates do not send welcome emails.
     */
    @IsTest
    static void testContactUpdate_WithEmail_DoesNotSendWelcomeEmailAgain() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        System.runAs(currentUser) {
            Contact contactWithEmail = new Contact(
                FirstName = 'Update',
                LastName = 'Customer',
                Email = 'update@example.com',
                Phone = '415-555-0102'
            );
            insert contactWithEmail;

            Test.startTest();
            contactWithEmail.LastName = 'Customer Updated';
            update contactWithEmail;
            Test.stopTest();

            System.assertEquals(0, Limits.getEmailInvocations(), 'Updates should not send welcome emails.');
        }
    }
}
