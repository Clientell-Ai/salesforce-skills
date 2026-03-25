/**
 * @description Minimal class used to generate a safe source change for push-failure testing.
 */
public with sharing class PushFailureProbe {
    /**
     * @description Returns a fixed status string.
     * @return Status text.
     */
    public static String status() {
        return "READY";
    }
}
