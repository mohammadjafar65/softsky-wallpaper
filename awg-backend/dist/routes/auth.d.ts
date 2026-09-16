declare const router: import("express-serve-static-core").Router;
/**
 * Generate a clean, unique username based on display name or email.
 * E.g., "Jafar Mansuri" -> "jafarmansuri" (or "jafarmansuri1" if taken)
 */
export declare function generateUniqueUsername(userRepository: any, nameOrEmail: string, excludeUserId?: number): Promise<string>;
/**
 * Backfill missing usernames for any existing users in DB.
 */
export declare function backfillMissingUsernames(): Promise<void>;
export default router;
//# sourceMappingURL=auth.d.ts.map