"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.User = void 0;
const typeorm_1 = require("typeorm");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
let User = class User {
    // Helper getter/setter to maintain API compatibility
    get subscription() {
        return {
            plan: this.subscriptionPlan,
            expiryDate: this.subscriptionExpiryDate,
            purchaseToken: this.subscriptionPurchaseToken,
        };
    }
    set subscription(value) {
        if (value.plan)
            this.subscriptionPlan = value.plan;
        if (value.expiryDate !== undefined)
            this.subscriptionExpiryDate = value.expiryDate;
        if (value.purchaseToken !== undefined)
            this.subscriptionPurchaseToken = value.purchaseToken;
    }
    async hashPassword() {
        if (this.password && this.password.length < 60) {
            // Only hash if not already hashed
            const salt = await bcryptjs_1.default.genSalt(10);
            this.password = await bcryptjs_1.default.hash(this.password, salt);
        }
    }
    async comparePassword(candidatePassword) {
        if (!this.password)
            return false;
        return bcryptjs_1.default.compare(candidatePassword, this.password);
    }
};
exports.User = User;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)(),
    __metadata("design:type", Number)
], User.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ unique: true, length: 255 }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", String)
], User.prototype, "email", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true, select: false, length: 255 }),
    __metadata("design:type", String)
], User.prototype, "password", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "display_name", length: 255 }),
    __metadata("design:type", String)
], User.prototype, "displayName", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "photo_url", type: "text", nullable: true }),
    __metadata("design:type", String)
], User.prototype, "photoUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "firebase_uid", unique: true, nullable: true, length: 255 }),
    __metadata("design:type", String)
], User.prototype, "firebaseUid", void 0);
__decorate([
    (0, typeorm_1.Column)({
        name: "auth_provider",
        type: "enum",
        enum: ["email", "google", "admin"],
        default: "email",
    }),
    __metadata("design:type", String)
], User.prototype, "authProvider", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: "enum",
        enum: ["user", "admin"],
        default: "user",
    }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", String)
], User.prototype, "role", void 0);
__decorate([
    (0, typeorm_1.Column)({
        name: "subscription_plan",
        type: "enum",
        enum: ["free", "monthly", "annual", "lifetime"],
        default: "free",
    }),
    __metadata("design:type", String)
], User.prototype, "subscriptionPlan", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "subscription_expiry_date", type: "datetime", nullable: true }),
    __metadata("design:type", Date)
], User.prototype, "subscriptionExpiryDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "subscription_purchase_token", length: 255, nullable: true }),
    __metadata("design:type", String)
], User.prototype, "subscriptionPurchaseToken", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 0 }),
    __metadata("design:type", Number)
], User.prototype, "downloads", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "fcm_token", type: "text", nullable: true }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", String)
], User.prototype, "fcmToken", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "is_active", default: true }),
    __metadata("design:type", Boolean)
], User.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: "created_at" }),
    __metadata("design:type", Date)
], User.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: "updated_at" }),
    __metadata("design:type", Date)
], User.prototype, "updatedAt", void 0);
__decorate([
    (0, typeorm_1.BeforeInsert)(),
    (0, typeorm_1.BeforeUpdate)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], User.prototype, "hashPassword", null);
exports.User = User = __decorate([
    (0, typeorm_1.Entity)("users")
], User);
//# sourceMappingURL=User.js.map