import { Router } from 'express';
import User from '../models/User';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = Router();

// Verify and update subscription from purchase
router.post('/verify', authenticate, async (req: AuthRequest, res) => {
    try {
        const { purchaseToken, plan, productId } = req.body;

        if (!purchaseToken || !plan) {
            return res.status(400).json({ error: 'Purchase token and plan are required' });
        }

        // TODO: Verify purchase with Google Play API
        // For now, we'll trust the client and update the subscription
        // In production, you should verify the purchase token with Google Play Developer API

        const user = await User.findById(req.user?.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Calculate expiry date based on plan
        let expiryDate: Date;
        switch (plan) {
            case 'monthly':
                expiryDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
                break;
            case 'annual':
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
    } catch (error) {
        console.error('Subscription verify error:', error);
        res.status(500).json({ error: 'Failed to verify subscription' });
    }
});

// Get current subscription status
router.get('/status', authenticate, async (req: AuthRequest, res) => {
    try {
        const user = await User.findById(req.user?.id);

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
    } catch (error) {
        res.status(500).json({ error: 'Failed to get subscription status' });
    }
});

// Restore subscription
router.post('/restore', authenticate, async (req: AuthRequest, res) => {
    try {
        const { purchaseToken, plan } = req.body;

        if (!purchaseToken || !plan) {
            return res.status(400).json({ error: 'Purchase token and plan are required' });
        }

        // TODO: Verify purchase history with Google Play API
        // For now, we trust the client provided data to restore logic (similar to verify)

        const user = await User.findById(req.user?.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Calculate expiry date based on plan
        let expiryDate: Date;
        switch (plan) {
            case 'monthly':
                expiryDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
                break;
            case 'annual':
                expiryDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
                break;
            case 'lifetime':
                expiryDate = new Date('2100-01-01');
                break;
            default:
                return res.status(400).json({ error: 'Invalid plan' });
        }

        // Update user subscription
        user.subscription = {
            plan,
            expiryDate,
            purchaseToken,
        };

        await user.save();

        res.json({
            message: 'Subscription restored successfully',
            subscription: user.subscription,
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to restore subscription' });
    }
});

// Cancel subscription (admin or user)
router.post('/cancel', authenticate, async (req: AuthRequest, res) => {
    try {
        const user = await User.findById(req.user?.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Don't immediately remove subscription, it will expire naturally
        // Just mark it as not renewing

        res.json({
            message: 'Subscription will not renew',
            expiryDate: user.subscription.expiryDate,
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to cancel subscription' });
    }
});

export default router;
