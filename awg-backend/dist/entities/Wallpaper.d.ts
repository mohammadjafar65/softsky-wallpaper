import { Category } from "./Category";
import { Pack } from "./Pack";
export declare class Wallpaper {
    id: number;
    title: string;
    imageUrl: string;
    thumbnailUrl: string;
    categoryId: number;
    category: Category;
    tags: string[];
    isWide: boolean;
    isPro: boolean;
    packId?: number;
    pack?: Pack;
    downloads: number;
    views: number;
    createdAt: Date;
    updatedAt: Date;
}
//# sourceMappingURL=Wallpaper.d.ts.map