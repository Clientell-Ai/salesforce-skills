trigger DuplicatePhoneBlocker_X96 on Lead (before insert, before update) {
    DuplicatePhoneBlocker_X96_Handler.run(Trigger.new, Trigger.oldMap);
}
