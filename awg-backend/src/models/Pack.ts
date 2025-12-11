import mongoose, { Document, Schema } from 'mongoose';

export interface IPack extends Document {
    name: string;
    description: string;
    coverImage: string;
    author: string;
    isPro: boolean;
    wallpaperCount: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}

const packSchema = new Schema<IPack>({
    name: { type: String, required: true, trim: true },
    description: { type: String, trim: true },
    coverImage: { type: String, required: true },
    author: { type: String, default: 'AWG Studio' },
    isPro: { type: Boolean, default: false },
    wallpaperCount: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
}, {
    timestamps: true,
});

packSchema.index({ isPro: 1 });
packSchema.index({ isActive: 1 });

export default mongoose.model<IPack>('Pack', packSchema);
