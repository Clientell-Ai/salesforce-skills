/**
 * @description Validates Account records prior to persistence or processing.
 */
public with sharing class AccountValidatorClass_42 {
    /**
     * @description Exception raised when account validation fails.
     */
    public class AccountValidationException extends Exception {}

    /**
     * @description Validates Account records for required and format rules.
     * @param accounts Account records to validate.
     */
    public static void validate(List<Account> accounts) {
        if (accounts == null) {
            return;
        }

        for (Integer index = 0; index < accounts.size(); index++) {
            Account acc = accounts[index];

            if (acc == null) {
                continue;
            }

            if (String.isBlank(acc.Name)) {
                throw new AccountValidationException('Account Name cannot be blank. Record index: ' + index);
            }

            if (!String.isBlank(acc.Phone)) {
                String digitsOnly = acc.Phone.replaceAll('\\D', '');
                if (digitsOnly.length() < 10) {
                    throw new AccountValidationException('Phone must contain at least 10 digits. Record index: ' + index);
                }
            }

            if (!String.isBlank(acc.Website)) {
                String websiteLower = acc.Website.toLowerCase();
                Boolean hasHttpScheme = websiteLower.startsWith('http://') || websiteLower.startsWith('https://');
                if (!hasHttpScheme) {
                    throw new AccountValidationException('Website must start with http:// or https://. Record index: ' + index);
                }
            }
        }
    }
}
