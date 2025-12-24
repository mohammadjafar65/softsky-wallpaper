import mongoose, { Document, Schema } from 'mongoose';
import bcrypt from 'bcryptjs';

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

const userSchema = new Schema<IUser>({
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, select: false },
    displayName: { type: String, required: true, trim: true },
    photoUrl: { type: String },
    firebaseUid: { type: String, unique: true, sparse: true },
    authProvider: { type: String, enum: ['email', 'google', 'admin'], default: 'email' },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    subscription: {
        plan: { type: String, enum: ['free', 'monthly', 'annual', 'lifetime'], default: 'free' },
        expiryDate: { type: Date },
        purchaseToken: { type: String },
    },
    favorites: [{ type: Schema.Types.ObjectId, ref: 'Wallpaper' }],
    downloads: { type: Number, default: 0 },
    fcmToken: { type: String },
    isActive: { type: Boolean, default: true },
}, {
    timestamps: true,
});

// Hash password before saving
userSchema.pre('save', async function (next) {
    if (!this.isModified('password') || !this.password) return next();

    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword: string): Promise<boolean> {
    if (!this.password) return false;
    return bcrypt.compare(candidatePassword, this.password);
};

userSchema.index({ role: 1 });
userSchema.index({ fcmToken: 1 });

export default mongoose.model<IUser>('User', userSchema);
