import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    BeforeInsert,
    BeforeUpdate,
    ManyToMany,
    JoinTable,
    Index,
} from "typeorm";
import bcrypt from "bcryptjs";

@Entity("users")
export class User {
    @PrimaryGeneratedColumn()
    id!: number;

    @Column({ unique: true, length: 255 })
    @Index()
    email!: string;

    @Column({ nullable: true, select: false, length: 255 })
    password?: string;

    @Column({ name: "display_name", length: 255 })
    displayName!: string;

    @Column({ name: "photo_url", type: "text", nullable: true })
    photoUrl?: string;

    @Column({ name: "firebase_uid", unique: true, nullable: true, length: 255 })
    firebaseUid?: string;

    @Column({
        name: "auth_provider",
        type: "enum",
        enum: ["email", "google", "admin"],
        default: "email",
    })
    authProvider!: "email" | "google" | "admin";

    @Column({
        type: "enum",
        enum: ["user", "admin"],
        default: "user",
    })
    @Index()
    role!: "user" | "admin";

    // Embedded subscription fields
    @Column({
        name: "subscription_plan",
        type: "enum",
        enum: ["free", "monthly", "annual", "lifetime"],
        default: "free",
    })
    subscriptionPlan!: "free" | "monthly" | "annual" | "lifetime";

    @Column({ name: "subscription_expiry_date", type: "datetime", nullable: true })
    subscriptionExpiryDate?: Date;

    @Column({ name: "subscription_purchase_token", length: 255, nullable: true })
    subscriptionPurchaseToken?: string;

    @Column({ default: 0 })
    downloads!: number;

    @Column({ name: "fcm_token", type: "text", nullable: true })
    @Index()
    fcmToken?: string;

    @Column({ name: "is_active", default: true })
    isActive!: boolean;

    @CreateDateColumn({ name: "created_at" })
    createdAt!: Date;

    @UpdateDateColumn({ name: "updated_at" })
    updatedAt!: Date;

    // Helper getter/setter to maintain API compatibility
    get subscription() {
        return {
            plan: this.subscriptionPlan,
            expiryDate: this.subscriptionExpiryDate,
            purchaseToken: this.subscriptionPurchaseToken,
        };
    }

    set subscription(value: { plan?: string; expiryDate?: Date; purchaseToken?: string }) {
        if (value.plan) this.subscriptionPlan = value.plan as any;
        if (value.expiryDate !== undefined) this.subscriptionExpiryDate = value.expiryDate;
        if (value.purchaseToken !== undefined) this.subscriptionPurchaseToken = value.purchaseToken;
    }

    @BeforeInsert()
    @BeforeUpdate()
    async hashPassword() {
        if (this.password && this.password.length < 60) {
            // Only hash if not already hashed
            const salt = await bcrypt.genSalt(10);
            this.password = await bcrypt.hash(this.password, salt);
        }
    }

    async comparePassword(candidatePassword: string): Promise<boolean> {
        if (!this.password) return false;
        return bcrypt.compare(candidatePassword, this.password);
    }
}
