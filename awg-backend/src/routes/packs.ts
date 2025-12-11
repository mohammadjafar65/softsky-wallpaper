import { Router } from 'express';
import Pack from '../models/Pack';
import Wallpaper from '../models/Wallpaper';
import { authenticate, requireAdmin, AuthRequest, optionalAuth } from '../middleware/auth';
import { upload, uploadToCloudinary } from '../middleware/upload';

const router = Router();

// Get all packs (public)
router.get('/', optionalAuth, async (req, res) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;
        const isPro = req.query.isPro === 'true';

        const query: any = { isActive: true };
        if (req.query.isPro !== undefined) {
            query.isPro = isPro;
        }

        const total = await Pack.countDocuments(query);
        const packs = await Pack.find(query)
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
    } catch (error) {
        console.error('Get packs error:', error);
        res.status(500).json({ error: 'Failed to get packs' });
    }
});

// Get single pack details with wallpapers
router.get('/:id', optionalAuth, async (req, res) => {
    try {
        const pack = await Pack.findById(req.params.id);
        if (!pack) {
            return res.status(404).json({ error: 'Pack not found' });
        }

        const wallpapers = await Wallpaper.find({ packId: pack._id })
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
    } catch (error) {
        res.status(500).json({ error: 'Failed to get pack' });
    }
});

// Create pack (admin only)
router.post('/', authenticate, requireAdmin, upload.single('coverImage'), async (req: AuthRequest, res) => {
    try {
        const { name, description, isPro, isActive } = req.body;

        if (!req.file) {
            return res.status(400).json({ error: 'Cover image is required' });
        }

        if (!name) {
            return res.status(400).json({ error: 'Name is required' });
        }

        // Upload to Cloudinary
        const { url } = await uploadToCloudinary(req.file.buffer, 'packs');

        const pack = await Pack.create({
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
    } catch (error) {
        console.error('Create pack error:', error);
        res.status(500).json({ error: 'Failed to create pack' });
    }
});

// Update pack (admin only)
router.put('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { name, description, isPro, isActive } = req.body;
        const pack = await Pack.findById(req.params.id);

        if (!pack) {
            return res.status(404).json({ error: 'Pack not found' });
        }

        if (name) pack.name = name;
        if (description !== undefined) pack.description = description;
        if (isPro !== undefined) pack.isPro = isPro === true || isPro === 'true';
        if (isActive !== undefined) pack.isActive = isActive === true || isActive === 'true';

        await pack.save();

        res.json({
            message: 'Pack updated successfully',
            pack,
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update pack' });
    }
});

// Delete pack (admin only)
router.delete('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const pack = await Pack.findById(req.params.id);
        if (!pack) {
            return res.status(404).json({ error: 'Pack not found' });
        }

        // Unlink wallpapers from this pack
        await Wallpaper.updateMany(
            { packId: pack._id },
            { $unset: { packId: 1 } }
        );

        await Pack.findByIdAndDelete(req.params.id);

        res.json({ message: 'Pack deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete pack' });
    }
});

export default router;
