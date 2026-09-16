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
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommunityPost = void 0;
const typeorm_1 = require("typeorm");
const User_1 = require("./User");
let CommunityPost = class CommunityPost {
};
exports.CommunityPost = CommunityPost;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)(),
    __metadata("design:type", Number)
], CommunityPost.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "user_id" }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", Number)
], CommunityPost.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => User_1.User, { onDelete: "CASCADE" }),
    (0, typeorm_1.JoinColumn)({ name: "user_id" }),
    __metadata("design:type", User_1.User)
], CommunityPost.prototype, "author", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "image_url", type: "text" }),
    __metadata("design:type", String)
], CommunityPost.prototype, "imageUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "thumbnail_url", type: "text", nullable: true }),
    __metadata("design:type", String)
], CommunityPost.prototype, "thumbnailUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 255, nullable: true }),
    __metadata("design:type", String)
], CommunityPost.prototype, "title", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: "text", nullable: true }),
    __metadata("design:type", String)
], CommunityPost.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: "int", nullable: true }),
    __metadata("design:type", Number)
], CommunityPost.prototype, "width", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: "int", nullable: true }),
    __metadata("design:type", Number)
], CommunityPost.prototype, "height", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "likes_count", default: 0 }),
    __metadata("design:type", Number)
], CommunityPost.prototype, "likesCount", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "comments_count", default: 0 }),
    __metadata("design:type", Number)
], CommunityPost.prototype, "commentsCount", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "saves_count", default: 0 }),
    __metadata("design:type", Number)
], CommunityPost.prototype, "savesCount", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "is_approved", default: true }),
    __metadata("design:type", Boolean)
], CommunityPost.prototype, "isApproved", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "is_reported", default: false }),
    __metadata("design:type", Boolean)
], CommunityPost.prototype, "isReported", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: "created_at" }),
    __metadata("design:type", Date)
], CommunityPost.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: "updated_at" }),
    __metadata("design:type", Date)
], CommunityPost.prototype, "updatedAt", void 0);
exports.CommunityPost = CommunityPost = __decorate([
    (0, typeorm_1.Entity)("community_posts")
], CommunityPost);
//# sourceMappingURL=CommunityPost.js.map