trigger LeadTwoPromptPRFlow26 on Lead (before insert, before update) {
    LeadTwoPromptPRFlow26Handler.handleBefore(Trigger.new);
}
