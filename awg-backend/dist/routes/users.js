"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const User_1 = __importDefault(require("../models/User"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// Get all users (admin only)
router.get('/', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const search = req.query.search;
        const plan = req.query.plan;
        const query = { role: 'user' };
        if (search) {
            query.$or = [
                { email: { $regex: search, $options: 'i' } },
                { displayName: { $regex: search, $options: 'i' } },
            ];
        }
        if (plan && plan !== 'all') {
            query['subscription.plan'] = plan;
        }
        const total = await User_1.default.countDocuments(query);
        const users = await User_1.default.find(query)
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(limit);
        res.json({
            users: users.map(u => ({
                id: u._id,
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
        res.status(500).json({ error: 'Failed to get users' });
    }
});
// Get single user (admin only)
router.get('/:id', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const user = await User_1.default.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json({
            id: user._id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
            authProvider: user.authProvider,
            role: user.role,
            subscription: user.subscription,
            favorites: user.favorites,
            downloads: user.downloads,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to get user' });
    }
});
// Update user (admin only)
router.put('/:id', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { displayName, isActive, subscription } = req.body;
        const user = await User_1.default.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        if (displayName)
            user.displayName = displayName;
        if (isActive !== undefined)
            user.isActive = isActive === true || isActive === 'true';
        if (subscription) {
            if (subscription.plan)
                user.subscription.plan = subscription.plan;
            if (subscription.expiryDate)
                user.subscription.expiryDate = new Date(subscription.expiryDate);
        }
        await user.save();
        res.json({
            message: 'User updated successfully',
            user: {
                id: user._id,
                email: user.email,
                displayName: user.displayName,
                subscription: user.subscription,
                isActive: user.isActive,
            },
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to update user' });
    }
});
// Delete user (admin only)
router.delete('/:id', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const user = await User_1.default.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        if (user.role === 'admin') {
            return res.status(400).json({ error: 'Cannot delete admin user' });
        }
        await User_1.default.findByIdAndDelete(req.params.id);
        res.json({ message: 'User deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to delete user' });
    }
});
// Get user stats (admin only)
router.get('/stats/overview', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const totalUsers = await User_1.default.countDocuments({ role: 'user' });
        const proUsers = await User_1.default.countDocuments({
            role: 'user',
            'subscription.plan': { $ne: 'free' }
        });
        const newUsersThisMonth = await User_1.default.countDocuments({
            role: 'user',
            createdAt: { $gte: new Date(new Date().setDate(1)) }
        });
        const subscriptionStats = await User_1.default.aggregate([
            { $match: { role: 'user' } },
            { $group: { _id: '$subscription.plan', count: { $sum: 1 } } }
        ]);
        res.json({
            totalUsers,
            proUsers,
            freeUsers: totalUsers - proUsers,
            newUsersThisMonth,
            subscriptionBreakdown: subscriptionStats.reduce((acc, curr) => {
                acc[curr._id] = curr.count;
                return acc;
            }, {}),
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to get user stats' });
    }
});
exports.default = router;
//# sourceMappingURL=users.js.map