import { User } from "./User";
import { CommunityPost } from "./CommunityPost";
export type ReportReason = "spam" | "nudity" | "copyright" | "other";
export declare class PostReport {
    id: number;
    reporterId: number;
    postId: number;
    reason: ReportReason;
    reporter: User;
    post: CommunityPost;
    createdAt: Date;
}
//# sourceMappingURL=PostReport.d.ts.map