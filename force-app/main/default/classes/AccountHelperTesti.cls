/**
 * @description Helper for Account operations.
 */
public with sharing class AccountHelperTesti {

    /**
     * @description Gets an Account by Id with USER_MODE checks.
     * @param accountId The Account Id.
     * @return The Account record or null.
     */
    public static Account getAccountById(Id accountId) {
        if (accountId == null) {
            return null;
        }
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('Insufficient access to Account');
        }
        List<Account> records = [
            SELECT Id, Name
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }
}
