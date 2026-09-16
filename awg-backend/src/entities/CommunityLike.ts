import {
    Entity,
    ManyToOne,
    JoinColumn,
    PrimaryColumn,
    CreateDateColumn,
    Index,
} from "typeorm";
import { User } from "./User";
import { CommunityPost } from "./CommunityPost";

@Entity("community_likes")
@Index(["userId", "postId"], { unique: true })
export class CommunityLike {
    @PrimaryColumn({ name: "user_id" })
    userId!: number;

    @PrimaryColumn({ name: "post_id" })
    postId!: number;

    @ManyToOne(() => User, { onDelete: "CASCADE" })
    @JoinColumn({ name: "user_id" })
    user!: User;

    @ManyToOne(() => CommunityPost, { onDelete: "CASCADE" })
    @JoinColumn({ name: "post_id" })
    post!: CommunityPost;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;
}
