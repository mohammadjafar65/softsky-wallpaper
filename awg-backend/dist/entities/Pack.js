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
exports.Pack = void 0;
const typeorm_1 = require("typeorm");
const Wallpaper_1 = require("./Wallpaper");
let Pack = class Pack {
};
exports.Pack = Pack;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)(),
    __metadata("design:type", Number)
], Pack.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 255 }),
    __metadata("design:type", String)
], Pack.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: "text", nullable: true }),
    __metadata("design:type", String)
], Pack.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "cover_image", type: "text" }),
    __metadata("design:type", String)
], Pack.prototype, "coverImage", void 0);
__decorate([
    (0, typeorm_1.Column)({ length: 255, default: "AWG Studio" }),
    __metadata("design:type", String)
], Pack.prototype, "author", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "is_pro", default: false }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", Boolean)
], Pack.prototype, "isPro", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "wallpaper_count", default: 0 }),
    __metadata("design:type", Number)
], Pack.prototype, "wallpaperCount", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "is_active", default: true }),
    (0, typeorm_1.Index)(),
    __metadata("design:type", Boolean)
], Pack.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: "created_at" }),
    __metadata("design:type", Date)
], Pack.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: "updated_at" }),
    __metadata("design:type", Date)
], Pack.prototype, "updatedAt", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => Wallpaper_1.Wallpaper, (wallpaper) => wallpaper.pack),
    __metadata("design:type", Array)
], Pack.prototype, "wallpapers", void 0);
exports.Pack = Pack = __decorate([
    (0, typeorm_1.Entity)("packs")
], Pack);
//# sourceMappingURL=Pack.js.map