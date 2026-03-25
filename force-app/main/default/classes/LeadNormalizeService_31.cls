/**
 * @description Normalizes Lead core fields before DML.
 */
public with sharing class LeadNormalizeService_31 {
    private static Boolean isNormalizing = false;

    /**
     * @description Returns true when normalization is already running in this transaction.
     * @return True when currently normalizing.
     */
    public static Boolean isInProgress() {
        return isNormalizing;
    }

    /**
     * @description Sets normalization state for recursion protection.
     * @param inProgress True when normalization is running.
     */
    public static void setInProgress(Boolean inProgress) {
        isNormalizing = inProgress;
    }

    /**
     * @description Normalizes lead name, company, email, and phone values.
     * @param leads Trigger.new leads to normalize.
     */
    public static void normalize(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        for (Lead currentLead : leads) {
            if (currentLead.FirstName != null) {
                currentLead.FirstName = currentLead.FirstName.trim();
            }
            if (currentLead.LastName != null) {
                currentLead.LastName = currentLead.LastName.trim();
            }
            if (currentLead.Company != null) {
                currentLead.Company = currentLead.Company.trim();
            }
            if (currentLead.Email != null) {
                currentLead.Email = currentLead.Email.trim().toLowerCase();
            }
            if (currentLead.Phone != null) {
                currentLead.Phone = normalizePhone(currentLead.Phone);
            }
        }
    }

    /**
     * @description Normalizes a phone string per project rules.
     * @param rawPhone The input phone value.
     * @return Formatted phone when possible; otherwise digits-only value.
     */
    private static String normalizePhone(String rawPhone) {
        String trimmedPhone = rawPhone.trim();
        String digitsOnly = trimmedPhone.replaceAll('[^0-9]', '');

        if (digitsOnly.length() == 10) {
            return '(' + digitsOnly.substring(0, 3) + ') ' + digitsOnly.substring(3, 6) + '-' + digitsOnly.substring(6, 10);
        }

        if (digitsOnly.length() == 11 && digitsOnly.startsWith('1')) {
            return '+1 (' + digitsOnly.substring(1, 4) + ') ' + digitsOnly.substring(4, 7) + '-' + digitsOnly.substring(7, 11);
        }

        return digitsOnly;
    }
}
