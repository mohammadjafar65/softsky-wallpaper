"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const Pack_1 = __importDefault(require("../models/Pack"));
const Wallpaper_1 = __importDefault(require("../models/Wallpaper"));
const auth_1 = require("../middleware/auth");
const upload_1 = require("../middleware/upload");
const router = (0, express_1.Router)();
// Get all packs (public)
router.get('/', auth_1.optionalAuth, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const isPro = req.query.isPro === 'true';
        const query = { isActive: true };
        if (req.query.isPro !== undefined) {
            query.isPro = isPro;
        }
        const total = await Pack_1.default.countDocuments(query);
        const packs = await Pack_1.default.find(query)
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(limit);
        res.json({
            packs,
            pagination: {
                page,
                limit,
                total,
                pages: Math.ceil(total / limit),
            },
        });
    }
    catch (error) {
        console.error('Get packs error:', error);
        res.status(500).json({ error: 'Failed to get packs' });
    }
});
// Get single pack details with wallpapers
router.get('/:id', auth_1.optionalAuth, async (req, res) => {
    try {
        const pack = await Pack_1.default.findById(req.params.id);
        if (!pack) {
            return res.status(404).json({ error: 'Pack not found' });
        }
        const wallpapers = await Wallpaper_1.default.find({ packId: pack._id })
            .populate('category', 'name slug icon')
            .sort({ createdAt: -1 });
        res.json({
            pack,
            wallpapers: wallpapers.map(w => ({
                id: w._id,
                title: w.title,
                imageUrl: w.imageUrl,
                thumbnailUrl: w.thumbnailUrl,
                category: w.category,
                isPro: w.isPro,
            })),
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to get pack' });
    }
});
// Create pack (admin only)
router.post('/', auth_1.authenticate, auth_1.requireAdmin, upload_1.upload.single('coverImage'), async (req, res) => {
    try {
        const { name, description, isPro, isActive } = req.body;
        if (!req.file) {
            return res.status(400).json({ error: 'Cover image is required' });
        }
        if (!name) {
            return res.status(400).json({ error: 'Name is required' });
        }
        // Upload to Cloudinary
        const { url } = await (0, upload_1.uploadToCloudinary)(req.file.buffer, 'packs');
        const pack = await Pack_1.default.create({
            name,
            description,
            coverImage: url,
            isPro: isPro === 'true',
            isActive: isActive === 'undefined' ? true : isActive === 'true',
        });
        res.status(201).json({
            message: 'Pack created successfully',
            pack,
        });
    }
    catch (error) {
        console.error('Create pack error:', error);
        res.status(500).json({ error: 'Failed to create pack' });
    }
});
// Update pack (admin only)
router.put('/:id', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { name, description, isPro, isActive } = req.body;
        const pack = await Pack_1.default.findById(req.params.id);
        if (!pack) {
            return res.status(404).json({ error: 'Pack not found' });
        }
        if (name)
            pack.name = name;
        if (description !== undefined)
            pack.description = description;
        if (isPro !== undefined)
            pack.isPro = isPro === true || isPro === 'true';
        if (isActive !== undefined)
            pack.isActive = isActive === true || isActive === 'true';
        await pack.save();
        res.json({
            message: 'Pack updated successfully',
            pack,
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to update pack' });
    }
});
// Delete pack (admin only)
router.delete('/:id', auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const pack = await Pack_1.default.findById(req.params.id);
        if (!pack) {
            return res.status(404).json({ error: 'Pack not found' });
        }
        // Unlink wallpapers from this pack
        await Wallpaper_1.default.updateMany({ packId: pack._id }, { $unset: { packId: 1 } });
        await Pack_1.default.findByIdAndDelete(req.params.id);
        res.json({ message: 'Pack deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to delete pack' });
    }
});
exports.default = router;
//# sourceMappingURL=packs.js.map