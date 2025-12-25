import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    OneToMany,
    Index,
} from "typeorm";
import { Wallpaper } from "./Wallpaper";

@Entity("categories")
export class Category {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ unique: true, length: 255 })
    name!: string;

    @Column({ unique: true, length: 255 })
    slug!: string;

    @Column({
        length: 50,
        nullable: true,
        charset: "utf8mb4",
        collation: "utf8mb4_unicode_ci",
    })
    icon?: string;

    @Column({ type: "text", nullable: true })
    description?: string;

    @Column({ name: "wallpaper_count", default: 0 })
    wallpaperCount!: number;

    @Column({ name: "is_active", default: true })
    @Index()
    isActive!: boolean;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;

    @UpdateDateColumn({ name: "updated_at" })
    updatedAt!: Date;

    @OneToMany(() => Wallpaper, (wallpaper) => wallpaper.category)
    wallpapers!: Wallpaper[];
}
