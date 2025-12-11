import { Router } from 'express';
import Category from '../models/Category';
import { authenticate, requireAdmin, AuthRequest } from '../middleware/auth';

const router = Router();

// Get all categories (public)
router.get('/', async (req, res) => {
    try {
        const includeInactive = req.query.includeInactive === 'true';

        const query: any = {};
        if (!includeInactive) {
            query.isActive = true;
        }

        const categories = await Category.find(query).sort({ name: 1 });

        res.json({
            categories: categories.map(c => ({
                id: c._id,
                name: c.name,
                slug: c.slug,
                icon: c.icon,
                description: c.description,
                wallpaperCount: c.wallpaperCount,
                isActive: c.isActive,
            })),
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get categories' });
    }
});

// Get single category
router.get('/:id', async (req, res) => {
    try {
        const category = await Category.findById(req.params.id);

        if (!category) {
            return res.status(404).json({ error: 'Category not found' });
        }

        res.json({
            id: category._id,
            name: category.name,
            slug: category.slug,
            icon: category.icon,
            description: category.description,
            wallpaperCount: category.wallpaperCount,
            isActive: category.isActive,
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to get category' });
    }
});

// Create category (admin only)
router.post('/', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { name, icon, description } = req.body;

        if (!name) {
            return res.status(400).json({ error: 'Name is required' });
        }

        // Generate slug from name
        const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

        // Check if slug already exists
        const existing = await Category.findOne({ slug });
        if (existing) {
            return res.status(400).json({ error: 'Category with this name already exists' });
        }

        const category = await Category.create({
            name,
            slug,
            icon: icon || '🎨',
            description,
        });

        res.status(201).json({
            message: 'Category created successfully',
            category: {
                id: category._id,
                name: category.name,
                slug: category.slug,
                icon: category.icon,
            },
        });
    } catch (error) {
        console.error('Create category error:', error);
        res.status(500).json({ error: 'Failed to create category' });
    }
});

// Update category (admin only)
router.put('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { name, icon, description, isActive } = req.body;

        const category = await Category.findById(req.params.id);

        if (!category) {
            return res.status(404).json({ error: 'Category not found' });
        }

        if (name) {
            category.name = name;
            category.slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
        }
        if (icon) category.icon = icon;
        if (description !== undefined) category.description = description;
        if (isActive !== undefined) category.isActive = isActive === true || isActive === 'true';

        await category.save();

        res.json({
            message: 'Category updated successfully',
            category: {
                id: category._id,
                name: category.name,
                slug: category.slug,
                icon: category.icon,
                isActive: category.isActive,
            },
        });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update category' });
    }
});

// Delete category (admin only)
router.delete('/:id', authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const category = await Category.findById(req.params.id);

        if (!category) {
            return res.status(404).json({ error: 'Category not found' });
        }

        if (category.wallpaperCount > 0) {
            return res.status(400).json({
                error: 'Cannot delete category with wallpapers. Please reassign or delete wallpapers first.'
            });
        }

        await Category.findByIdAndDelete(req.params.id);

        res.json({ message: 'Category deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to delete category' });
    }
});

export default router;
