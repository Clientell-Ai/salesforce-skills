/**
 * @description Sanitizes Lead name and email values in before-trigger context.
 */
public with sharing class LeadRegionSanitizeRun26Handler {
    private static Boolean isRunning = false;

    /**
     * @description Trims FirstName/LastName and trims + lowercases Email for each Lead.
     * @param leads Trigger.new records to sanitize.
     */
    public static void sanitizeLeads(List<Lead> leads) {
        if (isRunning || leads == null || leads.isEmpty()) {
            return;
        }

        isRunning = true;
        try {
            for (Lead currentLead : leads) {
                if (currentLead.FirstName != null) {
                    String trimmedFirstName = currentLead.FirstName.trim();
                    if (trimmedFirstName != currentLead.FirstName) {
                        currentLead.FirstName = trimmedFirstName;
                    }
                }

                if (currentLead.LastName != null) {
                    String trimmedLastName = currentLead.LastName.trim();
                    if (trimmedLastName != currentLead.LastName) {
                        currentLead.LastName = trimmedLastName;
                    }
                }

                if (currentLead.Email != null) {
                    String normalizedEmail = currentLead.Email.trim().toLowerCase();
                    if (normalizedEmail != currentLead.Email) {
                        currentLead.Email = normalizedEmail;
                    }
                }
            }
        } finally {
            isRunning = false;
        }
    }
}
