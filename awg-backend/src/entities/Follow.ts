import {
    Entity,
    Column,
    CreateDateColumn,
    ManyToOne,
    JoinColumn,
    PrimaryColumn,
    Index,
} from "typeorm";
import { User } from "./User";

@Entity("user_follows")
@Index(["followerId", "followingId"], { unique: true })
export class Follow {
    @PrimaryColumn({ name: "follower_id" })
    followerId!: number;

    @PrimaryColumn({ name: "following_id" })
    followingId!: number;

    @ManyToOne(() => User, { onDelete: "CASCADE" })
    @JoinColumn({ name: "follower_id" })
    follower!: User;

    @ManyToOne(() => User, { onDelete: "CASCADE" })
    @JoinColumn({ name: "following_id" })
    following!: User;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;
}
