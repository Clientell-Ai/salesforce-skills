trigger ContactNormalizeTrigger_39 on Contact (before insert, before update) {
    ContactNormalizeTrigger_39_Handler.run(
        Trigger.new,
        Trigger.oldMap,
        Trigger.isInsert,
        Trigger.isUpdate
    );
}
