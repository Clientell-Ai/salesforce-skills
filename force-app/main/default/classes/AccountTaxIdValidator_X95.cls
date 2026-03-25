/**
 * @description Validates Indian GSTIN-style tax IDs using structural rules and check digit verification.
 */
public with sharing class AccountTaxIdValidator_X95 {
    private static final String CHARSET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    /**
     * @description Normalizes a GSTIN by trimming, uppercasing, and removing all whitespace.
     * @param gstin Raw GSTIN value.
     * @return Normalized GSTIN string, or null when input is null.
     */
    public static String normalize(String gstin) {
        if (gstin == null) {
            return null;
        }
        return gstin.trim().toUpperCase().replaceAll('\\s+', '');
    }

    /**
     * @description Checks whether the provided GSTIN is valid.
     * @param gstin Raw GSTIN value.
     * @return True when valid, otherwise false.
     */
    public static Boolean isValid(String gstin) {
        return getValidationError(gstin) == null;
    }

    /**
     * @description Returns a short validation message when GSTIN is invalid.
     * @param gstin Raw GSTIN value.
     * @return Null when valid; otherwise a short error message.
     */
    public static String getValidationError(String gstin) {
        if (String.isBlank(gstin)) {
            return 'GSTIN is required';
        }

        String normalizedGstin = normalize(gstin);

        if (normalizedGstin.length() != 15) {
            return 'GSTIN must be 15 characters';
        }

        String stateCode = normalizedGstin.substring(0, 2);
        if (!Pattern.matches('^[0-9]{2}$', stateCode)) {
            return 'Invalid state code';
        }

        String panSegment = normalizedGstin.substring(2, 12);
        if (!Pattern.matches('^[A-Z]{5}[0-9]{4}[A-Z]$', panSegment)) {
            return 'Invalid PAN segment';
        }

        String entityCode = normalizedGstin.substring(12, 13);
        if (!Pattern.matches('^[1-9A-Z]$', entityCode)) {
            return 'Invalid entity code';
        }

        String defaultChar = normalizedGstin.substring(13, 14);
        if (defaultChar != 'Z') {
            return '14th character must be Z';
        }

        String providedCheckChar = normalizedGstin.substring(14, 15);
        String expectedCheckChar = computeCheckChar(normalizedGstin.substring(0, 14));

        if (expectedCheckChar == null || providedCheckChar != expectedCheckChar) {
            return 'Invalid checksum';
        }

        return null;
    }

    /**
     * @description Computes GSTIN check character for the first 14 GSTIN characters.
     * @param first14 First 14 characters of GSTIN.
     * @return Check character, or null when input has unsupported characters.
     */
    private static String computeCheckChar(String first14) {
        Integer sum = 0;
        Integer factor = 2;

        for (Integer i = first14.length() - 1; i >= 0; i--) {
            Integer codePoint = codePointFor(first14.substring(i, i + 1));
            if (codePoint < 0) {
                return null;
            }

            Integer product = codePoint * factor;
            Integer addend = (product / 36) + Math.mod(product, 36);
            sum += addend;
            factor = (factor == 2) ? 1 : 2;
        }

        Integer checkCodePoint = Math.mod(36 - Math.mod(sum, 36), 36);
        return CHARSET.substring(checkCodePoint, checkCodePoint + 1);
    }

    /**
     * @description Converts a base36 character to its numeric code point.
     * @param ch Single alphanumeric character.
     * @return 0-35 for valid characters; otherwise -1.
     */
    private static Integer codePointFor(String ch) {
        return CHARSET.indexOf(ch);
    }
}
