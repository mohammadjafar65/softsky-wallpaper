import { User } from "./User";
import { CommunityPost } from "./CommunityPost";
export declare class CommunityComment {
    id: number;
    userId: number;
    postId: number;
    content: string;
    author: User;
    post: CommunityPost;
    createdAt: Date;
}
//# sourceMappingURL=CommunityComment.d.ts.map