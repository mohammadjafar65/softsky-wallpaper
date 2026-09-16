"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppDataSource = void 0;
require("reflect-metadata");
const typeorm_1 = require("typeorm");
const User_1 = require("./entities/User");
const Wallpaper_1 = require("./entities/Wallpaper");
const Category_1 = require("./entities/Category");
const Pack_1 = require("./entities/Pack");
const CommunityPost_1 = require("./entities/CommunityPost");
const Follow_1 = require("./entities/Follow");
const CommunityLike_1 = require("./entities/CommunityLike");
const CommunityComment_1 = require("./entities/CommunityComment");
const CommunitySave_1 = require("./entities/CommunitySave");
const PostReport_1 = require("./entities/PostReport");
exports.AppDataSource = new typeorm_1.DataSource({
    type: "mysql",
    host: process.env.MYSQL_HOST || "localhost",
    port: parseInt(process.env.MYSQL_PORT || "3306"),
    username: process.env.MYSQL_USER || "root",
    password: process.env.MYSQL_PASSWORD || "",
    database: process.env.MYSQL_DATABASE || "softoatk_ssw_wallpaper",
    charset: "utf8mb4", // Ensure connection supports emojis
    extra: {
        connectionLimit: 10, // Create a connection pool
        waitForConnections: true,
        queueLimit: 0
    },
    synchronize: process.env.NODE_ENV !== "production", // Auto-sync in dev only
    logging: process.env.NODE_ENV !== "production",
    entities: [User_1.User, Wallpaper_1.Wallpaper, Category_1.Category, Pack_1.Pack, CommunityPost_1.CommunityPost, Follow_1.Follow, CommunityLike_1.CommunityLike, CommunityComment_1.CommunityComment, CommunitySave_1.CommunitySave, PostReport_1.PostReport],
    subscribers: [],
    migrations: [],
});
//# sourceMappingURL=data-source.js.map