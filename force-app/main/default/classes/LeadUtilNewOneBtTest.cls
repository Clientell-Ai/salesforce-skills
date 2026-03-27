/**
 * @description Test class for LeadUtilNewOneBt.
 */
@IsTest
public with sharing class LeadUtilNewOneBtTest {

    @IsTest
    static void testMapById_Basic() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            // Arrange
            Lead l = new Lead(
                LastName = 'Test',
                Company = 'Acme'
            );
            insert l;

            // Act
            Test.startTest();
            Map<Id, Lead> result = LeadUtilNewOneBt.mapById(new List<Lead>{ l });
            Test.stopTest();

            // Assert
            System.assertEquals(1, result.size(), 'Map should contain one entry');
            System.assertEquals(l.Id, result.keySet().iterator().next(), 'Lead Id should be mapped');
            System.assertEquals(l.LastName, result.get(l.Id).LastName, 'Mapped Lead should match');
        }
    }

    @IsTest
    static void testMapById_NullAndEmpty() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            Map<Id, Lead> nullResult = LeadUtilNewOneBt.mapById(null);
            Map<Id, Lead> emptyResult = LeadUtilNewOneBt.mapById(new List<Lead>());
            Test.stopTest();

            System.assertEquals(0, nullResult.size(), 'Null list should return empty map');
            System.assertEquals(0, emptyResult.size(), 'Empty list should return empty map');
        }
    }
}
