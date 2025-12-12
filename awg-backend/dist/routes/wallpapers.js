"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const Wallpaper_1 = __importDefault(require("../models/Wallpaper"));
const Category_1 = __importDefault(require("../models/Category"));
const auth_1 = require("../middleware/auth");
const upload_1 = require("../middleware/upload");
const router = (0, express_1.Router)();
// Get all wallpapers (public, with pagination)
router.get('/', auth_1.optionalAuth, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const category = req.query.category;
        const isPro = req.query.isPro === 'true';
        const isWide = req.query.isWide === 'true';
        const query = {};
        if (category && category !== 'all') {
            const categoryDoc = await Category_1.default.findOne({ slug: category });
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
        const total = await Wallpaper_1.default.countDocuments(query);
        const wallpapers = await Wallpaper_1.default.find(query)
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
    }
    catch (error) {
        console.error('Get wallpapers error:', error);
        res.status(500).json({ error: 'Failed to get wallpapers' });
    }
});
// Search wallpapers
router.get('/search', async (req, res) => {
    try {
        const query = req.query.q;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        if (!query) {
            return res.status(400).json({ error: 'Search query is required' });
        }
        const searchQuery = {
            $or: [
                { title: { $regex: query, $options: 'i' } },
                { tags: { $in: [new RegExp(query, 'i')] } },
            ],
        };
        const total = await Wallpaper_1.default.countDocuments(searchQuery);
        const wallpapers = await Wallpaper_1.default.find(searchQuery)
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
    }
    catch (error) {
        console.error('Search error:', error);
        res.status(500).json({ error: 'Search failed' });
    }
});
// Get single wallpaper
router.get('/:id', async (req, res) => {
    try {
        const wallpaper = await Wallpaper_1.default.findById(req.params.id)
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
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to get wallpaper' });
    }
});
// Create wallpaper (admin only)
router.post('/', auth_1.authenticate, auth_1.requireAdmin, upload_1.upload.single('image'), async (req, res) => {
    try {
        const { title, category, tags, isWide, isPro, packId } = req.body;
        if (!req.file) {
            return res.status(400).json({ error: 'Image is required' });
        }
        if (!title || !category) {
            return res.status(400).json({ error: 'Title and category are required' });
        }
        // Upload to Cloudinary
        const { url, thumbnailUrl } = await (0, upload_1.uploadToCloudinary)(req.file.buffer, isWide === 'true' ? 'wide' : 'wallpapers');
        // Verify category exists
        const categoryDoc = await Category_1.default.findById(category);
        if (!categoryDoc) {
            return res.status(400).json({ error: 'Invalid category' });
        }
        const wallpaper = await Wallpaper_1.default.create({
            title,
            imageUrl: url,
            thumbnailUrl,
            category,
            tags: tags ? tags.split(',').map((t) => t.trim()) : [],
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
    }
    catch (error) {
        console.error('Create wallpaper error:', error);
        res.status(500).json({ error: 'Failed to create wallpaper' });
    }
});
// Update wallpaper (admin only)
router.put('/:id', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { title, category, tags, isWide, isPro, packId } = req.body;
        const wallpaper = await Wallpaper_1.default.findById(req.params.id);
        if (!wallpaper) {
            return res.status(404).json({ error: 'Wallpaper not found' });
        }
        if (title)
            wallpaper.title = title;
        if (category)
            wallpaper.category = category;
        if (tags)
            wallpaper.tags = tags.split(',').map((t) => t.trim());
        if (isWide !== undefined)
            wallpaper.isWide = isWide === true || isWide === 'true';
        if (isPro !== undefined)
            wallpaper.isPro = isPro === true || isPro === 'true';
        if (packId !== undefined)
            wallpaper.packId = packId === '' ? undefined : packId;
        await wallpaper.save();
        res.json({
            message: 'Wallpaper updated successfully',
            wallpaper: {
                id: wallpaper._id,
                title: wallpaper.title,
                isPro: wallpaper.isPro,
            },
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to update wallpaper' });
    }
});
// Delete wallpaper (admin only)
router.delete('/:id', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const wallpaper = await Wallpaper_1.default.findById(req.params.id);
        if (!wallpaper) {
            return res.status(404).json({ error: 'Wallpaper not found' });
        }
        // Update category count
        await Category_1.default.findByIdAndUpdate(wallpaper.category, {
            $inc: { wallpaperCount: -1 },
        });
        await Wallpaper_1.default.findByIdAndDelete(req.params.id);
        res.json({ message: 'Wallpaper deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to delete wallpaper' });
    }
});
// Track download
router.post('/:id/download', async (req, res) => {
    try {
        const wallpaper = await Wallpaper_1.default.findByIdAndUpdate(req.params.id, { $inc: { downloads: 1 } }, { new: true });
        if (!wallpaper) {
            return res.status(404).json({ error: 'Wallpaper not found' });
        }
        res.json({ downloads: wallpaper.downloads });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to track download' });
    }
});
exports.default = router;
//# sourceMappingURL=wallpapers.js.map