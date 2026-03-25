trigger AccountNamePolicyRnd26A on Account (before insert, before update) {
    for (Account acc : Trigger.new) {
        if (acc.Name != null) {
            acc.Name = acc.Name.trim();
        }
        if (acc.Website != null) {
            acc.Website = acc.Website.toLowerCase();
        }
    }
}
