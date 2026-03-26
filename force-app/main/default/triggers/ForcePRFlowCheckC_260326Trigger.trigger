trigger ForcePRFlowCheckC_260326Trigger on Account (before insert, before update) {
    ForcePRFlowCheckC_260326.normalizeAccounts(Trigger.new);
}
