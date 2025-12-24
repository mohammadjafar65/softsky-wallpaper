import { Document } from 'mongoose';
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
declare const _default: any;
export default _default;
//# sourceMappingURL=Pack.d.ts.map