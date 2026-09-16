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
exports.Follow = void 0;
const typeorm_1 = require("typeorm");
const User_1 = require("./User");
let Follow = class Follow {
};
exports.Follow = Follow;
__decorate([
    (0, typeorm_1.PrimaryColumn)({ name: "follower_id" }),
    __metadata("design:type", Number)
], Follow.prototype, "followerId", void 0);
__decorate([
    (0, typeorm_1.PrimaryColumn)({ name: "following_id" }),
    __metadata("design:type", Number)
], Follow.prototype, "followingId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => User_1.User, { onDelete: "CASCADE" }),
    (0, typeorm_1.JoinColumn)({ name: "follower_id" }),
    __metadata("design:type", User_1.User)
], Follow.prototype, "follower", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => User_1.User, { onDelete: "CASCADE" }),
    (0, typeorm_1.JoinColumn)({ name: "following_id" }),
    __metadata("design:type", User_1.User)
], Follow.prototype, "following", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: "created_at" }),
    __metadata("design:type", Date)
], Follow.prototype, "createdAt", void 0);
exports.Follow = Follow = __decorate([
    (0, typeorm_1.Entity)("user_follows"),
    (0, typeorm_1.Index)(["followerId", "followingId"], { unique: true })
], Follow);
//# sourceMappingURL=Follow.js.map