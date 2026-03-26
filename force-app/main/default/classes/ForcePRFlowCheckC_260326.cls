/**
 * @description Normalizes Account fields before DML by trimming Name and lowercasing Website.
 */
public with sharing class ForcePRFlowCheckC_260326 {

    /**
     * @description Applies normalization to a collection of Account records.
     * @param records Account records from trigger context.
     */
    public static void normalizeAccounts(List<Account> records) {
        if (records == null || records.isEmpty()) {
            return;
        }

        for (Account acct : records) {
            if (acct == null) {
                continue;
            }

            if (acct.Name != null) {
                acct.Name = acct.Name.trim();
            }

            if (acct.Website != null) {
                acct.Website = acct.Website.trim().toLowerCase();
            }
        }
    }
}
