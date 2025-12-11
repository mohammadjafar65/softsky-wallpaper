import { Router } from 'express';
import Wallpaper from '../models/Wallpaper';
import Category from '../models/Category';
import { authenticate, requireAdmin, AuthRequest, optionalAuth } from '../middleware/auth';
import { upload, uploadToCloudinary, deleteFromCloudinary } from '../middleware/upload';

const router = Router();

// Get all wallpapers (public, with pagination)
router.get('/', optionalAuth, async (req: AuthRequest, res) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;
        const category = req.query.category as string;
        const isPro = req.query.isPro === 'true';
        const isWide = req.query.isWide === 'true';

        const query: any = {};

        if (category && category !== 'all') {
            const categoryDoc = await Category.findOne({ slug: category });
            if (categoryDoc) {
                query.category = categoryDoc._id;
            }
        }

        if (req.query.isPro !== undefined) {
            query.isPro = isPro;
        }

        if (req.query.isWide !== undefined) {
            query.isWide = isWide;
        }

        if (req.query.packId) {
            query.packId = req.query.packId;
        }

        const total = await Wallpaper.countDocuments(query);
        const wallpapers = await Wallpaper.find(query)
            .populate('category', 'name slug icon')
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(limit);

        res.json({
            wallpapers: wallpapers.map(w => ({
                id: w._id,
                title: w.title,
                imageUrl: w.imageUrl,
                thumbnailUrl: w.thumbnailUrl,
                category: w.category,
                tags: w.tags,
                isWide: w.isWide,
                isPro: w.isPro,
                downloads: w.downloads,
                createdAt: w.createdAt,
            })),
            pagination: {
                page,
                limit,
                total,
                pages: Math.ceil(total / limit),
            },
        });
    } catch (error) {
        console.error('Get wallpapers error:', error);
        res.status(500).json({ error: 'Failed to get wallpapers' });
    }
});

// Search wallpapers
router.get('/search', async (req, res) => {
    try {
        const query = req.query.q as string;
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;

        if (!query) {
            return res.status(400).json({ error: 'Search query is required' });
        }

        const searchQuery = {
            $or: [
                { title: { $regex: query, $options: 'i' } },
                { tags: { $in: [new RegExp(query, 'i')] } },
            ],
        };

        const total = await Wallpaper.countDocuments(searchQuery);
        const wallpapers = await Wallpaper.find(searchQuery)
            .populate('category', 'name slug icon')
            .sort({ downloads: -1, createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(limit);

        res.json({
            wallpapers: wallpapers.map(w => ({
                id: w._id,
                title: w.title,
                imageUrl: w.imageUrl,
                thumbnailUrl: w.thumbnailUrl,
                category: w.category,
                tags: w.tags,
                isWide: w.isWide,
                isPro: w.isPro,
                downloads: w.downloads,
                createdAt: w.createdAt,
            })),
            pagination: {
                page,
                limit,
                total,
                pages: Math.ceil(total / limit),
            },
        });
    } catch (error) {
        console.error('Search error:', error);
        res.status(500).json({ error: 'Search failed' });
    }
});

// Get single wallpaper
router.get('/:id', async (req, res) => {
    try {
        const wallpaper = await Wallpaper.findById(req.params.id)
            .populate('category', 'name slug icon');

        if (!wallpaper) {
            return res.status(404).json({ error: 'Wallpaper not found' });
        }

        // Increment views
        wallpaper.views += 1;
        await wallpaper.save();

        res.json({
            id: wallpaper._id,
            title: wallpaper.title,
            imageUrl: wallpaper.imageUrl,
            thumbnailUrl: wallpaper.thumbnailUrl,
            category: wallpaper.category,
            tags: wallpaper.tags,
            isWide: wallpaper.isWide,
            isPro: wallpaper.isPro,
            downloads: wallpaper.downloads,
            views: wallpaper.views,
            createdAt: wallpaper.createdAt,
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get wallpaper' });
    }
});

// Create wallpaper (admin only)
router.post('/', authenticate, requireAdmin, upload.single('image'), async (req: AuthRequest, res) => {
    try {
        const { title, category, tags, isWide, isPro, packId } = req.body;

        if (!req.file) {
            return res.status(400).json({ error: 'Image is required' });
        }

        if (!title || !category) {
            return res.status(400).json({ error: 'Title and category are required' });
        }

        // Upload to Cloudinary
        const { url, thumbnailUrl } = await uploadToCloudinary(
            req.file.buffer,
            isWide === 'true' ? 'wide' : 'wallpapers'
        );

        // Verify category exists
        const categoryDoc = await Category.findById(category);
        if (!categoryDoc) {
            return res.status(400).json({ error: 'Invalid category' });
        }

        const wallpaper = await Wallpaper.create({
            title,
            imageUrl: url,
            thumbnailUrl,
            category,
            tags: tags ? tags.split(',').map((t: string) => t.trim()) : [],
            isWide: isWide === 'true',
            isPro: isPro === 'true',
            packId: packId || undefined,
        });

        // Update category wallpaper count
        categoryDoc.wallpaperCount += 1;
        await categoryDoc.save();

        res.status(201).json({
            message: 'Wallpaper created successfully',
            wallpaper: {
                id: wallpaper._id,
                title: wallpaper.title,
                imageUrl: wallpaper.imageUrl,
                thumbnailUrl: wallpaper.thumbnailUrl,
            },
        });
    } catch (error) {
        console.error('Create wallpaper error:', error);
        res.status(500).json({ error: 'Failed to create wallpaper' });
    }
});

// Update wallpaper (admin only)
router.put('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { title, category, tags, isWide, isPro, packId } = req.body;

        const wallpaper = await Wallpaper.findById(req.params.id);

        if (!wallpaper) {
            return res.status(404).json({ error: 'Wallpaper not found' });
        }

        if (title) wallpaper.title = title;
        if (category) wallpaper.category = category;
        if (tags) wallpaper.tags = tags.split(',').map((t: string) => t.trim());
        if (isWide !== undefined) wallpaper.isWide = isWide === true || isWide === 'true';
        if (isPro !== undefined) wallpaper.isPro = isPro === true || isPro === 'true';
        if (packId !== undefined) wallpaper.packId = packId === '' ? undefined : packId;

        await wallpaper.save();

        res.json({
            message: 'Wallpaper updated successfully',
            wallpaper: {
                id: wallpaper._id,
                title: wallpaper.title,
                isPro: wallpaper.isPro,
            },
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update wallpaper' });
    }
});

// Delete wallpaper (admin only)
router.delete('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const wallpaper = await Wallpaper.findById(req.params.id);

        if (!wallpaper) {
            return res.status(404).json({ error: 'Wallpaper not found' });
        }

        // Update category count
        await Category.findByIdAndUpdate(wallpaper.category, {
            $inc: { wallpaperCount: -1 },
        });

        await Wallpaper.findByIdAndDelete(req.params.id);

        res.json({ message: 'Wallpaper deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete wallpaper' });
    }
});

// Track download
router.post('/:id/download', async (req, res) => {
    try {
        const wallpaper = await Wallpaper.findByIdAndUpdate(
            req.params.id,
            { $inc: { downloads: 1 } },
            { new: true }
        );

        if (!wallpaper) {
            return res.status(404).json({ error: 'Wallpaper not found' });
        }

        res.json({ downloads: wallpaper.downloads });
    } catch (error) {
        res.status(500).json({ error: 'Failed to track download' });
    }
});

export default router;
