import { Document } from 'mongoose';
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
declare const _default: any;
export default _default;
//# sourceMappingURL=Category.d.ts.map