import { Router } from "express";
import { AppDataSource } from "../data-source";
import { Category } from "../entities/Category";
import { Wallpaper } from "../entities/Wallpaper";
import { authenticate, requireAdmin, AuthRequest } from "../middleware/auth";
import { uploadToCloudinary } from "../middleware/upload";
import Parser from "rss-parser";
import axios from "axios";

const router = Router();

// Get all categories (public)
router.get("/", async (req, res) => {
    try {
        const includeInactive = req.query.includeInactive === "true";

        const categoryRepository = AppDataSource.getRepository(Category);

        const queryBuilder = categoryRepository.createQueryBuilder("category");

        if (!includeInactive) {
            queryBuilder.where("category.isActive = :isActive", { isActive: true });
        }

        const minWallpapers = parseInt(req.query.minWallpapers as string) || 0;
        if (minWallpapers > 0) {
            queryBuilder.andWhere("category.wallpaperCount >= :minWallpapers", { minWallpapers });
        }

        const categories = await queryBuilder
            .orderBy("category.name", "ASC")
            .getMany();

        res.json({
            categories: categories.map((c) => ({
                id: c.id,
                name: c.name,
                slug: c.slug,
                icon: c.icon,
                description: c.description,
                wallpaperCount: c.wallpaperCount,
                isActive: c.isActive,
                sourceUrl: c.sourceUrl,
            })),
        });
    } catch (error) {
        res.status(500).json({ error: "Failed to get categories" });
    }
});

// Get single category
router.get("/:id", async (req, res) => {
    try {
        const categoryRepository = AppDataSource.getRepository(Category);
        const category = await categoryRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });

        if (!category) {
            return res.status(404).json({ error: "Category not found" });
        }

        res.json({
            id: category.id,
            name: category.name,
            slug: category.slug,
            icon: category.icon,
            description: category.description,
            wallpaperCount: category.wallpaperCount,
            isActive: category.isActive,
            sourceUrl: category.sourceUrl,
        });
    } catch (error) {
        res.status(500).json({ error: "Failed to get category" });
    }
});

// Create category (admin only)
router.post("/", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { name, icon, description } = req.body;

        if (!name) {
            return res.status(400).json({ error: "Name is required" });
        }

        // Generate slug from name
        const slug = name
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/(^-|-$)/g, "");

        const categoryRepository = AppDataSource.getRepository(Category);

        // Check if slug already exists
        const existing = await categoryRepository.findOne({ where: { slug } });
        if (existing) {
            return res
                .status(400)
                .json({ error: "Category with this name already exists" });
        }

        const category = categoryRepository.create({
            name,
            slug,
            icon: icon || "🎨",
            description,
        });
        await categoryRepository.save(category);

        res.status(201).json({
            message: "Category created successfully",
            category: {
                id: category.id,
                name: category.name,
                slug: category.slug,
                icon: category.icon,
            },
        });
    } catch (error) {
        console.error("Create category error:", error);
        res.status(500).json({ error: "Failed to create category" });
    }
});

// Update category (admin only)
router.put("/:id", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { name, icon, description, isActive } = req.body;

        const categoryRepository = AppDataSource.getRepository(Category);
        const category = await categoryRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });

        if (!category) {
            return res.status(404).json({ error: "Category not found" });
        }

        if (name) {
            category.name = name;
            category.slug = name
                .toLowerCase()
                .replace(/[^a-z0-9]+/g, "-")
                .replace(/(^-|-$)/g, "");
        }
        if (icon) category.icon = icon;
        if (description !== undefined) category.description = description;
        if (isActive !== undefined)
            category.isActive = isActive === true || isActive === "true";

        await categoryRepository.save(category);

        res.json({
            message: "Category updated successfully",
            category: {
                id: category.id,
                name: category.name,
                slug: category.slug,
                icon: category.icon,
                isActive: category.isActive,
            },
        });
    } catch (error) {
        res.status(500).json({ error: "Failed to update category" });
    }
});

