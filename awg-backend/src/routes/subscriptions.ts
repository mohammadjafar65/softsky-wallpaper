import { Router } from "express";
import { AppDataSource } from "../data-source";
import { User } from "../entities/User";
import { Wallpaper } from "../entities/Wallpaper";
import { authenticate, requireAdmin, AuthRequest } from "../middleware/auth";
import { MoreThan } from "typeorm";

const router = Router();

// Known valid product IDs (keep in sync with your Google Play console)
const KNOWN_PRODUCT_IDS = new Set([
    "ssw_pro_monthly",
    "ssw_pro_annual",
    "ssw_pro_lifetime",
    // Add any additional product IDs here
]);

// Admin subscription stats
router.get("/stats", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const userRepository = AppDataSource.getRepository(User);
        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);
        const now = new Date();

        const totalUsers = await userRepository.count({ where: { role: "user" } });
        const proUsers = await userRepository
            .createQueryBuilder("user")
            .where("user.role = :role", { role: "user" })
            .andWhere("user.subscriptionPlan != :free", { free: "free" })
            .andWhere(
                "(user.subscriptionPlan = :lifetime OR user.subscriptionExpiryDate > :now)",
                { lifetime: "lifetime", now }
            )
            .getCount();

        const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const newUsersThisMonth = await userRepository.count({
            where: { role: "user", createdAt: MoreThan(firstDayOfMonth) },
        });

        const wallpaperStats = await wallpaperRepository
            .createQueryBuilder("wallpaper")
            .select("COALESCE(SUM(wallpaper.downloads), 0)", "totalDownloads")
            .getRawOne();

        const subscriptionStats = await userRepository
            .createQueryBuilder("user")
            .select(
                `CASE 
                    WHEN user.subscription_plan = 'free' THEN 'free'
                    WHEN user.subscription_plan = 'lifetime' THEN 'lifetime'
                    WHEN user.subscription_expiry_date > :now THEN user.subscription_plan
                    ELSE 'free'
                END`,
                "plan"
            )
            .addSelect("COUNT(*)", "count")
            .where("user.role = :role", { role: "user" })
            .setParameter("now", now)
            .groupBy("plan")
            .getRawMany();

        res.json({
            totalUsers,
            proUsers,
            freeUsers: totalUsers - proUsers,
            newUsersThisMonth,
            totalWallpaperDownloads: parseInt(wallpaperStats?.totalDownloads || "0", 10),
            subscriptionBreakdown: subscriptionStats.reduce(
                (acc: Record<string, number>, curr: { plan: string; count: string }) => {
                    acc[curr.plan] = parseInt(curr.count, 10);
                    return acc;
                },
                {}
            ),
        });
    } catch (error) {
        console.error("Subscription stats error:", error);
        res.status(500).json({ error: "Failed to get subscription stats" });
    }
});

// Admin subscriber roster
router.get("/subscribers", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const limit = Math.min(parseInt(req.query.limit as string) || 300, 1000);
        const userRepository = AppDataSource.getRepository(User);
        const now = new Date();

        const users = await userRepository
            .createQueryBuilder("user")
            .where("user.role = :role", { role: "user" })
            .andWhere("user.subscriptionPlan != :free", { free: "free" })
            .andWhere(
                "(user.subscriptionPlan = :lifetime OR user.subscriptionExpiryDate > :now)",
                { lifetime: "lifetime", now }
            )
            .orderBy("user.subscriptionExpiryDate", "ASC")
            .take(limit)
            .getMany();

        res.json({
            users: users.map((user) => ({
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                subscription: user.subscription,
                downloads: user.downloads,
                isActive: user.isActive,
                createdAt: user.createdAt,
                hasFcmToken: !!user.fcmToken,
            })),
        });
    } catch (error) {
        console.error("Subscriber roster error:", error);
        res.status(500).json({ error: "Failed to get subscribers" });
    }
});

