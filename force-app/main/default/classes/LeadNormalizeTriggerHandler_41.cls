/**
 * @description Handler for LeadNormalizeTrigger_41 to normalize Lead fields before DML.
 */
public with sharing class LeadNormalizeTriggerHandler_41 {
    private static Boolean isRunning = false;

    /**
     * @description Normalizes Lead fields before insert/update in bulk-safe manner.
     * @param newList Lead records from Trigger.new.
     */
    public static void handleBefore(List<Lead> newList) {
        if (isRunning || newList == null || newList.isEmpty()) {
            return;
        }

        isRunning = true;
        try {
            for (Lead leadRecord : newList) {
                if (leadRecord.Email != null) {
                    leadRecord.Email = leadRecord.Email.trim().toLowerCase();
                }

                if (leadRecord.Phone != null) {
                    String normalizedPhone = leadRecord.Phone.replaceAll('[^0-9]', '');
                    if (normalizedPhone.length() == 11 && normalizedPhone.startsWith('1')) {
                        normalizedPhone = normalizedPhone.substring(1);
                    }
                    leadRecord.Phone = normalizedPhone;
                }

                if (leadRecord.Company != null) {
                    leadRecord.Company = leadRecord.Company.trim().replaceAll('\\s+', ' ');
                }
            }
        } finally {
            isRunning = false;
        }
    }
}
