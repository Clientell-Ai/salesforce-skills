/**
 * @description Handler for sanitizing Lead name and company fields.
 */
public with sharing class VendorSampleSanitizeTriggerLocal2Handler {
    private static Boolean isProcessing = false;

    /**
     * @description Trims supported Lead fields in a null-safe and recursion-safe way.
     * @param leads Lead records from trigger context.
     */
    public static void sanitizeLeads(List<Lead> leads) {
        if (isProcessing || leads == null || leads.isEmpty()) {
            return;
        }

        isProcessing = true;
        try {
            for (Lead currentLead : leads) {
                if (currentLead == null) {
                    continue;
                }
                currentLead.FirstName = trimValue(currentLead.FirstName);
                currentLead.LastName = trimValue(currentLead.LastName);
                currentLead.Company = trimValue(currentLead.Company);
            }
        } finally {
            isProcessing = false;
        }
    }

    /**
     * @description Returns trimmed value when present, otherwise returns null.
     * @param inputValue Raw string value.
     * @return Trimmed string or null.
     */
    private static String trimValue(String inputValue) {
        return inputValue == null ? null : inputValue.trim();
    }
}