// Delete category (admin only)
router.delete("/:id", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const categoryRepository = AppDataSource.getRepository(Category);
        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);
        const categoryId = parseInt(req.params.id);
        const category = await categoryRepository.findOne({
            where: { id: categoryId },
        });

        if (!category) {
            return res.status(404).json({ error: "Category not found" });
        }

        const wallpaperCount = await wallpaperRepository.count({
            where: { categoryId },
        });

        if (wallpaperCount > 0) {
            return res.status(400).json({
                error: "This category still has wallpapers. Move them to another category before deleting it.",
            });
        }

        await categoryRepository.delete(categoryId);

        res.json({ message: "Category deleted successfully." });
    } catch (error) {
        res.status(500).json({ error: "Failed to delete category" });
    }
});

// Import Pinterest Board (admin only)
router.post("/import-pinterest", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { boardUrl } = req.body;
        if (!boardUrl) {
            return res.status(400).json({ error: "Pinterest board URL is required" });
        }

        // Example: https://www.pinterest.com/username/boardname/
        const urlMatch = boardUrl.match(/pinterest\.com\/([^\/]+)\/([^\/]+)/);
        if (!urlMatch) {
            return res.status(400).json({ error: "Invalid Pinterest board URL" });
        }

        const username = urlMatch[1];
        const boardname = urlMatch[2];
        const rssUrl = `https://www.pinterest.com/${username}/${boardname}.rss`;

        const parser = new Parser();
        let feed;
        try {
            feed = await parser.parseURL(rssUrl);
        } catch (error) {
            console.error("Failed to fetch RSS feed:", error);
            return res.status(400).json({ error: "Failed to fetch Pinterest board. Make sure it's public." });
        }

        const boardTitle = feed.title || `${username}'s ${boardname}`;

        // Find or create category
        const categoryRepository = AppDataSource.getRepository(Category);
        const slug = boardTitle.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

        let categoryDoc = await categoryRepository.findOne({ where: { slug } });
        if (!categoryDoc) {
            categoryDoc = categoryRepository.create({
                name: boardTitle.replace(/Pinterest$/, "").trim() || boardTitle,
                slug,
                icon: "📌",
                description: feed.description || `Imported from Pinterest: ${boardUrl}`,
                isActive: true,
                sourceUrl: boardUrl,
            });
            await categoryRepository.save(categoryDoc);
        }

        let importedCount = 0;
        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);

        // Process all items in the feed
        const itemsToProcess = feed.items;

        for (const item of itemsToProcess) {
            try {
                // Skip if this pin was already imported by exact sourceUrl
                const itemSourceUrl = item.link || item.guid || `${boardUrl}#${item.title || Math.random()}`;
                const existingWallpaper = await wallpaperRepository.findOne({ where: { sourceUrl: itemSourceUrl } });
                if (existingWallpaper) continue;

                // Title-based duplicate detection (mostly for old wallpapers before sourceUrl was added)
                const itemTitle = item.title || "Pinterest Selection";
                if (itemTitle !== "Pinterest Selection") {
                    const potentialDuplicate = await wallpaperRepository.findOne({
                        where: { categoryId: categoryDoc.id, title: itemTitle }
                    });

                    if (potentialDuplicate) {
                        // This title already exists in this category, strongly implying it's a duplicate.
                        if (!potentialDuplicate.sourceUrl) {
                            // Link it so it's definitively tracked next time.
                            potentialDuplicate.sourceUrl = itemSourceUrl;
                            await wallpaperRepository.save(potentialDuplicate);
                        }
                        continue;
                    }
                }

                // Extract image URL from description/content HTML
                const imgMatch = item.content?.match(/src="([^"]+)"/);
                if (!imgMatch) continue;

                let imageUrl = imgMatch[1];
                // Replace size part like 236x or 736x with originals to get high quality
                imageUrl = imageUrl.replace(/\/\d+x\//, '/originals/');

                // Fetch image buffer
                const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
                const buffer = Buffer.from(response.data);

                // Upload to cloudinary
                const { url, thumbnailUrl } = await uploadToCloudinary(buffer, "wallpapers");

                // Save to db
                const wallpaper = wallpaperRepository.create({
                    title: item.title || "Pinterest Selection",
                    imageUrl: url,
                    thumbnailUrl,
                    categoryId: categoryDoc.id,
                    tags: ["pinterest", username, boardname],
                    isWide: false,
                    isPro: false,
                    sourceUrl: itemSourceUrl,
                });
                await wallpaperRepository.save(wallpaper);
                importedCount++;
            } catch (itemError) {
                console.error("Failed to import single Pinterest item:", itemError);
                // Continue with next
            }
        }

        // Update category count
        if (importedCount > 0) {
            await categoryRepository.increment({ id: categoryDoc.id }, "wallpaperCount", importedCount);
        }

        res.json({ message: `Successfully imported ${importedCount} wallpapers from Pinterest`, importedCount });
    } catch (error) {
        console.error("Pinterest import error:", error);
        res.status(500).json({ error: "Failed to import from Pinterest" });
    }
});

