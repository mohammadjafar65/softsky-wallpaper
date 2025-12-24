"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const fcm_1 = __importDefault(require("../services/fcm"));
const router = (0, express_1.Router)();
/**
 * @route   POST /api/notifications/send-to-user
 * @desc    Send notification to a specific user
 * @access  Admin
 */
router.post('/send-to-user', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { userId, title, message, data } = req.body;
        // Validation
        if (!userId || !title || !message) {
            return res.status(400).json({ error: 'userId, title, and message are required' });
        }
        // Send notification
        const result = await fcm_1.default.sendNotificationToUser(userId, title, message, data);
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
        const { title, message, data } = req.body;
        // Validation
        if (!title || !message) {
            return res.status(400).json({ error: 'title and message are required' });
        }
        // Send notification to all users
        const result = await fcm_1.default.sendNotificationToAll(title, message, data);
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
        const { token, title, message, data } = req.body;
        // Validation
        if (!token || !title || !message) {
            return res.status(400).json({ error: 'token, title, and message are required' });
        }
        // Send test notification
        const result = await fcm_1.default.sendNotificationToToken(token, title, message, data);
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
exports.default = router;
//# sourceMappingURL=notifications.js.map