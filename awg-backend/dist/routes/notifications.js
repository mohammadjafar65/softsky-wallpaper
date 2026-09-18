"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const upload_1 = require("../middleware/upload");
const data_source_1 = require("../data-source");
const NotificationTemplate_1 = require("../entities/NotificationTemplate");
const fcm_1 = __importDefault(require("../services/fcm"));
const router = (0, express_1.Router)();
const DEFAULT_PREMADE_TEMPLATES = [
    {
        name: "Fresh Wallpaper Drop ✨",
        title: "Fresh Wallpapers Just Added! ✨",
        message: "Explore our latest collection of stunning 4K & UHD wallpapers curated just for your home screen.",
        category: "drop",
        isPremade: true,
    },
    {
        name: "Trending Now 🔥",
        title: "Trending Right Now 🔥",
        message: "Check out the most popular aesthetic wallpapers the community is downloading today!",
        category: "trending",
        isPremade: true,
    },
    {
        name: "Weekend Pro Special 💎",
        title: "Exclusive Pro Designs Unlocked 💎",
        message: "Upgrade your screen setup with exclusive handcrafted AMOLED & Minimal designs.",
        category: "promo",
        isPremade: true,
    },
    {
        name: "Pure Dark / AMOLED 🖤",
        title: "Pitch Black AMOLED Collection 🖤",
        message: "True black wallpapers crafted to look sensational and conserve your battery.",
        category: "featured",
        isPremade: true,
    },
    {
        name: "Community Spotlight 🎨",
        title: "Community Creators Spotlight 🎨",
        message: "Discover breathtaking wallpapers submitted by top artists in our community.",
        category: "community",
        isPremade: true,
    },
    {
        name: "New App Update 🚀",
        title: "SoftSky Wallpaper Update Available 🚀",
        message: "Update now to experience smoother performance, new category filters, and fresh daily wallpapers!",
        category: "update",
        isPremade: true,
    },
];
router.get('/status', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        res.json({
            firebase: fcm_1.default.getFirebaseStatus(),
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to get notification status', details: error.message });
    }
});
/**
 * @route   POST /api/notifications/send-to-user
 * @desc    Send notification to a specific user
 * @access  Admin
 */
router.post('/send-to-user', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { userId, title, message, data, imageUrl } = req.body;
        // Validation
        if (!userId || !title || !message) {
            return res.status(400).json({ error: 'userId, title, and message are required' });
        }
        // Send notification
        const result = await fcm_1.default.sendNotificationToUser(userId, title, message, data, imageUrl);
        if (result.success) {
            return res.json({
                success: true,
                message: 'Notification sent successfully',
                messageId: result.messageId,
            });
        }
        else {
            return res.status(400).json({
                success: false,
                error: result.error,
            });
        }
    }
    catch (error) {
        console.error('Error in send-to-user:', error);
        return res.status(500).json({ error: 'Failed to send notification', details: error.message });
    }
});
/**
 * @route   POST /api/notifications/send-to-all
 * @desc    Send notification to all users
 * @access  Admin
 */
router.post('/send-to-all', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { title, message, data, imageUrl } = req.body;
        // Validation
        if (!title || !message) {
            return res.status(400).json({ error: 'title and message are required' });
        }
        // Send notification to all users
        const result = await fcm_1.default.sendNotificationToAll(title, message, data, imageUrl);
        return res.json({
            success: true,
            message: 'Notifications sent',
            successCount: result.successCount,
            failureCount: result.failureCount,
            totalUsers: result.totalUsers,
        });
    }
    catch (error) {
        console.error('Error in send-to-all:', error);
        return res.status(500).json({ error: 'Failed to send notifications', details: error.message });
    }
});
/**
 * @route   POST /api/notifications/test
 * @desc    Send test notification to a specific FCM token
 * @access  Admin
 */
router.post('/test', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { token, title, message, data, imageUrl } = req.body;
        // Validation
        if (!token || !title || !message) {
            return res.status(400).json({ error: 'token, title, and message are required' });
        }
        // Send test notification
        const result = await fcm_1.default.sendNotificationToToken(token, title, message, data, imageUrl);
        if (result.success) {
            return res.json({
                success: true,
                message: 'Test notification sent successfully',
                messageId: result.messageId,
            });
        }
        else {
            return res.status(400).json({
                success: false,
                error: result.error,
            });
        }
    }
    catch (error) {
        console.error('Error in test notification:', error);
        return res.status(500).json({ error: 'Failed to send test notification', details: error.message });
    }
});
/**
 * @route   POST /api/notifications/upload-image
 * @desc    Upload thumbnail image for notifications
 * @access  Admin
 */
router.post('/upload-image', auth_1.authenticate, auth_1.requireAdmin, upload_1.upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'Image file is required' });
        }
        const { url, thumbnailUrl } = await (0, upload_1.uploadToCloudinary)(req.file.buffer, 'notifications');
        return res.json({
            success: true,
            url,
            thumbnailUrl,
        });
    }
    catch (error) {
        console.error('Error uploading notification thumbnail:', error);
        return res.status(500).json({ error: 'Failed to upload notification thumbnail', details: error.message });
    }
});
/**
 * @route   GET /api/notifications/templates
 * @desc    Get all notification templates (seeds premade defaults if empty)
 * @access  Admin
 */
router.get('/templates', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const repo = data_source_1.AppDataSource.getRepository(NotificationTemplate_1.NotificationTemplate);
        const count = await repo.count();
        if (count === 0) {
            const seedEntities = repo.create(DEFAULT_PREMADE_TEMPLATES);
            await repo.save(seedEntities);
        }
        const templates = await repo.find({
            order: {
                isPremade: 'DESC',
                createdAt: 'DESC',
            },
        });
        res.json({ success: true, templates });
    }
    catch (error) {
        console.error('Error fetching notification templates:', error);
        res.status(500).json({ error: 'Failed to fetch notification templates', details: error.message });
    }
});
/**
 * @route   POST /api/notifications/templates
 * @desc    Create a new notification template
 * @access  Admin
 */
router.post('/templates', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { name, title, message, imageUrl, category } = req.body;
        if (!name || !title || !message) {
            return res.status(400).json({ error: 'Name, title, and message are required' });
        }
        const repo = data_source_1.AppDataSource.getRepository(NotificationTemplate_1.NotificationTemplate);
        const template = repo.create({
            name: String(name).trim(),
            title: String(title).trim(),
            message: String(message).trim(),
            imageUrl: imageUrl ? String(imageUrl).trim() : undefined,
            category: category ? String(category).trim() : 'custom',
            isPremade: false,
        });
        await repo.save(template);
        res.status(201).json({ success: true, template });
    }
    catch (error) {
        console.error('Error creating notification template:', error);
        res.status(500).json({ error: 'Failed to create notification template', details: error.message });
    }
});
/**
 * @route   DELETE /api/notifications/templates/:id
 * @desc    Delete a notification template
 * @access  Admin
 */
router.delete('/templates/:id', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid template ID' });
        }
        const repo = data_source_1.AppDataSource.getRepository(NotificationTemplate_1.NotificationTemplate);
        const template = await repo.findOne({ where: { id } });
        if (!template) {
            return res.status(404).json({ error: 'Template not found' });
        }
        await repo.remove(template);
        res.json({ success: true, message: 'Template deleted successfully' });
    }
    catch (error) {
        console.error('Error deleting notification template:', error);
        res.status(500).json({ error: 'Failed to delete notification template', details: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=notifications.js.map