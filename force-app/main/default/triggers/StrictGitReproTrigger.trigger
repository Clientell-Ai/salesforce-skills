trigger StrictGitReproTrigger on Contact (before insert, before update) {
    for (Contact currentContact : Trigger.new) {
        String lastName = currentContact.LastName == null ? '' : currentContact.LastName.trim();
        if (String.isBlank(lastName)) {
            currentContact.LastName.addError('Last Name is required.');
        } else {
            currentContact.LastName = lastName;
        }

        if (String.isNotBlank(currentContact.Email)) {
            currentContact.Email = currentContact.Email.trim().toLowerCase();
        }
    }
}