// Refetch Pinterest Board (admin only)
router.post("/:id/refetch-pinterest", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const categoryRepository = AppDataSource.getRepository(Category);
        const category = await categoryRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });

        if (!category) {
            return res.status(404).json({ error: "Category not found" });
        }

        if (!category.sourceUrl || !category.sourceUrl.includes("pinterest.com")) {
            return res.status(400).json({ error: "Category is not a Pinterest imported board" });
        }

        const boardUrl = category.sourceUrl;
        const urlMatch = boardUrl.match(/pinterest\.com\/([^\/]+)\/([^\/]+)/);
        if (!urlMatch) {
            return res.status(400).json({ error: "Invalid Pinterest board URL stored in this category" });
        }

        const username = urlMatch[1];
        const boardname = urlMatch[2];
        const rssUrl = `https://www.pinterest.com/${username}/${boardname}.rss`;

        const parser = new Parser();
        let feed;
        try {
            feed = await parser.parseURL(rssUrl);
        } catch (error) {
            console.error("Failed to fetch RSS feed during refetch:", error);
            return res.status(400).json({ error: "Failed to fetch Pinterest board. Make sure it's public." });
        }

        let importedCount = 0;
        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);

        // Process all items in the feed
        const itemsToProcess = feed.items;

        for (const item of itemsToProcess) {
            try {
                // Skip if this pin was already imported
                const itemSourceUrl = item.link || item.guid || `${boardUrl}#${item.title || Math.random()}`;
                const existingWallpaper = await wallpaperRepository.findOne({ where: { sourceUrl: itemSourceUrl } });
                if (existingWallpaper) continue;

                // Title-based duplicate detection (mostly for old wallpapers before sourceUrl was added)
                const itemTitle = item.title || "Pinterest Selection";
                if (itemTitle !== "Pinterest Selection") {
                    const potentialDuplicate = await wallpaperRepository.findOne({
                        where: { categoryId: category.id, title: itemTitle }
                    });

                    if (potentialDuplicate) {
                        // This title already exists in this category, strongly implying it's a duplicate.
                        if (!potentialDuplicate.sourceUrl) {
                            // Link it so it's definitively tracked next time.
                            potentialDuplicate.sourceUrl = itemSourceUrl;
                            await wallpaperRepository.save(potentialDuplicate);
                        }
                        continue;
                    }
                }

                // Extract image URL from description/content HTML
                const imgMatch = item.content?.match(/src="([^"]+)"/);
                if (!imgMatch) continue;

                let imageUrl = imgMatch[1];
                // Replace size part like 236x or 736x with originals to get high quality
                imageUrl = imageUrl.replace(/\/\d+x\//, '/originals/');

                // Fetch image buffer
                const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
                const buffer = Buffer.from(response.data);

                // Upload to cloudinary
                const { url, thumbnailUrl } = await uploadToCloudinary(buffer, "wallpapers");

                // Save to db
                const wallpaper = wallpaperRepository.create({
                    title: item.title || "Pinterest Selection",
                    imageUrl: url,
                    thumbnailUrl,
                    categoryId: category.id,
                    tags: ["pinterest", username, boardname],
                    isWide: false,
                    isPro: false,
                    sourceUrl: itemSourceUrl,
                });
                await wallpaperRepository.save(wallpaper);
                importedCount++;
            } catch (itemError) {
                console.error("Failed to import single Pinterest item during refetch:", itemError);
                // Continue with next
            }
        }

        // Update category count
        if (importedCount > 0) {
            await categoryRepository.increment({ id: category.id }, "wallpaperCount", importedCount);
        }

        res.json({ message: `Successfully refetched ${importedCount} new wallpapers from Pinterest`, importedCount });
    } catch (error) {
        console.error("Pinterest refetch error:", error);
        res.status(500).json({ error: "Failed to refetch from Pinterest" });
    }
});

export default router;
