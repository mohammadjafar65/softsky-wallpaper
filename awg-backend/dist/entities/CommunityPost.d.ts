import { User } from "./User";
export declare class CommunityPost {
    id: number;
    userId: number;
    author: User;
    imageUrl: string;
    thumbnailUrl?: string;
    title?: string;
    description?: string;
    width?: number;
    height?: number;
    likesCount: number;
    commentsCount: number;
    savesCount: number;
    isApproved: boolean;
    isReported: boolean;
    createdAt: Date;
    updatedAt: Date;
}
//# sourceMappingURL=CommunityPost.d.ts.map