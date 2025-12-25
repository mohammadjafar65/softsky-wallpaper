"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("reflect-metadata");
const dotenv_1 = __importDefault(require("dotenv"));
// Load environment variables immediately
dotenv_1.default.config();
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const data_source_1 = require("./data-source");
// Import routes
const auth_1 = __importDefault(require("./routes/auth"));
const wallpapers_1 = __importDefault(require("./routes/wallpapers"));
const categories_1 = __importDefault(require("./routes/categories"));
const users_1 = __importDefault(require("./routes/users"));
const subscriptions_1 = __importDefault(require("./routes/subscriptions"));
const packs_1 = __importDefault(require("./routes/packs"));
const notifications_1 = __importDefault(require("./routes/notifications"));
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Middleware
const allowedOrigins = [
    process.env.CLIENT_URL || "",
    "http://softskyadmin.softsky.studio",
    "https://softskyadmin.softsky.studio",
].filter(Boolean);
// CORS configuration
const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (like mobile apps or curl requests)
        if (!origin)
            return callback(null, true);
        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        }
        else {
            console.log("Blocked by CORS:", origin);
            callback(null, true); // For now, allow all origins for debugging
        }
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: [
        "Content-Type",
        "Authorization",
        "Origin",
        "Accept",
        "X-Requested-With",
    ],
    optionsSuccessStatus: 200, // Some legacy browsers choke on 204
};
// Explicit CORS headers middleware (handles cases where reverse proxy interferes)
app.use((req, res, next) => {
    const origin = req.headers.origin;
    // Set CORS headers for all requests
    res.setHeader("Access-Control-Allow-Origin", origin || "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, Origin, Accept, X-Requested-With");
    res.setHeader("Access-Control-Allow-Credentials", "true");
    // Handle preflight requests immediately
    if (req.method === "OPTIONS") {
        res.status(200).end();
        return;
    }
    next();
});
app.use((0, cors_1.default)(corsOptions));
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
// Root endpoint - works without database for debugging
app.get("/", (req, res) => {
    res.json({
        status: "ok",
        message: "AWG Backend API Server is running",
        version: "1.0.0",
        timestamp: new Date().toISOString(),
        database: data_source_1.AppDataSource.isInitialized ? "connected" : "not connected",
    });
});
app.get("/api", (req, res) => {
    res.json({
        status: "ok",
        message: "AWG Backend API is available",
        database: data_source_1.AppDataSource.isInitialized ? "connected" : "not connected",
        endpoints: [
            "/api/health",
            "/api/auth",
            "/api/wallpapers",
            "/api/categories",
            "/api/users",
            "/api/subscriptions",
            "/api/packs",
            "/api/notifications",
        ],
    });
});
// API Routes
app.use("/api/auth", auth_1.default);
app.use("/api/wallpapers", wallpapers_1.default);
app.use("/api/categories", categories_1.default);
app.use("/api/users", users_1.default);
app.use("/api/subscriptions", subscriptions_1.default);
app.use("/api/packs", packs_1.default);
app.use("/api/notifications", notifications_1.default);
// Health check endpoint
app.get("/api/health", async (req, res) => {
    const dbConnected = data_source_1.AppDataSource.isInitialized;
    res.json({
        status: dbConnected ? "ok" : "error",
        message: dbConnected
            ? "AWG Backend API is running!"
            : "Database connection failed",
        database: {
            connected: dbConnected,
            host: process.env.MYSQL_HOST || "localhost",
            database: process.env.MYSQL_DATABASE || "awg_wallpaper",
        },
    });
});
// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: "Something went wrong!" });
});
// Start server immediately, then try to connect to database
const server = app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📡 API available at http://localhost:${PORT}/api`);
});
// Initialize database connection (non-blocking)
data_source_1.AppDataSource.initialize()
    .then(() => {
    console.log("✅ Connected to MySQL");
    console.log(`   Host: ${process.env.MYSQL_HOST || "localhost"}`);
    console.log(`   Database: ${process.env.MYSQL_DATABASE || "awg_wallpaper"}`);
})
    .catch((error) => {
    console.error("❌ MySQL connection error:", error.message);
    console.error("   The server will continue running but database operations will fail.");
    console.error("   Please check your MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, and MYSQL_DATABASE environment variables.");
});
exports.default = app;
//# sourceMappingURL=index.js.map