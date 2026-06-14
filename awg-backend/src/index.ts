import "reflect-metadata";
import dotenv from "dotenv";
// Load environment variables immediately
dotenv.config();

import express from "express";
import multer from "multer";
import cors from "cors";
import compression from "compression";
import rateLimit from "express-rate-limit";
import { AppDataSource } from "./data-source";

// Import routes
import authRoutes from "./routes/auth";
import wallpaperRoutes from "./routes/wallpapers";
import categoryRoutes from "./routes/categories";
import userRoutes from "./routes/users";
import subscriptionRoutes from "./routes/subscriptions";
import packRoutes from "./routes/packs";
import notificationRoutes from "./routes/notifications";
import settingRoutes from "./routes/settings";

const app = express();
const PORT = process.env.PORT || 3000;

// Store database connection error for debugging
let dbConnectionError: string | null = null;

// ----------– CORS ------------------------------------------
const allowedOrigins = [
    process.env.CLIENT_URL || "",
    "http://softskyadmin.softsky.studio",
    "https://softskyadmin.softsky.studio",
].filter(Boolean);

const corsOptions = {
    origin: function (
        origin: string | undefined,
        callback: (err: Error | null, allow?: boolean) => void
    ) {
        // Allow requests with no origin (mobile apps, curl, etc.)
        if (!origin) return callback(null, true);
        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            console.log("Blocked by CORS:", origin);
            callback(null, true); // Permissive for now; tighten in prod
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
        "X-Setup-Secret",
    ],
    optionsSuccessStatus: 200,
};

// Explicit CORS headers middleware (handles reverse-proxy interference)
app.use((req, res, next) => {
    const origin = req.headers.origin;
    res.setHeader("Access-Control-Allow-Origin", origin || "*");
    res.setHeader(
        "Access-Control-Allow-Methods",
        "GET, POST, PUT, DELETE, PATCH, OPTIONS"
    );
    res.setHeader(
        "Access-Control-Allow-Headers",
        "Content-Type, Authorization, Origin, Accept, X-Requested-With, X-Setup-Secret"
    );
    res.setHeader("Access-Control-Allow-Credentials", "true");

    if (req.method === "OPTIONS") {
        res.status(200).end();
        return;
    }
    next();
});

app.use(cors(corsOptions));

// ----------– Response Compression --------------------------
app.use(compression());

// ----------– Body Limits ------------------------------------
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// ----------– Rate Limiting ----------------------------------
// Auth routes rate limiter: max 15 requests per 15 min per IP
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 15,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: "Too many login attempts. Please try again in 15 minutes.",
    },
    skip: (req) => !AppDataSource.isInitialized, // don't rate-limit if DB not ready
});

// General API limiter: 300 req per minute per IP
const apiLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 300,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: "Too many requests. Please slow down." },
    skip: (req) => !AppDataSource.isInitialized,
});

app.use("/api/", apiLimiter);

// ----------– Root / Health Endpoints -----------------------
app.get("/", (req, res) => {
    res.json({
        status: "ok",
        message: "AWG Backend API Server is running",
        version: "1.0.0",
        timestamp: new Date().toISOString(),
        database: AppDataSource.isInitialized ? "connected" : "not connected",
    });
});

app.get("/api", (req, res) => {
    res.json({
        status: "ok",
        message: "AWG Backend API is available",
        database: AppDataSource.isInitialized ? "connected" : "not connected",
        endpoints: [
            "/api/health",
            "/api/auth",
            "/api/wallpapers",
            "/api/categories",
            "/api/users",
            "/api/subscriptions",
            "/api/packs",
            "/api/notifications",
            "/api/settings",
        ],
    });
});

// ----------– API Routes ------------------------------------
// Apply stricter rate limiting to auth endpoints
app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/wallpapers", wallpaperRoutes);
app.use("/api/categories", categoryRoutes);
app.use("/api/users", userRoutes);
app.use("/api/subscriptions", subscriptionRoutes);
app.use("/api/packs", packRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/settings", settingRoutes);

// Health check endpoint
app.get("/api/health", async (req, res) => {
    const dbConnected = AppDataSource.isInitialized;
    res.json({
        status: dbConnected ? "ok" : "error",
        message: dbConnected
            ? "AWG Backend API is running!"
            : "Database connection failed",
        database: {
            connected: dbConnected,
            host: process.env.MYSQL_HOST || "localhost",
            database: process.env.MYSQL_DATABASE || "softoatk_ssw_wallpaper",
            error: dbConnectionError,
        },
    });
});

// ----------– 404 Handler ------------------------------------
app.use((req, res) => {
    res.status(404).json({
        error: "Not Found",
        message: `Route ${req.method} ${req.path} does not exist`,
    });
});

// ----------– Error Handler ----------------------------------
app.use(
    (
        err: Error & { status?: number },
        req: express.Request,
        res: express.Response,
        next: express.NextFunction
    ) => {
        let status = err.status || 500;
        let message = err.message;

        if (err instanceof multer.MulterError) {
            status = err.code === "LIMIT_FILE_SIZE" ? 413 : 400;
            message =
                err.code === "LIMIT_FILE_SIZE"
                    ? "Image is too large. Upload an image smaller than 25MB."
                    : err.message;
        } else if (message === "Only image files are allowed!") {
            status = 400;
        }

        console.error(`[${new Date().toISOString()}] ${status} ${req.method} ${req.path} -`, err.message);
        if (process.env.NODE_ENV !== "production") {
            console.error(err.stack);
        }
        res.status(status).json({
            error: status === 500 ? "Internal server error" : message,
            details: process.env.NODE_ENV === "production" ? undefined : err.message,
        });
    }
);

// ----------– Start Server -----------------------------------
const server = app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📡 API available at http://localhost:${PORT}/api`);
    console.log(`🛡️  Rate limiting: auth=15/15min, api=300/min`);
    console.log(`📦 Response compression: enabled`);
});

// Initialize database connection (non-blocking)
AppDataSource.initialize()
    .then(() => {
        console.log("✅ Connected to MySQL");
        console.log(`   Host: ${process.env.MYSQL_HOST || "localhost"}`);
        console.log(`   Database: ${process.env.MYSQL_DATABASE || "softoatk_ssw_wallpaper"}`);
    })
    .catch((error) => {
        dbConnectionError = error.message;
        console.error("❌ MySQL connection error:", error.message);
        console.error("   The server will continue running but database operations will fail.");
        console.error("   Please check your MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, and MYSQL_DATABASE environment variables.");
    });

export default app;
