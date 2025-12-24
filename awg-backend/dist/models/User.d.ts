import mongoose, { Document } from 'mongoose';
export interface IUser extends Document {
    email: string;
    password?: string;
    displayName: string;
    photoUrl?: string;
    firebaseUid?: string;
    authProvider: 'email' | 'google' | 'admin';
    role: 'user' | 'admin';
    subscription: {
        plan: 'free' | 'monthly' | 'annual' | 'lifetime';
        expiryDate?: Date;
        purchaseToken?: string;
    };
    favorites: mongoose.Types.ObjectId[];
    downloads: number;
    fcmToken?: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    comparePassword(candidatePassword: string): Promise<boolean>;
}
declare const _default: any;
export default _default;
//# sourceMappingURL=User.d.ts.map