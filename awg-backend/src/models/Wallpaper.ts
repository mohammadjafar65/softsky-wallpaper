import mongoose, { Document, Schema } from 'mongoose';

export interface IWallpaper extends Document {
    title: string;
    imageUrl: string;
    thumbnailUrl: string;
    category: mongoose.Types.ObjectId;
    tags: string[];
    isWide: boolean;
    isPro: boolean;
    packId?: mongoose.Types.ObjectId;
    downloads: number;
    views: number;
    createdAt: Date;
    updatedAt: Date;
}

const wallpaperSchema = new Schema<IWallpaper>({
    title: { type: String, required: true, trim: true },
    imageUrl: { type: String, required: true },
    thumbnailUrl: { type: String, required: true },
    category: { type: Schema.Types.ObjectId, ref: 'Category', required: true },
    tags: [{ type: String, trim: true }],
    isWide: { type: Boolean, default: false },
    isPro: { type: Boolean, default: false },
    packId: { type: Schema.Types.ObjectId, ref: 'Pack' },
    downloads: { type: Number, default: 0 },
    views: { type: Number, default: 0 },
}, {
    timestamps: true,
});

// Index for search
wallpaperSchema.index({ title: 'text', tags: 'text' });
wallpaperSchema.index({ category: 1 });
wallpaperSchema.index({ isPro: 1 });
wallpaperSchema.index({ createdAt: -1 });

export default mongoose.model<IWallpaper>('Wallpaper', wallpaperSchema);
