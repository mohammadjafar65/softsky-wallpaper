export declare const getFirebaseStatus: () => {
    initialized: boolean;
    projectId: string | null;
    hasClientEmail: boolean;
    hasPrivateKey: boolean;
    hasServiceAccountPath: boolean;
};
/**
 * Send notification to a single device token
 */
export declare const sendNotificationToToken: (token: string, title: string, body: string, data?: Record<string, string>, imageUrl?: string) => Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
}>;
/**
 * Send notification to multiple device tokens
 */
export declare const sendNotificationToTokens: (tokens: string[], title: string, body: string, data?: Record<string, string>, imageUrl?: string) => Promise<{
    successCount: number;
    failureCount: number;
    errors: any[];
}>;
/**
 * Send notification to a specific user by user ID
 */
export declare const sendNotificationToUser: (userId: string, title: string, body: string, data?: Record<string, string>, imageUrl?: string) => Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
}>;
/**
 * Send notification to all users with FCM tokens
 */
export declare const sendNotificationToAll: (title: string, body: string, data?: Record<string, string>, imageUrl?: string) => Promise<{
    successCount: number;
    failureCount: number;
    totalUsers: number;
}>;
declare const _default: {
    getFirebaseStatus: () => {
        initialized: boolean;
        projectId: string | null;
        hasClientEmail: boolean;
        hasPrivateKey: boolean;
        hasServiceAccountPath: boolean;
    };
    sendNotificationToToken: (token: string, title: string, body: string, data?: Record<string, string>, imageUrl?: string) => Promise<{
        success: boolean;
        messageId?: string;
        error?: string;
    }>;
    sendNotificationToTokens: (tokens: string[], title: string, body: string, data?: Record<string, string>, imageUrl?: string) => Promise<{
        successCount: number;
        failureCount: number;
        errors: any[];
    }>;
    sendNotificationToUser: (userId: string, title: string, body: string, data?: Record<string, string>, imageUrl?: string) => Promise<{
        success: boolean;
        messageId?: string;
        error?: string;
    }>;
    sendNotificationToAll: (title: string, body: string, data?: Record<string, string>, imageUrl?: string) => Promise<{
        successCount: number;
        failureCount: number;
        totalUsers: number;
    }>;
};
export default _default;
//# sourceMappingURL=fcm.d.ts.map