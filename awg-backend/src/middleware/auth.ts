import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

export interface AuthRequest extends Request {
    user?: {
        id: string;
        email: string;
        role: string;
    };
}

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret_key_here";

// Warn loudly if JWT secret is the insecure default
if (!process.env.JWT_SECRET || process.env.JWT_SECRET === "your_jwt_secret_key_here") {
    console.warn("⚠️  WARNING: JWT_SECRET is not set or is using the insecure default. Set a strong secret in your .env file!");
}

// Verify JWT token
export const authenticate = async (
    req: AuthRequest,
    res: Response,
    next: NextFunction
) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res
                .status(401)
                .json({ error: "Access denied. No token provided." });
        }

        const token = authHeader.substring(7);
        const decoded = jwt.verify(token, JWT_SECRET) as {
            id: string;
            email: string;
            role: string;
        };

        req.user = decoded;
        next();
    } catch (error) {
        res.status(401).json({ error: "Invalid or expired token." });
    }
};

// Check if user is admin
export const requireAdmin = (
    req: AuthRequest,
    res: Response,
    next: NextFunction
) => {
    if (!req.user || req.user.role !== "admin") {
        return res
            .status(403)
            .json({ error: "Access denied. Admin privileges required." });
    }
    next();
};

// Optional authentication (doesn't fail if no token)
export const optionalAuth = async (
    req: AuthRequest,
    res: Response,
    next: NextFunction
) => {
    try {
        const authHeader = req.headers.authorization;

        if (authHeader && authHeader.startsWith("Bearer ")) {
            const token = authHeader.substring(7);
            const decoded = jwt.verify(token, JWT_SECRET) as {
                id: string;
                email: string;
                role: string;
            };
            req.user = decoded;
        }

        next();
    } catch (error) {
        // Continue without user if token is invalid
        next();
    }
};

// Generate JWT token
export const generateToken = (user: {
    id: string;
    email: string;
    role: string;
}): string => {
    return jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, {
        expiresIn: "30d",
    });
};
