import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    ManyToOne,
    JoinColumn,
    Index,
} from "typeorm";
import { User } from "./User";
import { CommunityPost } from "./CommunityPost";

export type ReportReason = "spam" | "nudity" | "copyright" | "other";

@Entity("post_reports")
export class PostReport {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ name: "reporter_id" })
    @Index()
    reporterId!: number;

    @Column({ name: "post_id" })
    @Index()
    postId!: number;

    @Column({
        type: "enum",
        enum: ["spam", "nudity", "copyright", "other"],
        default: "other",
    })
    reason!: ReportReason;

    @ManyToOne(() => User, { onDelete: "CASCADE" })
    @JoinColumn({ name: "reporter_id" })
    reporter!: User;

    @ManyToOne(() => CommunityPost, { onDelete: "CASCADE" })
    @JoinColumn({ name: "post_id" })
    post!: CommunityPost;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;
}
