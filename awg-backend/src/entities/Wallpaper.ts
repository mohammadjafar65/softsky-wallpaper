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
import { Category } from "./Category";
import { Pack } from "./Pack";

@Entity("wallpapers")
export class Wallpaper {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ length: 255 })
    title!: string;

    @Column({ name: "image_url", type: "text" })
    imageUrl!: string;

    @Column({ name: "thumbnail_url", type: "text" })
    thumbnailUrl!: string;

    @Column({ name: "category_id" })
    @Index()
    categoryId!: number;

    @ManyToOne(() => Category, (category) => category.wallpapers)
    @JoinColumn({ name: "category_id" })
    category!: Category;

    @Column({ type: "json", nullable: true })
    tags!: string[];

    @Column({ name: "is_wide", default: false })
    isWide!: boolean;

    @Column({ name: "is_pro", default: false })
    @Index()
    isPro!: boolean;

    @Column({ name: "pack_id", nullable: true })
    packId?: number;

    @ManyToOne(() => Pack, (pack) => pack.wallpapers, { nullable: true, onDelete: "SET NULL" })
    @JoinColumn({ name: "pack_id" })
    pack?: Pack;

    @Column({ default: 0 })
    downloads!: number;

    @Column({ default: 0 })
    views!: number;

    @CreateDateColumn({ name: "created_at" })
    @Index()
    createdAt!: Date;

    @UpdateDateColumn({ name: "updated_at" })
    updatedAt!: Date;
}
