"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateToken = exports.optionalAuth = exports.requireAdmin = exports.authenticate = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret_key_here";
// Warn loudly if JWT secret is the insecure default
if (!process.env.JWT_SECRET || process.env.JWT_SECRET === "your_jwt_secret_key_here") {
    console.warn("⚠️  WARNING: JWT_SECRET is not set or is using the insecure default. Set a strong secret in your .env file!");
}
// Verify JWT token
const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res
                .status(401)
                .json({ error: "Access denied. No token provided." });
        }
        const token = authHeader.substring(7);
        const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    }
    catch (error) {
        res.status(401).json({ error: "Invalid or expired token." });
    }
};
exports.authenticate = authenticate;
// Check if user is admin
const requireAdmin = (req, res, next) => {
    if (!req.user || req.user.role !== "admin") {
        return res
            .status(403)
            .json({ error: "Access denied. Admin privileges required." });
    }
    next();
};
exports.requireAdmin = requireAdmin;
// Optional authentication (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith("Bearer ")) {
            const token = authHeader.substring(7);
            const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
            req.user = decoded;
        }
        next();
    }
    catch (error) {
        // Continue without user if token is invalid
        next();
    }
};
exports.optionalAuth = optionalAuth;
// Generate JWT token
const generateToken = (user) => {
    return jsonwebtoken_1.default.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, {
        expiresIn: "30d",
    });
};
exports.generateToken = generateToken;
//# sourceMappingURL=auth.js.map