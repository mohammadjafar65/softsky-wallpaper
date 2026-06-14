import { Router } from "express";
import { AppDataSource } from "../data-source";
import { Wallpaper } from "../entities/Wallpaper";
import { User } from "../entities/User";
import { Category } from "../entities/Category";
import { Pack } from "../entities/Pack";
import {
    authenticate,
    requireAdmin,
    AuthRequest,
    optionalAuth,
} from "../middleware/auth";
import { upload, uploadToCloudinary, deleteFromCloudinary } from "../middleware/upload";
import { Like } from "typeorm";

const router = Router();

// Get all wallpapers (public, with pagination)
router.get("/", optionalAuth, async (req: AuthRequest, res) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;
        const category = req.query.category as string;
        const isPro = req.query.isPro === "true";
        const isWide = req.query.isWide === "true";

        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);
        const categoryRepository = AppDataSource.getRepository(Category);

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
                packId: parseInt(req.query.packId as string),
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
    } catch (error) {
        console.error("Get wallpapers error:", error);
        res.status(500).json({ error: "Failed to get wallpapers" });
    }
});

// Search wallpapers
router.get("/search", async (req, res) => {
    try {
        const query = req.query.q as string;
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;

        if (!query) {
            return res.status(400).json({ error: "Search query is required" });
        }

        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);

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
    } catch (error) {
        console.error("Search error:", error);
        res.status(500).json({ error: "Search failed" });
    }
});

// Get single wallpaper
router.get("/:id", async (req, res) => {
    try {
        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);

        const wallpaper = await wallpaperRepository.findOne({
            where: { id: parseInt(req.params.id) },
            relations: ["category"],
        });

        if (!wallpaper) {
            return res.status(404).json({ error: "Wallpaper not found" });
        }

        // Increment views
        await wallpaperRepository.increment(
            { id: wallpaper.id },
            "views",
            1
        );

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
    } catch (error) {
        res.status(500).json({ error: "Failed to get wallpaper" });
    }
});

