"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendNotificationToAll = exports.sendNotificationToUser = exports.sendNotificationToTokens = exports.sendNotificationToToken = void 0;
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin SDK
const initializeFirebaseAdmin = () => {
    if (admin.apps.length > 0) {
        return; // Already initialized
    }
    try {
        // Option 1: Using environment variables (recommended for production)
        if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
            admin.initializeApp({
                credential: admin.credential.cert({
                    projectId: process.env.FIREBASE_PROJECT_ID,
                    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
                }),
            });
            console.log('✅ Firebase Admin initialized with environment variables');
        }
        // Option 2: Using service account JSON file (for development)
        else if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
            const serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
            console.log('✅ Firebase Admin initialized with service account file');
        }
        else {
            console.warn('⚠️  Firebase Admin not initialized - FCM credentials not found');
            console.warn('Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in .env');
        }
    }
    catch (error) {
        console.error('❌ Failed to initialize Firebase Admin:', error);
    }
};
// Initialize on module load
initializeFirebaseAdmin();
/**
 * Send notification to a single device token
 */
const sendNotificationToToken = async (token, title, body, data) => {
    try {
        if (!admin.apps.length) {
            throw new Error('Firebase Admin not initialized');
        }
        const message = {
            notification: {
                title,
                body,
            },
            data: data || {},
            token,
            android: {
                priority: 'high',
                notification: {
                    channelId: 'softsky_wallpaper_notifications',
                    priority: 'high',
                    sound: 'default',
                },
            },
        };
        const response = await admin.messaging().send(message);
        console.log('✅ Notification sent successfully:', response);
        return { success: true, messageId: response };
    }
    catch (error) {
        console.error('❌ Error sending notification:', error);
        return { success: false, error: error.message };
    }
};
exports.sendNotificationToToken = sendNotificationToToken;
/**
 * Send notification to multiple device tokens
 */
const sendNotificationToTokens = async (tokens, title, body, data) => {
    try {
        if (!admin.apps.length) {
            throw new Error('Firebase Admin not initialized');
        }
        if (tokens.length === 0) {
            return { successCount: 0, failureCount: 0, errors: [] };
        }
        const message = {
            notification: {
                title,
                body,
            },
            data: data || {},
            tokens,
            android: {
                priority: 'high',
                notification: {
                    channelId: 'softsky_wallpaper_notifications',
                    priority: 'high',
                    sound: 'default',
                },
            },
        };
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`✅ Notifications sent: ${response.successCount} successful, ${response.failureCount} failed`);
        return {
            successCount: response.successCount,
            failureCount: response.failureCount,
            errors: response.responses
                .map((resp, idx) => resp.success ? null : { token: tokens[idx], error: resp.error })
                .filter(Boolean),
        };
    }
    catch (error) {
        console.error('❌ Error sending notifications:', error);
        return { successCount: 0, failureCount: tokens.length, errors: [{ error: error.message }] };
    }
};
exports.sendNotificationToTokens = sendNotificationToTokens;
/**
 * Send notification to a specific user by user ID
 */
const sendNotificationToUser = async (userId, title, body, data) => {
    try {
        const User = require('../models/User').default;
        const user = await User.findById(userId);
        if (!user) {
            return { success: false, error: 'User not found' };
        }
        if (!user.fcmToken) {
            return { success: false, error: 'User has no FCM token' };
        }
        const result = await (0, exports.sendNotificationToToken)(user.fcmToken, title, body, data);
        return result;
    }
    catch (error) {
        console.error('❌ Error sending notification to user:', error);
        return { success: false, error: error.message };
    }
};
exports.sendNotificationToUser = sendNotificationToUser;
/**
 * Send notification to all users with FCM tokens
 */
const sendNotificationToAll = async (title, body, data) => {
    try {
        const User = require('../models/User').default;
        // Get all users with FCM tokens
        const users = await User.find({ fcmToken: { $exists: true, $ne: null } });
        const tokens = users.map((user) => user.fcmToken).filter(Boolean);
        if (tokens.length === 0) {
            console.log('⚠️  No users with FCM tokens found');
            return { successCount: 0, failureCount: 0, totalUsers: 0 };
        }
        console.log(`📤 Sending notification to ${tokens.length} users...`);
        // Send in batches of 500 (FCM limit)
        const batchSize = 500;
        let totalSuccess = 0;
        let totalFailure = 0;
        for (let i = 0; i < tokens.length; i += batchSize) {
            const batch = tokens.slice(i, i + batchSize);
            const result = await (0, exports.sendNotificationToTokens)(batch, title, body, data);
            totalSuccess += result.successCount;
            totalFailure += result.failureCount;
        }
        return {
            successCount: totalSuccess,
            failureCount: totalFailure,
            totalUsers: tokens.length,
        };
    }
    catch (error) {
        console.error('❌ Error sending notification to all users:', error);
        return { successCount: 0, failureCount: 0, totalUsers: 0 };
    }
};
exports.sendNotificationToAll = sendNotificationToAll;
exports.default = {
    sendNotificationToToken: exports.sendNotificationToToken,
    sendNotificationToTokens: exports.sendNotificationToTokens,
    sendNotificationToUser: exports.sendNotificationToUser,
    sendNotificationToAll: exports.sendNotificationToAll,
};
//# sourceMappingURL=fcm.js.map