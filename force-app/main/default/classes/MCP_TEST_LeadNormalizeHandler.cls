/**
 * @description Normalizes Lead key fields before insert and before update.
 */
public with sharing class MCP_TEST_LeadNormalizeHandler {

    /**
     * @description Normalizes name/contact/company fields for non-converted leads.
     * @param newList Incoming trigger records.
     */
    public static void normalize(List<Lead> newList) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        for (Lead leadRecord : newList) {
            if (leadRecord == null || leadRecord.IsConverted) {
                continue;
            }

            leadRecord.FirstName = trimValue(leadRecord.FirstName);
            leadRecord.LastName = trimValue(leadRecord.LastName);
            leadRecord.Company = trimValue(leadRecord.Company);
            leadRecord.Title = trimValue(leadRecord.Title);
            leadRecord.Email = normalizeEmail(leadRecord.Email);
            leadRecord.Phone = normalizePhone(leadRecord.Phone);
            leadRecord.MobilePhone = normalizePhone(leadRecord.MobilePhone);

            if (String.isBlank(leadRecord.Company)) {
                leadRecord.Company = 'Unknown';
            }
        }
    }

    private static String trimValue(String inputValue) {
        return inputValue == null ? null : inputValue.trim();
    }

    private static String normalizeEmail(String inputValue) {
        if (inputValue == null) {
            return null;
        }
        String trimmed = inputValue.trim();
        return String.isBlank(trimmed) ? trimmed : trimmed.toLowerCase();
    }

    private static String normalizePhone(String inputValue) {
        if (inputValue == null) {
            return null;
        }

        String digitsOnly = inputValue.replaceAll('[^0-9]', '');

        if (digitsOnly.length() == 10) {
            return '(' + digitsOnly.substring(0, 3) + ') ' + digitsOnly.substring(3, 6) + '-' + digitsOnly.substring(6, 10);
        }

        if (digitsOnly.length() == 11 && digitsOnly.startsWith('1')) {
            return '+1 (' + digitsOnly.substring(1, 4) + ') ' + digitsOnly.substring(4, 7) + '-' + digitsOnly.substring(7, 11);
        }

        return digitsOnly;
    }
}
