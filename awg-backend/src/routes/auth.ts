import { Router } from 'express';
import User, { IUser } from '../models/User';
import { generateToken, authenticate, requireAdmin, AuthRequest } from '../middleware/auth';

const router = Router();

// Admin login
router.post('/admin/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        // Find admin user
        const user = await User.findOne({ email, role: 'admin' }).select('+password');

        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Verify password
        const isMatch = await user.comparePassword(password);

        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Generate token
        const token = generateToken({
            id: user._id.toString(),
            email: user.email,
            role: user.role,
        });

        res.json({
            token,
            user: {
                id: user._id,
                email: user.email,
                displayName: user.displayName,
                role: user.role,
            },
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

// Verify Firebase token and sync user (for mobile app)
router.post('/firebase/verify', async (req, res) => {
    try {
        const { firebaseUid, email, displayName, photoUrl, authProvider } = req.body;

        if (!firebaseUid || !email) {
            return res.status(400).json({ error: 'Firebase UID and email are required' });
        }

        // Find or create user
        let user = await User.findOne({ firebaseUid });

        if (!user) {
            user = await User.findOne({ email });

            if (user) {
                // Update existing user with Firebase UID
                user.firebaseUid = firebaseUid;
                user.authProvider = authProvider || 'google';
                if (photoUrl) user.photoUrl = photoUrl;
                await user.save();
            } else {
                // Create new user
                user = await User.create({
                    firebaseUid,
                    email,
                    displayName: displayName || email.split('@')[0],
                    photoUrl,
                    authProvider: authProvider || 'google',
                    role: 'user',
                });
            }
        }

        // Generate token
        const token = generateToken({
            id: user._id.toString(),
            email: user.email,
            role: user.role,
        });

        res.json({
            token,
            user: {
                id: user._id,
                email: user.email,
                displayName: user.displayName,
                photoUrl: user.photoUrl,
                role: user.role,
                subscription: user.subscription,
            },
        });
    } catch (error) {
        console.error('Firebase verify error:', error);
        res.status(500).json({ error: 'Verification failed' });
    }
});

// Get current user profile
router.get('/me', authenticate, async (req: AuthRequest, res) => {
    try {
        const user = await User.findById(req.user?.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({
            id: user._id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
            role: user.role,
            subscription: user.subscription,
            downloads: user.downloads,
            createdAt: user.createdAt,
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get profile' });
    }
});

// Create initial admin (run once during setup)
router.post('/setup-admin', async (req, res) => {
    try {
        const existingAdmin = await User.findOne({ role: 'admin' });

        if (existingAdmin) {
            return res.status(400).json({ error: 'Admin already exists' });
        }

        const adminEmail = process.env.ADMIN_EMAIL || 'admin@awgwallpaper.com';
        const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';

        const admin = await User.create({
            email: adminEmail,
            password: adminPassword,
            displayName: 'Admin',
            authProvider: 'admin',
            role: 'admin',
        });

        res.json({
            message: 'Admin created successfully',
            email: admin.email,
        });
    } catch (error) {
        console.error('Setup admin error:', error);
        res.status(500).json({ error: 'Failed to create admin' });
    }
});

export default router;
