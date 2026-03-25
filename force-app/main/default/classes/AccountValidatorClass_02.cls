/**
 * @description Lightweight validation utility for Account records.
 *
 * Uses the addError pattern intentionally so validation messages are attached directly
 * to individual in-memory records during trigger/flow execution, preventing bad DML
 * while preserving partial-success behavior where applicable.
 *
 * Example (before insert/update trigger):
 * AccountValidatorClass_02.validateAccounts(Trigger.new, Trigger.oldMap);
 *
 * Example (invocable/flow context with no old values):
 * AccountValidatorClass_02.validateAccounts(accountsToValidate, null);
 */
public with sharing class AccountValidatorClass_02 {

    /**
     * @description Validates Account records with generic, production-safe checks.
     * @param newList Incoming Account records (for insert/update contexts).
     * @param oldMap Prior-state map for update context; null for insert/flow-only contexts.
     */
    public static void validateAccounts(List<Account> newList, Map<Id, Account> oldMap) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        if (!Schema.sObjectType.Account.isAccessible()) {
            return;
        }

        for (Account acc : newList) {
            if (acc == null) {
                continue;
            }

            validateRequiredName(acc);
            validateNameChangedOnUpdate(acc, oldMap);
        }
    }

    /**
     * @description Ensures Account Name is present.
     * @param acc Account record under validation.
     */
    private static void validateRequiredName(Account acc) {
        if (String.isBlank(acc.Name)) {
            acc.Name.addError('Account Name is required.');
        }
    }

    /**
     * @description Guards against no-op updates where Name is unchanged after trimming.
     * @param acc New-state Account record.
     * @param oldMap Prior-state map from trigger context.
     */
    private static void validateNameChangedOnUpdate(Account acc, Map<Id, Account> oldMap) {
        if (oldMap == null || acc.Id == null || !oldMap.containsKey(acc.Id)) {
            return;
        }

        Account oldAcc = oldMap.get(acc.Id);
        String newName = acc.Name == null ? null : acc.Name.trim();
        String previousName = oldAcc.Name == null ? null : oldAcc.Name.trim();

        if (!String.isBlank(newName) && newName == previousName) {
            acc.Name.addError('Update ignored: Account Name must be meaningfully changed.');
        }
    }
}
