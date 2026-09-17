import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    ManyToOne,
    JoinColumn,
    Index,
} from "typeorm";
import { User } from "./User";

@Entity("community_posts")
export class CommunityPost {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ name: "user_id" })
    @Index()
    userId!: number;

    @ManyToOne(() => User, { onDelete: "CASCADE" })
    @JoinColumn({ name: "user_id" })
    author!: User;

    @Column({ name: "image_url", type: "text" })
    imageUrl!: string;

    @Column({ name: "thumbnail_url", type: "text", nullable: true })
    thumbnailUrl?: string;

    @Column({ length: 255, nullable: true })
    title?: string;

    @Column({ type: "text", nullable: true })
    description?: string;

    @Column({ type: "int", nullable: true })
    width?: number;

    @Column({ type: "int", nullable: true })
    height?: number;

    @Column({ name: "likes_count", default: 0 })
    likesCount!: number;

    @Column({ name: "comments_count", default: 0 })
    commentsCount!: number;

    @Column({ name: "saves_count", default: 0 })
    savesCount!: number;

    @Column({ name: "downloads_count", default: 0 })
    downloadsCount!: number;

    @Column({ name: "is_approved", default: true })
    isApproved!: boolean;

    @Column({ name: "is_reported", default: false })
    isReported!: boolean;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;

    @UpdateDateColumn({ name: "updated_at" })
    updatedAt!: Date;
}
