/**
 * @description Test class for LeadNormalizeTrigger and LeadNormalizeUtil.
 */
@IsTest
public with sharing class LeadNormalizeTriggerTest {

    @IsTest
    static void testBeforeInsertNormalization() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l1 = new Lead(
                FirstName = '  Jane   ',
                LastName = '  Doe  ',
                Company = '  Acme    Corp  ',
                Email = '  TEST@Example.COM  ',
                Phone = ' (415) 555-1212 '
            );
            Lead l2 = new Lead(
                FirstName = '   Bob   ',
                LastName = '   ',
                Company = '   ',
                Email = '  Bob.Smith@Example.COM ',
                Phone = '1-212-555-7890'
            );

            insert new List<Lead>{ l1, l2 };

            Lead r1 = [SELECT FirstName, LastName, Company, Email, Phone FROM Lead WHERE Id = :l1.Id];
            Lead r2 = [SELECT FirstName, LastName, Company, Email, Phone FROM Lead WHERE Id = :l2.Id];

            System.assertEquals('Jane', r1.FirstName, 'FirstName should be normalized');
            System.assertEquals('Doe', r1.LastName, 'LastName should be normalized');
            System.assertEquals('Acme Corp', r1.Company, 'Company should be normalized');
            System.assertEquals('test@example.com', r1.Email, 'Email should be normalized');
            System.assertEquals('(415) 555-1212', r1.Phone, 'Phone should be normalized');

            System.assertEquals('Bob', r2.FirstName, 'FirstName should be normalized');
            System.assertEquals('Unknown', r2.LastName, 'LastName should default to Unknown');
            System.assertEquals('Unknown', r2.Company, 'Company should default to Unknown');
            System.assertEquals('bob.smith@example.com', r2.Email, 'Email should be normalized');
            System.assertEquals('+1 (212) 555-7890', r2.Phone, 'Phone should be normalized');
        }
    }

    @IsTest
    static void testBeforeUpdateNormalization() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(
                FirstName = 'Ann',
                LastName = 'Lee',
                Company = 'Example',
                Email = 'ann@example.com',
                Phone = '4155551212'
            );
            insert l;

            l.FirstName = '  Ann   Marie  ';
            l.LastName = '   ';
            l.Company = '  Big   Co  ';
            l.Email = '  ANN@EXAMPLE.COM ';
            l.Phone = '  212.555.7890 ';

            Test.startTest();
            update l;
            Test.stopTest();

            Lead r = [SELECT FirstName, LastName, Company, Email, Phone FROM Lead WHERE Id = :l.Id];
            System.assertEquals('Ann Marie', r.FirstName, 'FirstName should be normalized on update');
            System.assertEquals('Unknown', r.LastName, 'LastName should default to Unknown on update');
            System.assertEquals('Big Co', r.Company, 'Company should be normalized on update');
            System.assertEquals('ann@example.com', r.Email, 'Email should be normalized on update');
            System.assertEquals('(212) 555-7890', r.Phone, 'Phone should be normalized on update');
        }
    }

    @IsTest
    static void testNullValuesDoNotThrow() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Lead l = new Lead(
                FirstName = null,
                LastName = '  Doe  ',
                Company = 'Acme',
                Email = null
            );

            Test.startTest();
            insert l;
            Test.stopTest();

            Lead insertedLead = [SELECT FirstName, LastName, Email FROM Lead WHERE Id = :l.Id];
            System.assertEquals(null, insertedLead.FirstName, 'FirstName should remain null when input is null');
            System.assertEquals('Doe', insertedLead.LastName, 'LastName should be trimmed safely when provided');
            System.assertEquals(null, insertedLead.Email, 'Email should remain null when input is null');

            insertedLead.FirstName = null;
            insertedLead.LastName = null;
            insertedLead.Email = null;

            Test.startTest();
            update insertedLead;
            Test.stopTest();

            Lead updatedLead = [SELECT FirstName, LastName, Email FROM Lead WHERE Id = :insertedLead.Id];
            System.assertEquals(null, updatedLead.FirstName, 'FirstName should stay null on update');
            System.assertEquals('Unknown', updatedLead.LastName, 'LastName should be normalized safely on update');
            System.assertEquals(null, updatedLead.Email, 'Email should stay null on update');
        }
    }
}
