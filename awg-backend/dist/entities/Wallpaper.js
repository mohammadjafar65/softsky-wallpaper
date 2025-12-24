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
exports.Wallpaper = void 0;
const typeorm_1 = require("typeorm");
const Category_1 = require("./Category");
const Pack_1 = require("./Pack");
let Wallpaper = class Wallpaper {
};
exports.Wallpaper = Wallpaper;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)(),
    __metadata("design:type", Number)
], Wallpaper.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 255 }),
    __metadata("design:type", String)
], Wallpaper.prototype, "title", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "image_url", type: "text" }),
    __metadata("design:type", String)
], Wallpaper.prototype, "imageUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "thumbnail_url", type: "text" }),
    __metadata("design:type", String)
], Wallpaper.prototype, "thumbnailUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "category_id" }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", Number)
], Wallpaper.prototype, "categoryId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => Category_1.Category, (category) => category.wallpapers),
    (0, typeorm_1.JoinColumn)({ name: "category_id" }),
    __metadata("design:type", Category_1.Category)
], Wallpaper.prototype, "category", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: "json", nullable: true }),
    __metadata("design:type", Array)
], Wallpaper.prototype, "tags", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "is_wide", default: false }),
    __metadata("design:type", Boolean)
], Wallpaper.prototype, "isWide", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "is_pro", default: false }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", Boolean)
], Wallpaper.prototype, "isPro", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "pack_id", nullable: true }),
    __metadata("design:type", Number)
], Wallpaper.prototype, "packId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => Pack_1.Pack, (pack) => pack.wallpapers, { nullable: true, onDelete: "SET NULL" }),
    (0, typeorm_1.JoinColumn)({ name: "pack_id" }),
    __metadata("design:type", Pack_1.Pack)
], Wallpaper.prototype, "pack", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 0 }),
    __metadata("design:type", Number)
], Wallpaper.prototype, "downloads", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 0 }),
    __metadata("design:type", Number)
], Wallpaper.prototype, "views", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: "created_at" }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", Date)
], Wallpaper.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: "updated_at" }),
    __metadata("design:type", Date)
], Wallpaper.prototype, "updatedAt", void 0);
exports.Wallpaper = Wallpaper = __decorate([
    (0, typeorm_1.Entity)("wallpapers")
], Wallpaper);
//# sourceMappingURL=Wallpaper.js.map