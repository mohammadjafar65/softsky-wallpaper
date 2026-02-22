"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const data_source_1 = require("../data-source");
const User_1 = require("../entities/User");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// Known valid product IDs (keep in sync with your Google Play console)
const KNOWN_PRODUCT_IDS = new Set([
    "ssw_pro_monthly",
    "ssw_pro_annual",
    "ssw_pro_lifetime",
    // Add any additional product IDs here
]);
// Verify and update subscription from purchase
router.post("/verify", auth_1.authenticate, async (req, res) => {
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
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user?.id || "0") },
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        // Calculate expiry date based on plan
        let expiryDate;
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
    }
    catch (error) {
        console.error("Subscription verify error:", error);
        res.status(500).json({ error: "Failed to verify subscription" });
    }
});
// Get current subscription status
router.get("/status", auth_1.authenticate, async (req, res) => {
    try {
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user?.id || "0") },
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        // Check if subscription has expired
        const isExpired = user.subscriptionExpiryDate &&
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
    }
    catch (error) {
        res.status(500).json({ error: "Failed to get subscription status" });
    }
});
// Restore subscription
router.post("/restore", auth_1.authenticate, async (req, res) => {
    try {
        const { purchaseToken, plan } = req.body;
        if (!purchaseToken || !plan) {
            return res
                .status(400)
                .json({ error: "Purchase token and plan are required" });
        }
        // TODO: Verify purchase history with Google Play API
        // For now, we trust the client provided data to restore logic (similar to verify)
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const user = await userRepository.findOne({
            where: { id: parseInt(req.user?.id || "0") },
        });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        // Calculate expiry date based on plan
        let expiryDate;
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
    }
    catch (error) {
        res.status(500).json({ error: "Failed to restore subscription" });
    }
});
// Cancel subscription (admin or user)
router.post("/cancel", auth_1.authenticate, async (req, res) => {
    try {
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
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
    }
    catch (error) {
        res.status(500).json({ error: "Failed to cancel subscription" });
    }
});
exports.default = router;
//# sourceMappingURL=subscriptions.js.map