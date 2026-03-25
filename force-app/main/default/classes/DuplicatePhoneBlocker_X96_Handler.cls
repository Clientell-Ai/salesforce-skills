/**
 * @description Blocks duplicate phone values for open Leads.
 */
public with sharing class DuplicatePhoneBlocker_X96_Handler {
    private static final String ERROR_MESSAGE = 'Duplicate phone found on another open Lead.';
    private static final Set<String> CLOSED_STATUSES = new Set<String>{
        'Closed - Converted',
        'Closed - Not Converted'
    };

    /**
     * @description Applies duplicate phone validation for before insert and before update.
     * @param newList Trigger.new records.
     * @param oldMap Trigger.oldMap records (null for insert).
     */
    public static void run(List<Lead> newList, Map<Id, Lead> oldMap) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Lead.isAccessible() || !Schema.sObjectType.Lead.fields.Phone.isAccessible()) {
            return;
        }

        Boolean useStatusFilter = hasClosedStatusValues();
        Map<Integer, String> candidateIndexToPhone = new Map<Integer, String>();
        Set<String> candidatePhones = new Set<String>();

        for (Integer i = 0; i < newList.size(); i++) {
            Lead currentLead = newList[i];
            String normalizedPhone = normalizePhone(currentLead.Phone);
            if (String.isBlank(normalizedPhone) || !isOpenLead(currentLead, useStatusFilter)) {
                continue;
            }

            if (oldMap != null && oldMap.containsKey(currentLead.Id)) {
                Lead oldLead = oldMap.get(currentLead.Id);
                String oldNormalizedPhone = normalizePhone(oldLead.Phone);
                Boolean phoneChanged = normalizedPhone != oldNormalizedPhone;
                Boolean becameOpen = !isOpenLead(oldLead, useStatusFilter) && isOpenLead(currentLead, useStatusFilter);
                if (!phoneChanged && !becameOpen) {
                    continue;
                }
            }

            candidateIndexToPhone.put(i, normalizedPhone);
            candidatePhones.add(normalizedPhone);
        }

        if (candidatePhones.isEmpty()) {
            return;
        }

        Map<String, Id> existingOpenPhoneToLeadId = new Map<String, Id>();
        for (Lead existingLead : [
            SELECT Id, Phone, IsConverted, Status
            FROM Lead
            WHERE Phone != null
            AND IsConverted = false
            WITH USER_MODE
        ]) {
            if (!isOpenLead(existingLead, useStatusFilter)) {
                continue;
            }
            String normalizedExistingPhone = normalizePhone(existingLead.Phone);
            if (String.isBlank(normalizedExistingPhone) || !candidatePhones.contains(normalizedExistingPhone)) {
                continue;
            }
            if (!existingOpenPhoneToLeadId.containsKey(normalizedExistingPhone)) {
                existingOpenPhoneToLeadId.put(normalizedExistingPhone, existingLead.Id);
            }
        }

        Set<String> seenInBatchPhones = new Set<String>();
        for (Integer i = 0; i < newList.size(); i++) {
            if (!candidateIndexToPhone.containsKey(i)) {
                continue;
            }

            Lead currentLead = newList[i];
            String normalizedPhone = candidateIndexToPhone.get(i);

            if (existingOpenPhoneToLeadId.containsKey(normalizedPhone)
                && (currentLead.Id == null || existingOpenPhoneToLeadId.get(normalizedPhone) != currentLead.Id)) {
                currentLead.Phone.addError(ERROR_MESSAGE);
                continue;
            }

            if (seenInBatchPhones.contains(normalizedPhone)) {
                currentLead.Phone.addError(ERROR_MESSAGE);
                continue;
            }

            seenInBatchPhones.add(normalizedPhone);
        }
    }

    /**
     * @description Normalizes a phone string by keeping digits only.
     * @param phoneValue Raw phone value.
     * @return Digits-only phone value, or null when input is blank.
     */
    public static String normalizePhone(String phoneValue) {
        if (String.isBlank(phoneValue)) {
            return null;
        }
        String digitsOnly = phoneValue.replaceAll('[^0-9]', '');
        return String.isBlank(digitsOnly) ? null : digitsOnly;
    }

    /**
     * @description Determines whether a Lead is open according to the trigger rule.
     * @param leadRecord Lead to evaluate.
     * @param useStatusFilter True when closed status values are available in org metadata.
     * @return True when the Lead is considered open.
     */
    public static Boolean isOpenLead(Lead leadRecord, Boolean useStatusFilter) {
        if (leadRecord == null || leadRecord.IsConverted) {
            return false;
        }
        if (!useStatusFilter) {
            return true;
        }
        return !CLOSED_STATUSES.contains(leadRecord.Status);
    }

    /**
     * @description Checks if both closed status values are configured in Lead.Status picklist.
     * @return True when both closed status values exist.
     */
    public static Boolean hasClosedStatusValues() {
        Set<String> statusValues = new Set<String>();
        for (Schema.PicklistEntry entry : Lead.Status.getDescribe().getPicklistValues()) {
            statusValues.add(entry.getValue());
        }
        return statusValues.contains('Closed - Converted') && statusValues.contains('Closed - Not Converted');
    }
}
