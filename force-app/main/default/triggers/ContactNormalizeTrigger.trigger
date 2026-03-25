/**
 * @description Normalizes Contact name, email, and phone fields before insert/update.
 */
trigger ContactNormalizeTrigger on Contact (before insert, before update) {
    // Normalize each contact in the trigger context (bulk-safe, no SOQL/DML).
    for (Contact c : Trigger.new) {
        // Trim FirstName and LastName; blank becomes null.
        if (c.FirstName != null) {
            String firstNameTrimmed = c.FirstName.trim();
            c.FirstName = String.isBlank(firstNameTrimmed) ? null : firstNameTrimmed;
        }
        if (c.LastName != null) {
            String lastNameTrimmed = c.LastName.trim();
            c.LastName = String.isBlank(lastNameTrimmed) ? null : lastNameTrimmed;
        }

        // Trim and lowercase Email; blank becomes null.
        if (c.Email != null) {
            String emailTrimmed = c.Email.trim();
            c.Email = String.isBlank(emailTrimmed) ? null : emailTrimmed.toLowerCase();
        }

        // Normalize Phone to digits-only; blank becomes null.
        if (c.Phone != null) {
            String phoneTrimmed = c.Phone.trim();
            String phoneDigits = phoneTrimmed.replaceAll('[^0-9]', '');
            c.Phone = String.isBlank(phoneDigits) ? null : phoneDigits;
        }

        // Normalize MobilePhone to digits-only; blank becomes null.
        if (c.MobilePhone != null) {
            String mobileTrimmed = c.MobilePhone.trim();
            String mobileDigits = mobileTrimmed.replaceAll('[^0-9]', '');
            c.MobilePhone = String.isBlank(mobileDigits) ? null : mobileDigits;
        }
    }
}
