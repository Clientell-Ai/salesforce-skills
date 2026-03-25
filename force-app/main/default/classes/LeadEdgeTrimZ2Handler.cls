/**
 * @description Normalizes Lead names and email before DML operations.
 */
public with sharing class LeadEdgeTrimZ2Handler {
    /**
     * @description Trims FirstName/LastName and trims+lowercases Email for each Lead record.
     * @param leads The trigger context Lead records to normalize.
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

            if (currentLead.Email != null) {
                currentLead.Email = currentLead.Email.trim().toLowerCase();
            }
        }
    }
}
