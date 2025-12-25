import "reflect-metadata";
import { DataSource } from "typeorm";
import { User } from "./entities/User";
import { Wallpaper } from "./entities/Wallpaper";
import { Category } from "./entities/Category";
import { Pack } from "./entities/Pack";

export const AppDataSource = new DataSource({
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
    entities: [User, Wallpaper, Category, Pack],
    subscribers: [],
    migrations: [],
});
