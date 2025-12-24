export declare class User {
    id: number;
    email: string;
    password?: string;
    displayName: string;
    photoUrl?: string;
    firebaseUid?: string;
    authProvider: "email" | "google" | "admin";
    role: "user" | "admin";
    subscriptionPlan: "free" | "monthly" | "annual" | "lifetime";
    subscriptionExpiryDate?: Date;
    subscriptionPurchaseToken?: string;
    downloads: number;
    fcmToken?: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    get subscription(): {
        plan?: string;
        expiryDate?: Date;
        purchaseToken?: string;
    };
    set subscription(value: {
        plan?: string;
        expiryDate?: Date;
        purchaseToken?: string;
    });
    hashPassword(): Promise<void>;
    comparePassword(candidatePassword: string): Promise<boolean>;
}
//# sourceMappingURL=User.d.ts.map