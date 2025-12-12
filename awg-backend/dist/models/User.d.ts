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
        plan: 'free' | 'weekly' | 'monthly' | 'yearly' | 'lifetime';
        expiryDate?: Date;
        purchaseToken?: string;
    };
    favorites: mongoose.Types.ObjectId[];
    downloads: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    comparePassword(candidatePassword: string): Promise<boolean>;
}
declare const _default: mongoose.Model<IUser, {}, {}, {}, mongoose.Document<unknown, {}, IUser, {}, {}> & IUser & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any>;
export default _default;
//# sourceMappingURL=User.d.ts.map