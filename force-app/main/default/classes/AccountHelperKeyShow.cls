/**
 * @description Helper utilities for basic Account operations.
 */
public with sharing class AccountHelperKeyShow {

    /**
     * @description Returns the number of Accounts owned by a given User.
     * @param ownerId The User Id to count Accounts for.
     * @return The count of Accounts owned by the user, or 0 when input is null.
     */
    public static Integer countAccountsByOwner(Id ownerId) {
        if (ownerId == null) {
            return 0;
        }
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('Insufficient access to Account.');
        }
        AggregateResult[] results = [
            SELECT COUNT(Id) total
            FROM Account
            WHERE OwnerId = :ownerId
            WITH USER_MODE
        ];
        if (results.isEmpty()) {
            return 0;
        }
        return (Integer) results[0].get('total');
    }
}
