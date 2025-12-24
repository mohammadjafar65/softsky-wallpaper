import dotenv from 'dotenv';
// Load environment variables immediately
dotenv.config();

import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';

// Import routes
import authRoutes from './routes/auth';
import wallpaperRoutes from './routes/wallpapers';
import categoryRoutes from './routes/categories';
import userRoutes from './routes/users';
import subscriptionRoutes from './routes/subscriptions';
import packRoutes from './routes/packs';
import notificationRoutes from './routes/notifications';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
const allowedOrigins = [
    // 'http://localhost:5173',
    // 'http://localhost:5174',
    // 'http://localhost:3000',
    process.env.CLIENT_URL || '',
    'http://softskyadmin.softsky.studio',
    'https://softskyadmin.softsky.studio'
].filter(Boolean);

// CORS configuration
const corsOptions = {
    origin: function (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) {
        // Allow requests with no origin (like mobile apps or curl requests)
        if (!origin) return callback(null, true);

        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            console.log('Blocked by CORS:', origin);
            callback(null, true); // For now, allow all origins for debugging
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Origin', 'Accept', 'X-Requested-With'],
    optionsSuccessStatus: 200 // Some legacy browsers choke on 204
};

// Explicit CORS headers middleware (handles cases where reverse proxy interferes)
app.use((req, res, next) => {
    const origin = req.headers.origin;

    // Set CORS headers for all requests
    res.setHeader('Access-Control-Allow-Origin', origin || '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Origin, Accept, X-Requested-With');
    res.setHeader('Access-Control-Allow-Credentials', 'true');

    // Handle preflight requests immediately
    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }

    next();
});

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/awg_wallpaper';

// Log masked URI for debugging
console.log('Attempting to connect to MongoDB...');
const maskedURI = MONGODB_URI.replace(/:([^:@]+)@/, ':****@');
console.log(`Connection URI: ${maskedURI}`);

mongoose.connect(MONGODB_URI)
    .then(() => console.log('✅ Connected to MongoDB'))
    .catch((err) => console.error('❌ MongoDB connection error:', err));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/wallpapers', wallpaperRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/users', userRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/packs', packRoutes);
app.use('/api/notifications', notificationRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', message: 'AWG Backend API is running!' });
});

// Error handling middleware
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📡 API available at http://localhost:${PORT}/api`);
});

export default app;
