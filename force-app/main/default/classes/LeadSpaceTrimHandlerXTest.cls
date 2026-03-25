/**
 * @description Test coverage for LeadSpaceTrimHandlerX and LeadSpaceTrimTriggerX.
 */
@IsTest
public with sharing class LeadSpaceTrimHandlerXTest {
    /**
     * @description Verifies the trigger trims configured fields on insert.
     */
    @IsTest
    static void testBeforeInsert_TrimsConfiguredFields() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.runAs(currentUser) {
            Lead testLead = new Lead(
                LastName = 
