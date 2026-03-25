trigger ContactNormalizeTrigger_39 on Contact (before insert, before update) {
    ContactNormalizeTrigger39Handler.handle(Trigger.new);
}
