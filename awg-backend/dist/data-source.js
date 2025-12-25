"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppDataSource = void 0;
require("reflect-metadata");
const typeorm_1 = require("typeorm");
const User_1 = require("./entities/User");
const Wallpaper_1 = require("./entities/Wallpaper");
const Category_1 = require("./entities/Category");
const Pack_1 = require("./entities/Pack");
exports.AppDataSource = new typeorm_1.DataSource({
    type: "mysql",
    host: process.env.MYSQL_HOST || "localhost",
    port: parseInt(process.env.MYSQL_PORT || "3306"),
    username: process.env.MYSQL_USER || "root",
    password: process.env.MYSQL_PASSWORD || "",
    database: process.env.MYSQL_DATABASE || "softoatk_ssw_wallpaper",
    synchronize: process.env.NODE_ENV !== "production", // Auto-sync in dev only
    logging: process.env.NODE_ENV !== "production",
    entities: [User_1.User, Wallpaper_1.Wallpaper, Category_1.Category, Pack_1.Pack],
    subscribers: [],
    migrations: [],
});
//# sourceMappingURL=data-source.js.map