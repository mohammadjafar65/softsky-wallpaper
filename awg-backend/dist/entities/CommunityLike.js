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
exports.CommunityLike = void 0;
const typeorm_1 = require("typeorm");
const User_1 = require("./User");
const CommunityPost_1 = require("./CommunityPost");
let CommunityLike = class CommunityLike {
};
exports.CommunityLike = CommunityLike;
__decorate([
    (0, typeorm_1.PrimaryColumn)({ name: "user_id" }),
    __metadata("design:type", Number)
], CommunityLike.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.PrimaryColumn)({ name: "post_id" }),
    __metadata("design:type", Number)
], CommunityLike.prototype, "postId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => User_1.User, { onDelete: "CASCADE" }),
    (0, typeorm_1.JoinColumn)({ name: "user_id" }),
    __metadata("design:type", User_1.User)
], CommunityLike.prototype, "user", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => CommunityPost_1.CommunityPost, { onDelete: "CASCADE" }),
    (0, typeorm_1.JoinColumn)({ name: "post_id" }),
    __metadata("design:type", CommunityPost_1.CommunityPost)
], CommunityLike.prototype, "post", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: "created_at" }),
    __metadata("design:type", Date)
], CommunityLike.prototype, "createdAt", void 0);
exports.CommunityLike = CommunityLike = __decorate([
    (0, typeorm_1.Entity)("community_likes"),
    (0, typeorm_1.Index)(["userId", "postId"], { unique: true })
], CommunityLike);
//# sourceMappingURL=CommunityLike.js.map