/**
 * @description Utility methods for normalizing Lead fields.
 */
public with sharing class LeadNormalizeUtil {

    /**
     * @description Normalize email by trimming and lowercasing.
     * @param emailValue The email to normalize.
     * @return Normalized email or null.
     */
    public static String normalizeEmail(String emailValue) {
        if (String.isBlank(emailValue)) {
            return null;
        }
        return emailValue.trim().toLowerCase();
    }

    /**
     * @description Normalize phone to standard formats or digits-only fallback.
     * @param phoneValue The phone to normalize.
     * @return Normalized phone or null.
     */
    public static String normalizePhone(String phoneValue) {
        if (String.isBlank(phoneValue)) {
            return null;
        }
        String digits = phoneValue.replaceAll('\\D', '');
        if (digits.length() == 10) {
            return '(' + digits.substring(0, 3) + ') ' + digits.substring(3, 6) + '-' + digits.substring(6, 10);
        }
        if (digits.length() == 11 && digits.startsWith('1')) {
            return '+1 (' + digits.substring(1, 4) + ') ' + digits.substring(4, 7) + '-' + digits.substring(7, 11);
        }
        return digits;
    }

    /**
     * @description Normalize company by trimming and collapsing spaces; default to 'Unknown'.
     * @param companyValue The company to normalize.
     * @return Normalized company.
     */
    public static String normalizeCompany(String companyValue) {
        String normalized = normalizeSpaces(companyValue);
        if (String.isBlank(normalized)) {
            return 'Unknown';
        }
        return normalized;
    }

    /**
     * @description Normalize first name by trimming and collapsing spaces.
     * @param firstNameValue The first name to normalize.
     * @return Normalized first name or null.
     */
    public static String normalizeFirstName(String firstNameValue) {
        return normalizeSpaces(firstNameValue);
    }

    /**
     * @description Normalize last name by trimming and collapsing spaces; default to 'Unknown'.
     * @param lastNameValue The last name to normalize.
     * @return Normalized last name.
     */
    public static String normalizeLastName(String lastNameValue) {
        String normalized = normalizeSpaces(lastNameValue);
        if (String.isBlank(normalized)) {
            return 'Unknown';
        }
        return normalized;
    }

    /**
     * @description Trim and collapse multiple whitespace characters to a single space.
     * @param value The string to normalize.
     * @return Normalized string or null.
     */
    public static String normalizeSpaces(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        return value.trim().replaceAll('\\s+', ' ');
    }
}