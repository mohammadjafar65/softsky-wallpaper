"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const data_source_1 = require("../data-source");
const User_1 = require("../entities/User");
const Wallpaper_1 = require("../entities/Wallpaper");
const auth_1 = require("../middleware/auth");
const typeorm_1 = require("typeorm");
const router = (0, express_1.Router)();
// Get all users (admin only)
router.get("/", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const search = req.query.search;
        const plan = req.query.plan;
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const queryBuilder = userRepository
            .createQueryBuilder("user")
            .where("user.role = :role", { role: "user" });
        if (search) {
            queryBuilder.andWhere("(user.email LIKE :search OR user.displayName LIKE :search)", { search: `%${search}%` });
        }
        if (plan && plan !== "all") {
            queryBuilder.andWhere("user.subscriptionPlan = :plan", { plan });
        }
        const total = await queryBuilder.getCount();
        const users = await queryBuilder
            .orderBy("user.createdAt", "DESC")
            .skip((page - 1) * limit)
            .take(limit)
            .getMany();
        res.json({
            users: users.map((u) => ({
                id: u.id,
                email: u.email,
                displayName: u.displayName,
                photoUrl: u.photoUrl,
                authProvider: u.authProvider,
                subscription: u.subscription,
                downloads: u.downloads,
                isActive: u.isActive,
                createdAt: u.createdAt,
            })),
            pagination: {
                page,
                limit,
                total,
                pages: Math.ceil(total / limit),
            },
        });
    }
    catch (error) {
        console.error("Get users error:", error);
        res.status(500).json({ error: "Failed to get users" });
    }
});
// Get single user (admin only)
router.get("/:id", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        res.json({
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
            authProvider: user.authProvider,
            role: user.role,
            subscription: user.subscription,
            favorites: [], // TODO: Implement favorites relation
            downloads: user.downloads,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
        });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to get user" });
    }
});
// Update user (admin only)
router.put("/:id", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { displayName, isActive, subscription } = req.body;
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        if (displayName)
            user.displayName = displayName;
        if (isActive !== undefined)
            user.isActive = isActive === true || isActive === "true";
        if (subscription) {
            if (subscription.plan)
                user.subscriptionPlan = subscription.plan;
            if (subscription.expiryDate)
                user.subscriptionExpiryDate = new Date(subscription.expiryDate);
        }
        await userRepository.save(user);
        res.json({
            message: "User updated successfully",
            user: {
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                subscription: user.subscription,
                isActive: user.isActive,
            },
        });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to update user" });
    }
});
// Delete user (admin only)
router.delete("/:id", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        if (user.role === "admin") {
            return res.status(400).json({ error: "Cannot delete admin user" });
        }
        await userRepository.delete(req.params.id);
        res.json({ message: "User deleted successfully" });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to delete user" });
    }
});
// Get user stats (admin only)
router.get("/stats/overview", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const wallpaperRepository = data_source_1.AppDataSource.getRepository(Wallpaper_1.Wallpaper);
        // Total users
        const totalUsers = await userRepository.count({ where: { role: "user" } });
        // Active pro users (not expired)
        const now = new Date();
        const proUsers = await userRepository
            .createQueryBuilder("user")
            .where("user.role = :role", { role: "user" })
            .andWhere("user.subscriptionPlan != :free", { free: "free" })
            .andWhere("(user.subscriptionPlan = :lifetime OR user.subscriptionExpiryDate > :now)", { lifetime: "lifetime", now })
            .getCount();
        // Total wallpaper downloads
        const wallpaperStats = await wallpaperRepository
            .createQueryBuilder("wallpaper")
            .select("SUM(wallpaper.downloads)", "totalDownloads")
            .getRawOne();
        const totalWallpaperDownloads = parseInt(wallpaperStats?.totalDownloads || "0");
        // New users this month
        const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const newUsersThisMonth = await userRepository.count({
            where: {
                role: "user",
                createdAt: (0, typeorm_1.MoreThan)(firstDayOfMonth),
            },
        });
        // Subscription breakdown with proper expiry handling
        const subscriptionStats = await userRepository
            .createQueryBuilder("user")
            .select(`CASE 
                    WHEN user.subscription_plan = 'free' THEN 'free'
                    WHEN user.subscription_plan = 'lifetime' THEN 'lifetime'
                    WHEN user.subscription_expiry_date > :now THEN user.subscription_plan
                    ELSE 'free'
                END`, "plan")
            .addSelect("COUNT(*)", "count")
            .where("user.role = :role", { role: "user" })
            .setParameter("now", now)
            .groupBy("plan")
            .getRawMany();
        res.json({
            totalUsers,
            proUsers,
            totalWallpaperDownloads,
            freeUsers: totalUsers - proUsers,
            newUsersThisMonth,
            subscriptionBreakdown: subscriptionStats.reduce((acc, curr) => {
                acc[curr.plan] = parseInt(curr.count);
                return acc;
            }, {}),
        });
    }
    catch (error) {
        console.error("Get user stats error:", error);
        res.status(500).json({ error: "Failed to get user stats" });
    }
});
// Update FCM token for current user
router.post("/fcm-token", auth_1.authenticate, async (req, res) => {
    try {
        const { fcmToken } = req.body;
        if (!fcmToken) {
            return res.status(400).json({ error: "FCM token is required" });
        }
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user.id) },
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        user.fcmToken = fcmToken;
        await userRepository.save(user);
        res.json({
            success: true,
            message: "FCM token updated successfully",
        });
    }
    catch (error) {
        console.error("Error updating FCM token:", error);
        res.status(500).json({ error: "Failed to update FCM token" });
    }
});
exports.default = router;
//# sourceMappingURL=users.js.map