// Create wallpaper (admin only)
router.post(
    "/",
    authenticate,
    requireAdmin,
    upload.single("image"),
    async (req: AuthRequest, res) => {
        try {
            const { title, category, categoryName, categoryEmoji, tags, isWide, isPro, packId } = req.body;
            console.log("Create wallpaper request body:", { title, category, categoryName, categoryEmoji, tags, isWide, isPro, packId });

            if (!req.file) {
                return res.status(400).json({ error: "Image is required" });
            }

            if (!title || (!category && !categoryName)) {
                return res
                    .status(400)
                    .json({ error: "Title and category are required" });
            }

            // Upload to Cloudinary
            const { url, thumbnailUrl } = await uploadToCloudinary(
                req.file.buffer,
                isWide === "true" ? "wide" : "wallpapers"
            );

            const categoryRepository = AppDataSource.getRepository(Category);
            const wallpaperRepository = AppDataSource.getRepository(Wallpaper);
            const packRepository = AppDataSource.getRepository(Pack);

            let categoryDoc;
            let categoryId: number;

            if (categoryName) {
                // Find or Create Category
                const slug = categoryName
                    .toLowerCase()
                    .replace(/[^a-z0-9]+/g, "-")
                    .replace(/(^-|-$)/g, "");

                categoryDoc = await categoryRepository.findOne({ where: { slug } });

                if (!categoryDoc) {
                    categoryDoc = categoryRepository.create({
                        name: categoryName,
                        slug,
                        icon: categoryEmoji || "🎨",
                        description: `Wallpapers for ${categoryName}`,
                        isActive: true,
                    });
                    await categoryRepository.save(categoryDoc);
                }
                categoryId = categoryDoc.id;
            } else {
                categoryId = parseInt(category);
                if (isNaN(categoryId)) {
                    return res.status(400).json({ error: "Invalid category ID" });
                }

                // Verify category exists
                categoryDoc = await categoryRepository.findOne({
                    where: { id: categoryId },
                });
                if (!categoryDoc) {
                    return res.status(400).json({ error: "Invalid category" });
                }
            }

            let parsedPackId: number | undefined = undefined;
            if (packId && packId !== "" && packId !== "null" && packId !== "undefined") {
                parsedPackId = parseInt(packId);
                if (isNaN(parsedPackId)) {
                    parsedPackId = undefined;
                }
            }

            const wallpaper = wallpaperRepository.create({
                title,
                imageUrl: url,
                thumbnailUrl,
                categoryId: categoryId,
                tags: tags ? tags.split(",").map((t: string) => t.trim()) : [],
                isWide: isWide === "true",
                isPro: isPro === "true",
                packId: parsedPackId,
            });
            await wallpaperRepository.save(wallpaper);

            // Update category wallpaper count
            await categoryRepository.increment(
                { id: categoryDoc.id },
                "wallpaperCount",
                1
            );

            // Update pack wallpaper count if assigned to a pack
            if (parsedPackId) {
                await packRepository.increment(
                    { id: parsedPackId },
                    "wallpaperCount",
                    1
                );
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
        } catch (error: any) {
            console.error("Create wallpaper error:", error);
            // Enhanced error logging
            if (error.sqlMessage) console.error("SQL Error:", error.sqlMessage);
            if (error.code) console.error("Error Code:", error.code);

            res.status(500).json({
                error: "Failed to create wallpaper",
                details: error.message || "Unknown error",
                sqlMessage: process.env.NODE_ENV === 'development' ? error.sqlMessage : undefined,
                stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
            });
        }
    }
);

// Bulk reassign wallpapers to another category (admin only)
router.put("/bulk-reassign", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const wallpaperIds = Array.isArray(req.body.wallpaperIds)
            ? req.body.wallpaperIds
                .map((id: unknown) => parseInt(String(id), 10))
                .filter((id: number) => !isNaN(id))
            : [];
        const targetCategoryId = parseInt(String(req.body.targetCategoryId), 10);

        if (wallpaperIds.length === 0) {
            return res.status(400).json({ error: "At least one wallpaper ID is required" });
        }

        if (isNaN(targetCategoryId)) {
            return res.status(400).json({ error: "A valid target category is required" });
        }

        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);
        const categoryRepository = AppDataSource.getRepository(Category);

        const targetCategory = await categoryRepository.findOne({
            where: { id: targetCategoryId },
        });

        if (!targetCategory) {
            return res.status(404).json({ error: "Target category not found" });
        }

        const wallpapers = await wallpaperRepository.find({
            where: wallpaperIds.map((id: number) => ({ id })),
        });

        if (wallpapers.length === 0) {
            return res.status(404).json({ error: "Wallpapers not found" });
        }

        const moveCounts = new Map<number, number>();
        let movedCount = 0;

        for (const wallpaper of wallpapers) {
            if (wallpaper.categoryId === targetCategoryId) {
                continue;
            }

            moveCounts.set(wallpaper.categoryId, (moveCounts.get(wallpaper.categoryId) || 0) + 1);
            wallpaper.categoryId = targetCategoryId;
            movedCount++;
        }

        if (movedCount === 0) {
            return res.json({
                message: "Wallpapers are already in the selected category",
                movedCount: 0,
            });
        }

        await wallpaperRepository.save(wallpapers);

        for (const [sourceCategoryId, count] of moveCounts.entries()) {
            await categoryRepository.decrement({ id: sourceCategoryId }, "wallpaperCount", count);
        }
        await categoryRepository.increment({ id: targetCategoryId }, "wallpaperCount", movedCount);

        res.json({
            message: "Wallpapers reassigned successfully",
            movedCount,
            targetCategory: {
                id: targetCategory.id,
                name: targetCategory.name,
                slug: targetCategory.slug,
            },
        });
    } catch (error) {
        console.error("Bulk reassign wallpapers error:", error);
        res.status(500).json({ error: "Failed to reassign wallpapers" });
    }
});

