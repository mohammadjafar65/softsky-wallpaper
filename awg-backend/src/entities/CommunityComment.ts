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

@Entity("community_comments")
export class CommunityComment {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ name: "user_id" })
    @Index()
    userId!: number;

    @Column({ name: "post_id" })
    @Index()
    postId!: number;

    @Column({ type: "text" })
    content!: string;

    @ManyToOne(() => User, { onDelete: "CASCADE" })
    @JoinColumn({ name: "user_id" })
    author!: User;

    @ManyToOne(() => CommunityPost, { onDelete: "CASCADE" })
    @JoinColumn({ name: "post_id" })
    post!: CommunityPost;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;
}
