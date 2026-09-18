import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    Index,
} from "typeorm";

@Entity("notification_templates")
export class NotificationTemplate {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ length: 255 })
    name!: string;

    @Column({ length: 255 })
    title!: string;

    @Column({ type: "text" })
    message!: string;

    @Column({ name: "image_url", type: "text", nullable: true })
    imageUrl?: string;

    @Column({ length: 50, default: "general" })
    category!: string;

    @Column({ name: "is_premade", default: false })
    @Index()
    isPremade!: boolean;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;

    @UpdateDateColumn({ name: "updated_at" })
    updatedAt!: Date;
}
