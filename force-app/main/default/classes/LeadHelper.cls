/**
 * @description Helper methods for Lead records.
 */
public with sharing class LeadHelper {

    /**
     * @description Sets a default Company value when blank and updates Leads in USER_MODE.
     * @param leads The Lead records to normalize and update.
     * @return The number of Lead records updated.
     */
    public static Integer applyDefaultCompany(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return 0;
        }
        if (!Schema.sObjectType.Lead.isUpdateable() ||
            !Schema.sObjectType.Lead.fields.Company.isUpdateable()) {
            throw new AuraHandledException('Insufficient access to update Lead.Company');
        }

        List<Lead> toUpdate = new List<Lead>();
        for (Lead l : leads) {
            if (l == null) {
                continue;
            }
            if (String.isBlank(l.Company)) {
                l.Company = 'Unknown';
                toUpdate.add(l);
            }
        }

        if (toUpdate.isEmpty()) {
            return 0;
        }

        Database.update(toUpdate, AccessLevel.USER_MODE);
        return toUpdate.size();
    }
}
