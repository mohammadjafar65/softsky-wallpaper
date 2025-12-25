import { Wallpaper } from "./Wallpaper";
export declare class Category {
    id: number;
    name: string;
    slug: string;
    icon?: string;
    description?: string;
    wallpaperCount: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    wallpapers: Wallpaper[];
}
//# sourceMappingURL=Category.d.ts.map