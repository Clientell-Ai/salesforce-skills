/**
 * @description Static guard for LeadNormalizeTrigger recursion prevention.
 */
public with sharing class LeadNormalizeTriggerHandler {
    public static Boolean isRunning = false;
}