import mongoose, { Document } from 'mongoose';
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
declare const _default: any;
export default _default;
//# sourceMappingURL=Wallpaper.d.ts.map