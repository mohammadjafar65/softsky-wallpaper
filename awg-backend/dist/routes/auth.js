"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const data_source_1 = require("../data-source");
const User_1 = require("../entities/User");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// Admin login
router.post("/admin/login", async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res
                .status(400)
                .json({ error: "Email and password are required" });
        }
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        // Find admin user with password
        const user = await userRepository
            .createQueryBuilder("user")
            .addSelect("user.password")
            .where("user.email = :email", { email })
            .andWhere("user.role = :role", { role: "admin" })
            .getOne();
        if (!user) {
            return res.status(401).json({ error: "Invalid credentials" });
        }
        // Verify password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ error: "Invalid credentials" });
        }
        // Generate token
        const token = (0, auth_1.generateToken)({
            id: user.id.toString(),
            email: user.email,
            role: user.role,
        });
        res.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                role: user.role,
            },
        });
    }
    catch (error) {
        console.error("Login error:", error);
        res.status(500).json({
            error: "Login failed",
            details: error.message || error,
        });
    }
});
// Verify Firebase token and sync user (for mobile app)
router.post("/firebase/verify", async (req, res) => {
    try {
        const { firebaseUid, email, displayName, photoUrl, authProvider } = req.body;
        if (!firebaseUid || !email) {
            return res
                .status(400)
                .json({ error: "Firebase UID and email are required" });
        }
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        // Find or create user
        let user = await userRepository.findOne({ where: { firebaseUid } });
        if (!user) {
            user = await userRepository.findOne({ where: { email } });
            if (user) {
                // Update existing user with Firebase UID
                user.firebaseUid = firebaseUid;
                user.authProvider = authProvider || "google";
                if (photoUrl)
                    user.photoUrl = photoUrl;
                await userRepository.save(user);
            }
            else {
                // Create new user
                user = userRepository.create({
                    firebaseUid,
                    email,
                    displayName: displayName || email.split("@")[0],
                    photoUrl,
                    authProvider: authProvider || "google",
                    role: "user",
                });
                await userRepository.save(user);
            }
        }
        // Generate token
        const token = (0, auth_1.generateToken)({
            id: user.id.toString(),
            email: user.email,
            role: user.role,
        });
        res.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                photoUrl: user.photoUrl,
                role: user.role,
                subscription: user.subscription,
            },
        });
    }
    catch (error) {
        console.error("Firebase verify error:", error);
        res.status(500).json({ error: "Verification failed" });
    }
});
// Get current user profile
router.get("/me", auth_1.authenticate, async (req, res) => {
    try {
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user?.id || "0") },
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        res.json({
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
            role: user.role,
            subscription: user.subscription,
            downloads: user.downloads,
            createdAt: user.createdAt,
        });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to get profile" });
    }
});
// Create initial admin (run once during setup)
router.post("/setup-admin", async (req, res) => {
    try {
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const existingAdmin = await userRepository.findOne({
            where: { role: "admin" },
        });
        if (existingAdmin) {
            return res.status(400).json({ error: "Admin already exists" });
        }
        const adminEmail = process.env.ADMIN_EMAIL || "admin@awgwallpaper.com";
        const adminPassword = process.env.ADMIN_PASSWORD || "admin123";
        const admin = userRepository.create({
            email: adminEmail,
            password: adminPassword,
            displayName: "Admin",
            authProvider: "admin",
            role: "admin",
        });
        await userRepository.save(admin);
        res.json({
            message: "Admin created successfully",
            email: admin.email,
        });
    }
    catch (error) {
        console.error("Setup admin error:", error);
        res.status(500).json({ error: "Failed to create admin" });
    }
});
// Reset admin password (for fixing login issues)
router.post("/reset-admin", async (req, res) => {
    try {
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const admin = await userRepository.findOne({
            where: { role: "admin" },
        });
        if (!admin) {
            return res.status(404).json({ error: "No admin user found" });
        }
        const newPassword = process.env.ADMIN_PASSWORD || "admin123";
        admin.password = newPassword;
        await userRepository.save(admin);
        res.json({
            message: "Admin password reset successfully",
            email: admin.email,
        });
    }
    catch (error) {
        console.error("Reset admin error:", error);
        res.status(500).json({ error: "Failed to reset admin password" });
    }
});
exports.default = router;
//# sourceMappingURL=auth.js.map