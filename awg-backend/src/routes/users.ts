import { Router } from 'express';
import User from '../models/User';
import Wallpaper from '../models/Wallpaper';
import { authenticate, requireAdmin, AuthRequest } from '../middleware/auth';

const router = Router();

// Get all users (admin only)
router.get('/', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;
        const search = req.query.search as string;
        const plan = req.query.plan as string;

        const query: any = { role: 'user' };

        if (search) {
            query.$or = [
                { email: { $regex: search, $options: 'i' } },
                { displayName: { $regex: search, $options: 'i' } },
            ];
        }

        if (plan && plan !== 'all') {
            query['subscription.plan'] = plan;
        }

        const total = await User.countDocuments(query);
        const users = await User.find(query)
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
    } catch (error) {
        res.status(500).json({ error: 'Failed to get users' });
    }
});

// Get single user (admin only)
router.get('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const user = await User.findById(req.params.id);

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
    } catch (error) {
        res.status(500).json({ error: 'Failed to get user' });
    }
});

// Update user (admin only)
router.put('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { displayName, isActive, subscription } = req.body;

        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        if (displayName) user.displayName = displayName;
        if (isActive !== undefined) user.isActive = isActive === true || isActive === 'true';
        if (subscription) {
            if (subscription.plan) user.subscription.plan = subscription.plan;
            if (subscription.expiryDate) user.subscription.expiryDate = new Date(subscription.expiryDate);
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
    } catch (error) {
        res.status(500).json({ error: 'Failed to update user' });
    }
});

// Delete user (admin only)
router.delete('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        if (user.role === 'admin') {
            return res.status(400).json({ error: 'Cannot delete admin user' });
        }

        await User.findByIdAndDelete(req.params.id);

        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete user' });
    }
});

// Get user stats (admin only)
router.get('/stats/overview', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const totalUsers = await User.countDocuments({ role: 'user' });

        // Count active pro users (not expired)
        const activeProQuery = {
            role: 'user',
            'subscription.plan': { $ne: 'free' },
            $or: [
                { 'subscription.plan': 'lifetime' },
                { 'subscription.expiryDate': { $gt: new Date() } }
            ]
        };

        const proUsers = await User.countDocuments(activeProQuery);

        // Get total wallpaper downloads
        const wallpaperStats = await Wallpaper.aggregate([
            { $group: { _id: null, totalDownloads: { $sum: '$downloads' } } }
        ]);
        const totalWallpaperDownloads = wallpaperStats[0]?.totalDownloads || 0;

        // Get new users this month
        const newUsersThisMonth = await User.countDocuments({
            role: 'user',
            createdAt: { $gte: new Date(new Date().setDate(1)) }
        });

        // Subscription breakdown
        const subscriptionStats = await User.aggregate([
            { $match: { role: 'user' } },
            {
                $project: {
                    plan: {
                        $cond: {
                            if: {
                                $or: [
                                    { $eq: ['$subscription.plan', 'free'] },
                                    { $eq: ['$subscription.plan', 'lifetime'] },
                                    { $gt: ['$subscription.expiryDate', new Date()] }
                                ]
                            },
                            then: '$subscription.plan',
                            else: 'free' // Treat expired as free for stats
                        }
                    }
                }
            },
            { $group: { _id: '$plan', count: { $sum: 1 } } }
        ]);

        res.json({
            totalUsers,
            proUsers,
            totalWallpaperDownloads,
            freeUsers: totalUsers - proUsers,
            newUsersThisMonth,
            subscriptionBreakdown: subscriptionStats.reduce((acc, curr) => {
                acc[curr._id] = curr.count;
                return acc;
            }, {} as Record<string, number>),
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get user stats' });
    }
});

export default router;
