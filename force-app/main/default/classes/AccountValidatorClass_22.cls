/**
 * @description Reusable validation utility for Account records.
 */
public with sharing class AccountValidatorClass_22 {
    /**
     * @description Container for validation output.
     */
    public class ValidationResult {
        /**
         * @description True when no validation errors are present.
         */
        public Boolean isValid;

        /**
         * @description Collection of validation error messages.
         */
        public List<String> errors;

        /**
         * @description Creates a ValidationResult with default values.
         */
        public ValidationResult() {
            this.isValid = true;
            this.errors = new List<String>();
        }
    }

    /**
     * @description Validates Accounts for insert-specific business rules.
     * @param newAccounts Accounts to validate.
     * @return List of validation errors. Each message includes Account.Name when available.
     */
    public static List<String> validateForInsert(List<Account> newAccounts) {
        List<String> errors = new List<String>();

        if (newAccounts == null || newAccounts.isEmpty()) {
            return errors;
        }

        for (Account acc : newAccounts) {
            String nameValue = acc != null ? acc.Name : null;
            String nameLabel = String.isBlank(nameValue) ? 'Unnamed Account' : nameValue;

            if (acc == null) {
                errors.add('Account [' + nameLabel + ']: Record is null.');
                continue;
            }

            if (String.isBlank(acc.Name)) {
                errors.add('Account [' + nameLabel + ']: Name is required.');
            }

            if (!String.isBlank(acc.Industry) && acc.Industry.equalsIgnoreCase('Other')) {
                errors.add('Account [' + nameLabel + ']: Industry cannot be Other.');
            }

            if (!String.isBlank(acc.Phone)) {
                String digitsOnlyPhone = acc.Phone.replaceAll('[^0-9]', '');
                if (digitsOnlyPhone.length() < 10) {
                    errors.add('Account [' + nameLabel + ']: Phone must contain at least 10 digits.');
                }
            }
        }

        return errors;
    }

    /**
     * @description Validates Accounts and returns a structured validation result.
     * @param accounts Accounts to validate.
     * @return ValidationResult with validity flag and errors.
     */
    public static ValidationResult validate(List<Account> accounts) {
        ValidationResult result = new ValidationResult();
        result.errors = validateForInsert(accounts);
        result.isValid = result.errors.isEmpty();
        return result;
    }
}
