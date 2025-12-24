import mongoose, { Document, Schema } from 'mongoose';

export interface ICategory extends Document {
    name: string;
    slug: string;
    icon: string;
    description?: string;
    wallpaperCount: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}

const categorySchema = new Schema<ICategory>({
    name: { type: String, required: true, unique: true, trim: true },
    slug: { type: String, required: true, unique: true, lowercase: true, trim: true },
    icon: { type: String, default: '🎨' },
    description: { type: String, trim: true },
    wallpaperCount: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
}, {
    timestamps: true,
});

categorySchema.index({ isActive: 1 });

export default mongoose.model<ICategory>('Category', categorySchema);
