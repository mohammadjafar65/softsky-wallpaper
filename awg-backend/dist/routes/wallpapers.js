"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const data_source_1 = require("../data-source");
const Wallpaper_1 = require("../entities/Wallpaper");
const User_1 = require("../entities/User");
const Category_1 = require("../entities/Category");
const Pack_1 = require("../entities/Pack");
const auth_1 = require("../middleware/auth");
const upload_1 = require("../middleware/upload");
const router = (0, express_1.Router)();
// Get all wallpapers (public, with pagination)
router.get("/", auth_1.optionalAuth, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const category = req.query.category;
        const isPro = req.query.isPro === "true";
        const isWide = req.query.isWide === "true";
        const wallpaperRepository = data_source_1.AppDataSource.getRepository(Wallpaper_1.Wallpaper);
        const categoryRepository = data_source_1.AppDataSource.getRepository(Category_1.Category);
        const queryBuilder = wallpaperRepository
            .createQueryBuilder("wallpaper")
            .leftJoinAndSelect("wallpaper.category", "category");
        if (category && category !== "all") {
            const categoryDoc = await categoryRepository.findOne({
                where: { slug: category },
            });
            if (categoryDoc) {
                queryBuilder.andWhere("wallpaper.categoryId = :categoryId", {
                    categoryId: categoryDoc.id,
                });
            }
        }
        if (req.query.isPro !== undefined) {
            queryBuilder.andWhere("wallpaper.isPro = :isPro", { isPro });
        }
        if (req.query.isWide !== undefined) {
            queryBuilder.andWhere("wallpaper.isWide = :isWide", { isWide });
        }
        if (req.query.packId) {
            queryBuilder.andWhere("wallpaper.packId = :packId", {
                packId: parseInt(req.query.packId),
            });
        }
        const total = await queryBuilder.getCount();
        const wallpapers = await queryBuilder
            .orderBy("wallpaper.createdAt", "DESC")
            .skip((page - 1) * limit)
            .take(limit)
            .getMany();
        res.json({
            wallpapers: wallpapers.map((w) => ({
                id: w.id,
                title: w.title,
                imageUrl: w.imageUrl,
                thumbnailUrl: w.thumbnailUrl,
                category: w.category
                    ? {
                        id: w.category.id,
                        name: w.category.name,
                        slug: w.category.slug,
                        icon: w.category.icon,
                    }
                    : null,
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
        console.error("Get wallpapers error:", error);
        res.status(500).json({ error: "Failed to get wallpapers" });
    }
});
// Search wallpapers
router.get("/search", async (req, res) => {
    try {
        const query = req.query.q;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        if (!query) {
            return res.status(400).json({ error: "Search query is required" });
        }
        const wallpaperRepository = data_source_1.AppDataSource.getRepository(Wallpaper_1.Wallpaper);
        const queryBuilder = wallpaperRepository
            .createQueryBuilder("wallpaper")
            .leftJoinAndSelect("wallpaper.category", "category")
            .where("wallpaper.title LIKE :query", { query: `%${query}%` })
            .orWhere("JSON_SEARCH(wallpaper.tags, 'one', :searchTag) IS NOT NULL", {
            searchTag: `%${query}%`,
        });
        const total = await queryBuilder.getCount();
        const wallpapers = await queryBuilder
            .orderBy("wallpaper.downloads", "DESC")
            .addOrderBy("wallpaper.createdAt", "DESC")
            .skip((page - 1) * limit)
            .take(limit)
            .getMany();
        res.json({
            wallpapers: wallpapers.map((w) => ({
                id: w.id,
                title: w.title,
                imageUrl: w.imageUrl,
                thumbnailUrl: w.thumbnailUrl,
                category: w.category
                    ? {
                        id: w.category.id,
                        name: w.category.name,
                        slug: w.category.slug,
                        icon: w.category.icon,
                    }
                    : null,
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
        console.error("Search error:", error);
        res.status(500).json({ error: "Search failed" });
    }
});
// Get single wallpaper
router.get("/:id", async (req, res) => {
    try {
        const wallpaperRepository = data_source_1.AppDataSource.getRepository(Wallpaper_1.Wallpaper);
        const wallpaper = await wallpaperRepository.findOne({
            where: { id: parseInt(req.params.id) },
            relations: ["category"],
        });
        if (!wallpaper) {
            return res.status(404).json({ error: "Wallpaper not found" });
        }
        // Increment views
        await wallpaperRepository.increment({ id: wallpaper.id }, "views", 1);
        res.json({
            id: wallpaper.id,
            title: wallpaper.title,
            imageUrl: wallpaper.imageUrl,
            thumbnailUrl: wallpaper.thumbnailUrl,
            category: wallpaper.category
                ? {
                    id: wallpaper.category.id,
                    name: wallpaper.category.name,
                    slug: wallpaper.category.slug,
                    icon: wallpaper.category.icon,
                }
                : null,
            tags: wallpaper.tags,
            isWide: wallpaper.isWide,
            isPro: wallpaper.isPro,
            downloads: wallpaper.downloads,
            views: wallpaper.views + 1,
            createdAt: wallpaper.createdAt,
        });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to get wallpaper" });
    }
});
// Create wallpaper (admin only)
router.post("/", auth_1.authenticate, auth_1.requireAdmin, upload_1.upload.single("image"), async (req, res) => {
    try {
        const { title, category, tags, isWide, isPro, packId } = req.body;
        if (!req.file) {
            return res.status(400).json({ error: "Image is required" });
        }
        if (!title || !category) {
            return res
                .status(400)
                .json({ error: "Title and category are required" });
        }
        // Upload to Cloudinary
        const { url, thumbnailUrl } = await (0, upload_1.uploadToCloudinary)(req.file.buffer, isWide === "true" ? "wide" : "wallpapers");
        const categoryRepository = data_source_1.AppDataSource.getRepository(Category_1.Category);
        const wallpaperRepository = data_source_1.AppDataSource.getRepository(Wallpaper_1.Wallpaper);
        const packRepository = data_source_1.AppDataSource.getRepository(Pack_1.Pack);
        // Verify category exists
        const categoryDoc = await categoryRepository.findOne({
            where: { id: parseInt(category) },
        });
        if (!categoryDoc) {
            return res.status(400).json({ error: "Invalid category" });
        }
        const wallpaper = wallpaperRepository.create({
            title,
            imageUrl: url,
            thumbnailUrl,
            categoryId: parseInt(category),
            tags: tags ? tags.split(",").map((t) => t.trim()) : [],
            isWide: isWide === "true",
            isPro: isPro === "true",
            packId: packId ? parseInt(packId) : undefined,
        });
        await wallpaperRepository.save(wallpaper);
        // Update category wallpaper count
        await categoryRepository.increment({ id: categoryDoc.id }, "wallpaperCount", 1);
        // Update pack wallpaper count if assigned to a pack
        if (packId) {
            await packRepository.increment({ id: parseInt(packId) }, "wallpaperCount", 1);
        }
        res.status(201).json({
            message: "Wallpaper created successfully",
            wallpaper: {
                id: wallpaper.id,
                title: wallpaper.title,
                imageUrl: wallpaper.imageUrl,
                thumbnailUrl: wallpaper.thumbnailUrl,
            },
        });
    }
    catch (error) {
        console.error("Create wallpaper error:", error);
        res.status(500).json({ error: "Failed to create wallpaper" });
    }
});
// Update wallpaper (admin only)
router.put("/:id", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const { title, category, tags, isWide, isPro, packId } = req.body;
        const wallpaperRepository = data_source_1.AppDataSource.getRepository(Wallpaper_1.Wallpaper);
        const packRepository = data_source_1.AppDataSource.getRepository(Pack_1.Pack);
        const wallpaper = await wallpaperRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });
        if (!wallpaper) {
            return res.status(404).json({ error: "Wallpaper not found" });
        }
        if (title)
            wallpaper.title = title;
        if (category)
            wallpaper.categoryId = parseInt(category);
        if (tags)
            wallpaper.tags = tags.split(",").map((t) => t.trim());
        if (isWide !== undefined)
            wallpaper.isWide = isWide === true || isWide === "true";
        if (isPro !== undefined)
            wallpaper.isPro = isPro === true || isPro === "true";
        // Handle pack assignment changes
        if (packId !== undefined) {
            const oldPackId = wallpaper.packId;
            const newPackId = packId === "" ? undefined : parseInt(packId);
            // If pack changed, update counts
            if (oldPackId !== newPackId) {
                // Decrement old pack count
                if (oldPackId) {
                    await packRepository.decrement({ id: oldPackId }, "wallpaperCount", 1);
                }
                // Increment new pack count
                if (newPackId) {
                    await packRepository.increment({ id: newPackId }, "wallpaperCount", 1);
                }
            }
            wallpaper.packId = newPackId;
        }
        await wallpaperRepository.save(wallpaper);
        res.json({
            message: "Wallpaper updated successfully",
            wallpaper: {
                id: wallpaper.id,
                title: wallpaper.title,
                isPro: wallpaper.isPro,
            },
        });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to update wallpaper" });
    }
});
// Delete wallpaper (admin only)
router.delete("/:id", auth_1.authenticate, auth_1.requireAdmin, async (req, res) => {
    try {
        const wallpaperRepository = data_source_1.AppDataSource.getRepository(Wallpaper_1.Wallpaper);
        const categoryRepository = data_source_1.AppDataSource.getRepository(Category_1.Category);
        const packRepository = data_source_1.AppDataSource.getRepository(Pack_1.Pack);
        const wallpaper = await wallpaperRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });
        if (!wallpaper) {
            return res.status(404).json({ error: "Wallpaper not found" });
        }
        // Update category count
        await categoryRepository.decrement({ id: wallpaper.categoryId }, "wallpaperCount", 1);
        // Update pack count if wallpaper was in a pack
        if (wallpaper.packId) {
            await packRepository.decrement({ id: wallpaper.packId }, "wallpaperCount", 1);
        }
        await wallpaperRepository.delete(req.params.id);
        res.json({ message: "Wallpaper deleted successfully" });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to delete wallpaper" });
    }
});
// Track download
router.post("/:id/download", auth_1.optionalAuth, async (req, res) => {
    try {
        const wallpaperRepository = data_source_1.AppDataSource.getRepository(Wallpaper_1.Wallpaper);
        const userRepository = data_source_1.AppDataSource.getRepository(User_1.User);
        const wallpaper = await wallpaperRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });
        if (!wallpaper) {
            return res.status(404).json({ error: "Wallpaper not found" });
        }
        // Increment wallpaper downloads
        await wallpaperRepository.increment({ id: wallpaper.id }, "downloads", 1);
        // If user is authenticated, track their download
        if (req.user?.id) {
            await userRepository.increment({ id: parseInt(req.user.id) }, "downloads", 1);
        }
        res.json({ downloads: wallpaper.downloads + 1 });
    }
    catch (error) {
        res.status(500).json({ error: "Failed to track download" });
    }
});
exports.default = router;
//# sourceMappingURL=wallpapers.js.map