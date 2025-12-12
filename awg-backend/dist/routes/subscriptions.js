"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const User_1 = __importDefault(require("../models/User"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// Verify and update subscription from purchase
router.post('/verify', auth_1.authenticate, async (req, res) => {
    try {
        const { purchaseToken, plan, productId } = req.body;
        if (!purchaseToken || !plan) {
            return res.status(400).json({ error: 'Purchase token and plan are required' });
        }
        // TODO: Verify purchase with Google Play API
        // For now, we'll trust the client and update the subscription
        // In production, you should verify the purchase token with Google Play Developer API
        const user = await User_1.default.findById(req.user?.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        // Calculate expiry date based on plan
        let expiryDate;
        switch (plan) {
            case 'weekly':
                expiryDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
                break;
            case 'monthly':
                expiryDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
                break;
            case 'yearly':
                expiryDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
                break;
            case 'lifetime':
                expiryDate = new Date('2100-01-01');
                break;
            default:
                return res.status(400).json({ error: 'Invalid plan' });
        }
        user.subscription = {
            plan,
            expiryDate,
            purchaseToken,
        };
        await user.save();
        res.json({
            message: 'Subscription verified successfully',
            subscription: user.subscription,
        });
    }
    catch (error) {
        console.error('Subscription verify error:', error);
        res.status(500).json({ error: 'Failed to verify subscription' });
    }
});
// Get current subscription status
router.get('/status', auth_1.authenticate, async (req, res) => {
    try {
        const user = await User_1.default.findById(req.user?.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        // Check if subscription has expired
        const isExpired = user.subscription.expiryDate &&
            user.subscription.expiryDate < new Date() &&
            user.subscription.plan !== 'lifetime';
        if (isExpired) {
            user.subscription.plan = 'free';
            user.subscription.expiryDate = undefined;
            user.subscription.purchaseToken = undefined;
            await user.save();
        }
        const isPro = user.subscription.plan !== 'free' && !isExpired;
        res.json({
            plan: user.subscription.plan,
            expiryDate: user.subscription.expiryDate,
            isPro,
            isExpired,
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to get subscription status' });
    }
});
// Restore subscription
router.post('/restore', auth_1.authenticate, async (req, res) => {
    try {
        const { purchaseToken, plan } = req.body;
        // TODO: Verify purchase history with Google Play API
        // For now, just return current subscription status
        const user = await User_1.default.findById(req.user?.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json({
            message: 'Subscription restored',
            subscription: user.subscription,
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to restore subscription' });
    }
});
// Cancel subscription (admin or user)
router.post('/cancel', auth_1.authenticate, async (req, res) => {
    try {
        const user = await User_1.default.findById(req.user?.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        // Don't immediately remove subscription, it will expire naturally
        // Just mark it as not renewing
        res.json({
            message: 'Subscription will not renew',
            expiryDate: user.subscription.expiryDate,
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to cancel subscription' });
    }
});
exports.default = router;
//# sourceMappingURL=subscriptions.js.map