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

@Entity("packs")
export class Pack {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ length: 255 })
    name!: string;

    @Column({ type: "text", nullable: true })
    description?: string;

    @Column({ name: "cover_image", type: "text" })
    coverImage!: string;

    @Column({ length: 255, default: "AWG Studio" })
    author!: string;

    @Column({ name: "is_pro", default: false })
    @Index()
    isPro!: boolean;

    @Column({ name: "wallpaper_count", default: 0 })
    wallpaperCount!: number;

    @Column({ name: "is_active", default: true })
    @Index()
    isActive!: boolean;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;

    @UpdateDateColumn({ name: "updated_at" })
    updatedAt!: Date;

    @OneToMany(() => Wallpaper, (wallpaper) => wallpaper.pack)
    wallpapers!: Wallpaper[];
}
