/**
 * @description Enforces the Opportunity amount policy that requires an Account phone number
 * when the Opportunity Amount is at or above a configured threshold.
 */
public with sharing class OpportunityAmountPolicyPhone {
    private static final Decimal DEFAULT_MINIMUM_AMOUNT = 10000;

    /**
     * @description Raised when required object or field access is not available.
     */
    public class PolicyAccessException extends Exception {}

    /**
     * @description Applies the policy to each Opportunity and adds record errors for violations.
     * @param opportunities Opportunities to evaluate.
     * @param minimumAmount Threshold amount that requires an Account phone.
     */
    public static void enforce(List<Opportunity> opportunities, Decimal minimumAmount) {
        if (opportunities == null || opportunities.isEmpty()) {
            return;
        }

        validateFieldAccess();

        Decimal threshold = minimumAmount == null ? DEFAULT_MINIMUM_AMOUNT : minimumAmount;
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity opp : opportunities) {
            if (opp != null && opp.Amount != null && opp.Amount >= threshold && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        Map<Id, Account> accountsById = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            for (Account accountRecord : [
                SELECT Id, Phone
                FROM Account
                WHERE Id IN :accountIds
                WITH USER_MODE
            ]) {
                accountsById.put(accountRecord.Id, accountRecord);
            }
        }

        for (Opportunity opp : opportunities) {
            if (opp == null || opp.Amount == null || opp.Amount < threshold) {
                continue;
            }

            String accountPhone;
            if (opp.AccountId != null && accountsById.containsKey(opp.AccountId)) {
                accountPhone = accountsById.get(opp.AccountId).Phone;
            }

            if (String.isBlank(accountPhone)) {
                opp.addError('Account Phone is required when Opportunity Amount is at least ' + String.valueOf(threshold) + '.');
            }
        }

        System.debug(LoggingLevel.DEBUG, 'OpportunityAmountPolicyPhone evaluated ' + opportunities.size() + ' opportunity record(s).');
    }

    /**
     * @description Validates read access required by this policy.
     */
    private static void validateFieldAccess() {
        if (!Schema.sObjectType.Opportunity.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.Amount.isAccessible() ||
            !Schema.sObjectType.Opportunity.fields.AccountId.isAccessible()) {
            throw new PolicyAccessException('Insufficient access to Opportunity fields required for amount policy checks.');
        }

        if (!Schema.sObjectType.Account.isAccessible() ||
            !Schema.sObjectType.Account.fields.Phone.isAccessible()) {
            throw new PolicyAccessException('Insufficient access to Account.Phone required for amount policy checks.');
        }
    }
}