// Update wallpaper (admin only)
router.put("/:id", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const { title, category, tags, isWide, isPro, packId } = req.body;

        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);
        const categoryRepository = AppDataSource.getRepository(Category);
        const packRepository = AppDataSource.getRepository(Pack);

        const wallpaper = await wallpaperRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });

        if (!wallpaper) {
            return res.status(404).json({ error: "Wallpaper not found" });
        }

        if (title) wallpaper.title = title;
        if (category) {
            const nextCategoryId = parseInt(category);
            if (isNaN(nextCategoryId)) {
                return res.status(400).json({ error: "Invalid category ID" });
            }

            if (wallpaper.categoryId !== nextCategoryId) {
                const nextCategory = await categoryRepository.findOne({
                    where: { id: nextCategoryId },
                });

                if (!nextCategory) {
                    return res.status(404).json({ error: "Category not found" });
                }

                await categoryRepository.decrement(
                    { id: wallpaper.categoryId },
                    "wallpaperCount",
                    1
                );
                await categoryRepository.increment(
                    { id: nextCategoryId },
                    "wallpaperCount",
                    1
                );
                wallpaper.categoryId = nextCategoryId;
            }
        }
        if (tags) wallpaper.tags = tags.split(",").map((t: string) => t.trim());
        if (isWide !== undefined)
            wallpaper.isWide = isWide === true || isWide === "true";
        if (isPro !== undefined)
            wallpaper.isPro = isPro === true || isPro === "true";

        // Handle pack assignment changes
        if (packId !== undefined) {
            const oldPackId = wallpaper.packId;
            let newPackId: number | undefined = undefined;

            if (packId !== "" && packId !== "null" && packId !== "undefined") {
                const parsed = parseInt(packId);
                newPackId = isNaN(parsed) ? undefined : parsed;
            }

            // If pack changed, update counts
            if (oldPackId !== newPackId) {
                // Decrement old pack count
                if (oldPackId) {
                    await packRepository.decrement(
                        { id: oldPackId },
                        "wallpaperCount",
                        1
                    );
                }
                // Increment new pack count
                if (newPackId) {
                    await packRepository.increment(
                        { id: newPackId },
                        "wallpaperCount",
                        1
                    );
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
    } catch (error) {
        res.status(500).json({ error: "Failed to update wallpaper" });
    }
});

// Delete wallpaper (admin only)
router.delete("/:id", authenticate, requireAdmin, async (req: AuthRequest, res) => {
    try {
        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);
        const categoryRepository = AppDataSource.getRepository(Category);
        const packRepository = AppDataSource.getRepository(Pack);

        const wallpaper = await wallpaperRepository.findOne({
            where: { id: parseInt(req.params.id) },
        });

        if (!wallpaper) {
            return res.status(404).json({ error: "Wallpaper not found" });
        }

        // Update category count
        await categoryRepository.decrement(
            { id: wallpaper.categoryId },
            "wallpaperCount",
            1
        );

        // Update pack count if wallpaper was in a pack
        if (wallpaper.packId) {
            await packRepository.decrement(
                { id: wallpaper.packId },
                "wallpaperCount",
                1
            );
        }

        await wallpaperRepository.delete(parseInt(req.params.id));

        // Delete from Cloudinary (extract public_id from the URL)
        // Cloudinary URLs follow: .../upload/vXXXXX/folder/filename.ext
        try {
            const urlParts = wallpaper.imageUrl.split("/upload/");
            if (urlParts.length === 2) {
                // Remove version segment (vXXXXXX/) if present, then strip extension
                const pathWithoutVersion = urlParts[1].replace(/^v\d+\//, "");
                const publicId = pathWithoutVersion.replace(/\.[^.]+$/, "");
                await deleteFromCloudinary(publicId);
                console.log(`Deleted Cloudinary image: ${publicId}`);
            }
        } catch (cloudinaryError) {
            // Log but don't fail the request if Cloudinary cleanup fails
            console.error("Failed to delete Cloudinary image (non-fatal):", cloudinaryError);
        }

        res.json({ message: "Wallpaper deleted successfully" });
    } catch (error) {
        res.status(500).json({ error: "Failed to delete wallpaper" });
    }
});

// Track download
router.post("/:id/download", optionalAuth, async (req: AuthRequest, res) => {
    try {
        const wallpaperId = parseInt(req.params.id, 10);
        if (isNaN(wallpaperId)) {
            return res.status(400).json({ error: "Invalid wallpaper ID" });
        }

        const wallpaperRepository = AppDataSource.getRepository(Wallpaper);
        const userRepository = AppDataSource.getRepository(User);

        const wallpaper = await wallpaperRepository.findOne({
            where: { id: wallpaperId },
        });

        if (!wallpaper) {
            return res.status(404).json({ error: "Wallpaper not found" });
        }

        // Increment wallpaper downloads
        await wallpaperRepository.increment({ id: wallpaper.id }, "downloads", 1);

        // If user is authenticated, track their download
        let userDownloads: number | undefined;
        if (req.user?.id) {
            const userId = parseInt(req.user.id, 10);
            if (!isNaN(userId)) {
                await userRepository.increment({ id: userId }, "downloads", 1);
                const user = await userRepository.findOne({ where: { id: userId } });
                userDownloads = user?.downloads;
            }
        }

        res.json({
            success: true,
            wallpaperId: wallpaper.id,
            downloads: wallpaper.downloads + 1,
            userDownloads,
        });
    } catch (error) {
        console.error("Track download error:", error);
        res.status(500).json({ error: "Failed to track download" });
    }
});

export default router;