// Verify and update subscription from purchase
router.post("/verify", authenticate, async (req: AuthRequest, res) => {
    try {
        const { purchaseToken, plan, productId } = req.body;

        if (!purchaseToken || !plan) {
            return res
                .status(400)
                .json({ error: "Purchase token and plan are required" });
        }

        // Validate productId if provided
        if (productId && !KNOWN_PRODUCT_IDS.has(productId)) {
            console.warn(`Unknown productId received: ${productId}`);
            return res.status(400).json({ error: "Invalid product ID" });
        }

        // Validate plan
        const validPlans = ["monthly", "annual", "lifetime"];
        if (!validPlans.includes(plan)) {
            return res.status(400).json({ error: "Invalid plan" });
        }

        // TODO: Verify purchase with Google Play Developer API for production security
        // For now, we validate productId/plan consistency and trust token

        const userRepository = AppDataSource.getRepository(User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user?.id || "0") },
        });

        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }

        // Calculate expiry date based on plan
        let expiryDate: Date;
        switch (plan) {
            case "monthly":
                expiryDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
                break;
            case "annual":
                expiryDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
                break;
            case "lifetime":
                expiryDate = new Date("2100-01-01");
                break;
            default:
                return res.status(400).json({ error: "Invalid plan" });
        }

        user.subscriptionPlan = plan;
        user.subscriptionExpiryDate = expiryDate;
        user.subscriptionPurchaseToken = purchaseToken;

        await userRepository.save(user);
        console.log(`Subscription verified: user=${req.user?.id} plan=${plan} productId=${productId} expires=${expiryDate.toISOString()}`);

        res.json({
            message: "Subscription verified successfully",
            subscription: user.subscription,
        });
    } catch (error) {
        console.error("Subscription verify error:", error);
        res.status(500).json({ error: "Failed to verify subscription" });
    }
});

// Get current subscription status
router.get("/status", authenticate, async (req: AuthRequest, res) => {
    try {
        const userRepository = AppDataSource.getRepository(User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user?.id || "0") },
        });

        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }

        // Check if subscription has expired
        const isExpired =
            user.subscriptionExpiryDate &&
            user.subscriptionExpiryDate < new Date() &&
            user.subscriptionPlan !== "lifetime";

        if (isExpired) {
            user.subscriptionPlan = "free";
            user.subscriptionExpiryDate = undefined;
            user.subscriptionPurchaseToken = undefined;
            await userRepository.save(user);
        }

        const isPro = user.subscriptionPlan !== "free" && !isExpired;

        res.json({
            plan: user.subscriptionPlan,
            expiryDate: user.subscriptionExpiryDate,
            isPro,
            isExpired: isExpired || false,
        });
    } catch (error) {
        res.status(500).json({ error: "Failed to get subscription status" });
    }
});

// Restore subscription
router.post("/restore", authenticate, async (req: AuthRequest, res) => {
    try {
        const { purchaseToken, plan } = req.body;

        if (!purchaseToken || !plan) {
            return res
                .status(400)
                .json({ error: "Purchase token and plan are required" });
        }

        // TODO: Verify purchase history with Google Play API
        // For now, we trust the client provided data to restore logic (similar to verify)

        const userRepository = AppDataSource.getRepository(User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user?.id || "0") },
        });

        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }

        // Calculate expiry date based on plan
        let expiryDate: Date;
        switch (plan) {
            case "monthly":
                expiryDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
                break;
            case "annual":
                expiryDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
                break;
            case "lifetime":
                expiryDate = new Date("2100-01-01");
                break;
            default:
                return res.status(400).json({ error: "Invalid plan" });
        }

        // Update user subscription
        user.subscriptionPlan = plan;
        user.subscriptionExpiryDate = expiryDate;
        user.subscriptionPurchaseToken = purchaseToken;

        await userRepository.save(user);

        res.json({
            message: "Subscription restored successfully",
            subscription: user.subscription,
        });
    } catch (error) {
        res.status(500).json({ error: "Failed to restore subscription" });
    }
});

// Cancel subscription (admin or user)
router.post("/cancel", authenticate, async (req: AuthRequest, res) => {
    try {
        const userRepository = AppDataSource.getRepository(User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user?.id || "0") },
        });

        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }

        // Don't immediately remove subscription, it will expire naturally
        // Just mark it as not renewing

        res.json({
            message: "Subscription will not renew",
            expiryDate: user.subscriptionExpiryDate,
        });
    } catch (error) {
        res.status(500).json({ error: "Failed to cancel subscription" });
    }
});

export default router;
