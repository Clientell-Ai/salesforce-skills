/**
 * @description Provides greeting utilities for Clientell.
 */
public with sharing class HelloClientell {
    /**
     * @description Returns a formatted greeting.
     * @param name The optional name to include in the greeting.
     * @return A greeting message addressed to the provided name or Clientell.
     */
    public static String hello(String name) {
        if (String.isBlank(name)) {
            return 'Hello, Clientell!';
        }
        return 'Hello, ' + name.trim() + '!';
    }
}
