import { Router, Request, Response } from 'express';
import { authenticate, requireAdmin, AuthRequest } from '../middleware/auth';
import fcmService from '../services/fcm';

const router = Router();

/**
 * @route   POST /api/notifications/send-to-user
 * @desc    Send notification to a specific user
 * @access  Admin
 */
router.post('/send-to-user', authenticate, requireAdmin, async (req: AuthRequest, res: Response) => {
    try {
        const { userId, title, message, data } = req.body;

        // Validation
        if (!userId || !title || !message) {
            return res.status(400).json({ error: 'userId, title, and message are required' });
        }

        // Send notification
        const result = await fcmService.sendNotificationToUser(userId, title, message, data);

        if (result.success) {
            return res.json({
                success: true,
                message: 'Notification sent successfully',
                messageId: result.messageId,
            });
        } else {
            return res.status(400).json({
                success: false,
                error: result.error,
            });
        }
    } catch (error: any) {
        console.error('Error in send-to-user:', error);
        return res.status(500).json({ error: 'Failed to send notification', details: error.message });
    }
});

/**
 * @route   POST /api/notifications/send-to-all
 * @desc    Send notification to all users
 * @access  Admin
 */
router.post('/send-to-all', authenticate, requireAdmin, async (req: AuthRequest, res: Response) => {
    try {
        const { title, message, data } = req.body;

        // Validation
        if (!title || !message) {
            return res.status(400).json({ error: 'title and message are required' });
        }

        // Send notification to all users
        const result = await fcmService.sendNotificationToAll(title, message, data);

        return res.json({
            success: true,
            message: 'Notifications sent',
            successCount: result.successCount,
            failureCount: result.failureCount,
            totalUsers: result.totalUsers,
        });
    } catch (error: any) {
        console.error('Error in send-to-all:', error);
        return res.status(500).json({ error: 'Failed to send notifications', details: error.message });
    }
});

/**
 * @route   POST /api/notifications/test
 * @desc    Send test notification to a specific FCM token
 * @access  Admin
 */
router.post('/test', authenticate, requireAdmin, async (req: AuthRequest, res: Response) => {
    try {
        const { token, title, message, data } = req.body;

        // Validation
        if (!token || !title || !message) {
            return res.status(400).json({ error: 'token, title, and message are required' });
        }

        // Send test notification
        const result = await fcmService.sendNotificationToToken(token, title, message, data);

        if (result.success) {
            return res.json({
                success: true,
                message: 'Test notification sent successfully',
                messageId: result.messageId,
            });
        } else {
            return res.status(400).json({
                success: false,
                error: result.error,
            });
        }
    } catch (error: any) {
        console.error('Error in test notification:', error);
        return res.status(500).json({ error: 'Failed to send test notification', details: error.message });
    }
});

export default router;
