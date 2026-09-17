import { Router, Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { CommunityPost } from "../entities/CommunityPost";
import { CommunityLike } from "../entities/CommunityLike";
import { CommunityComment } from "../entities/CommunityComment";
import { CommunitySave } from "../entities/CommunitySave";
import { Follow } from "../entities/Follow";
import { PostReport } from "../entities/PostReport";
import { User } from "../entities/User";
import { authenticate, optionalAuth, requireAdmin, AuthRequest } from "../middleware/auth";

const router = Router();

// ─── Helper: serialize a post with viewer context ────────────────────────────
async function serializePost(post: CommunityPost, viewerId: number | null) {
    const likeRepo = AppDataSource.getRepository(CommunityLike);
    const saveRepo = AppDataSource.getRepository(CommunitySave);
    const followRepo = AppDataSource.getRepository(Follow);

    const safeViewerId = viewerId ? Number(viewerId) : null;

    const [isLiked, isSaved, isFollowing] = await Promise.all([
        safeViewerId
            ? likeRepo.findOne({ where: { userId: safeViewerId, postId: post.id } })
            : null,
        safeViewerId
            ? saveRepo.findOne({ where: { userId: safeViewerId, postId: post.id } })
            : null,
        safeViewerId && post.author
            ? followRepo.findOne({ where: { followerId: safeViewerId, followingId: post.userId } })
            : null,
    ]);

    const authorUsername = post.author?.username || (post.author?.displayName
        ? post.author.displayName.toLowerCase().replace(/[^a-z0-9_]/g, '')
        : 'user');

    return {
        id: post.id,
        imageUrl: post.imageUrl,
        thumbnailUrl: post.thumbnailUrl,
        title: post.title,
        description: post.description,
        width: post.width,
        height: post.height,
        likesCount: post.likesCount || 0,
        commentsCount: post.commentsCount || 0,
        savesCount: post.savesCount || 0,
        downloadsCount: post.downloadsCount || 0,
        isLiked: !!isLiked,
        isSaved: !!isSaved,
        isApproved: post.isApproved ?? false,
        isReported: post.isReported ?? false,
        createdAt: post.createdAt,
        author: post.author
            ? {
                  id: post.author.id,
                  displayName: post.author.displayName || "Community Member",
                  photoUrl: post.author.photoUrl,
                  username: authorUsername,
                  bio: post.author.bio,
                  followersCount: post.author.followersCount || 0,
                  followingCount: post.author.followingCount || 0,
                  postsCount: post.author.postsCount || 0,
                  isFollowing: !!isFollowing,
              }
            : null,
    };
}

import { upload, uploadToCloudinary } from "../middleware/upload";
import path from "path";
import fs from "fs";

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/posts — create a new post (supports multipart file or json)
// ─────────────────────────────────────────────────────────────────────────────
router.post(
    "/posts",
    authenticate,
    upload.fields([
        { name: "image", maxCount: 1 },
        { name: "thumbnail", maxCount: 1 },
    ]),
    async (req: Request, res: Response) => {
        try {
            const userId = (req as any).user?.id;
            let { imageUrl, thumbnailUrl, title, description, width, height } = req.body;

            const files = req.files as { [fieldname: string]: Express.Multer.File[] } | undefined;
            const imageFile = files?.image?.[0];

            if (imageFile) {
                // Try Cloudinary first if configured
                if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY) {
                    try {
                        const uploaded = await uploadToCloudinary(imageFile.buffer, "community");
                        imageUrl = uploaded.url;
                        thumbnailUrl = uploaded.thumbnailUrl;
                    } catch (cloudErr) {
                        console.error("Cloudinary failed, falling back to local file storage:", cloudErr);
                    }
                }

                // If Cloudinary didn't provide an imageUrl (or failed), save locally on hosting server
                if (!imageUrl) {
                    const ext = path.extname(imageFile.originalname) || ".jpg";
                    const filename = `community_${Date.now()}_${Math.random().toString(36).substring(2, 9)}${ext}`;
                    const targetPath = path.join(process.cwd(), "uploads", "community", filename);
                    fs.writeFileSync(targetPath, imageFile.buffer);

                    const protocol = req.protocol;
                    const host = req.get("host") || "softskyapi.softsky.studio";
                    imageUrl = `${protocol}://${host}/uploads/community/${filename}`;
                    thumbnailUrl = imageUrl;
                }
            }

            if (!imageUrl) {
                return res.status(400).json({ error: "Image file or imageUrl is required" });
            }

            const postRepo = AppDataSource.getRepository(CommunityPost);
            const userRepo = AppDataSource.getRepository(User);

            const post = postRepo.create({
                userId,
                imageUrl,
                thumbnailUrl: thumbnailUrl || imageUrl,
                title,
                description,
                width: width ? parseInt(width) : undefined,
                height: height ? parseInt(height) : undefined,
                isApproved: false,
                isReported: false,
            });
            await postRepo.save(post);

            // Increment user posts count
            await userRepo.increment({ id: userId }, "postsCount", 1);

            // Reload with author
            const saved = await postRepo.findOne({
                where: { id: post.id },
                relations: ["author"],
            });

            return res.status(201).json({ post: await serializePost(saved!, userId) });
        } catch (err: any) {
            console.error("POST /community/posts error:", err);
            return res.status(500).json({ error: err.message || "Internal server error" });
        }
    }
);

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/feed — paginated feed (following + own posts)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/feed", optionalAuth, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id ? parseInt((req as any).user.id, 10) : null;
        const postRepo = AppDataSource.getRepository(CommunityPost);
        const totalCount = await postRepo.count({ where: { isApproved: true } });
        if (!userId) {
            return res.json({ posts: [], page: 1, hasMore: false, totalCount });
        }
        const page = parseInt((req.query.page as string) || "1", 10);
        const limit = parseInt((req.query.limit as string) || "20", 10);
        const skip = (page - 1) * limit;

        const followRepo = AppDataSource.getRepository(Follow);

        // Get IDs of people the user follows
        const follows = await followRepo.find({ where: { followerId: userId } });
        const followingIds = follows.map((f) => f.followingId);
        // Include own posts
        const feedIds = [...followingIds, userId];

        let posts: CommunityPost[];
        if (feedIds.length === 0) {
            posts = [];
        } else {
            posts = await postRepo
                .createQueryBuilder("post")
                .leftJoinAndSelect("post.author", "author")
                .where("post.userId IN (:...ids) AND post.isApproved = true", { ids: feedIds })
                .orderBy("post.createdAt", "DESC")
                .skip(skip)
                .take(limit)
                .getMany();
        }

        const serialized = await Promise.all(posts.map((p) => serializePost(p, userId)));
        return res.json({ posts: serialized, page, hasMore: posts.length === limit, totalCount });
    } catch (err: any) {
        console.error("GET /community/feed error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/trending — top liked posts from last 7 days
// ─────────────────────────────────────────────────────────────────────────────
router.get("/trending", optionalAuth, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id ? parseInt((req as any).user.id, 10) : null;
        const page = parseInt((req.query.page as string) || "1", 10);
        const limit = parseInt((req.query.limit as string) || "20", 10);
        const skip = (page - 1) * limit;

        const postRepo = AppDataSource.getRepository(CommunityPost);
        const totalCount = await postRepo.count({ where: { isApproved: true } });
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const posts = await postRepo
            .createQueryBuilder("post")
            .leftJoinAndSelect("post.author", "author")
            .where("post.createdAt >= :since AND post.isApproved = true", { since: sevenDaysAgo })
            .orderBy("post.likesCount", "DESC")
            .addOrderBy("post.createdAt", "DESC")
            .skip(skip)
            .take(limit)
            .getMany();

        const serialized = await Promise.all(posts.map((p) => serializePost(p, userId)));
        return res.json({ posts: serialized, page, hasMore: posts.length === limit, totalCount });
    } catch (err: any) {
        console.error("GET /community/trending error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/posts/:id — single post
// ─────────────────────────────────────────────────────────────────────────────
router.get("/posts/:id", optionalAuth, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id ? parseInt((req as any).user.id, 10) : null;
        const postId = parseInt(req.params.id, 10);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const post = await postRepo.findOne({
            where: { id: postId },
            relations: ["author"],
        });

        if (!post) return res.status(404).json({ error: "Post not found" });

        const userRole = (req as any).user?.role;
        if (!post.isApproved && post.userId !== userId && userRole !== "admin") {
            return res.status(404).json({ error: "Post not found" });
        }

        return res.json({ post: await serializePost(post, userId) });
    } catch (err: any) {
        console.error("GET /community/posts/:id error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/community/posts/:id — delete own post
// ─────────────────────────────────────────────────────────────────────────────
router.delete("/posts/:id", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id;
        const userRole = (req as any).user?.role;
        const postId = parseInt(req.params.id);
        const postRepo = AppDataSource.getRepository(CommunityPost);
        const userRepo = AppDataSource.getRepository(User);

        const post = await postRepo.findOne({ where: { id: postId } });
        if (!post) return res.status(404).json({ error: "Post not found" });
        if (post.userId !== userId && userRole !== "admin") return res.status(403).json({ error: "Forbidden" });

        await postRepo.delete(postId);
        await userRepo.decrement({ id: post.userId }, "postsCount", 1);

        return res.json({ success: true });
    } catch (err: any) {
        console.error("DELETE /community/posts/:id error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/posts/:id/like — toggle like
// ─────────────────────────────────────────────────────────────────────────────
router.post("/posts/:id/like", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = parseInt((req as any).user?.id, 10);
        const postId = parseInt(req.params.id, 10);
        if (isNaN(userId) || isNaN(postId)) {
            return res.status(400).json({ error: "Invalid user or post ID" });
        }

        const likeRepo = AppDataSource.getRepository(CommunityLike);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const existing = await likeRepo.findOne({ where: { userId, postId } });

        if (existing) {
            await likeRepo.delete({ userId, postId });
            await postRepo
                .createQueryBuilder()
                .update(CommunityPost)
                .set({ likesCount: () => "GREATEST(likes_count - 1, 0)" })
                .where("id = :id", { id: postId })
                .execute();
            return res.json({ liked: false });
        } else {
            await likeRepo.save(likeRepo.create({ userId, postId }));
            await postRepo.increment({ id: postId }, "likesCount", 1);
            return res.json({ liked: true });
        }
    } catch (err: any) {
        console.error("POST /community/posts/:id/like error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/posts/:id/comment — add comment
// ─────────────────────────────────────────────────────────────────────────────
router.post("/posts/:id/comment", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = parseInt((req as any).user?.id, 10);
        const postId = parseInt(req.params.id, 10);
        const { content } = req.body;

        if (isNaN(userId) || isNaN(postId)) {
            return res.status(400).json({ error: "Invalid user or post ID" });
        }

        if (!content || content.trim().length === 0) {
            return res.status(400).json({ error: "Comment content is required" });
        }
        if (content.length > 1000) {
            return res.status(400).json({ error: "Comment too long (max 1000 chars)" });
        }

        const commentRepo = AppDataSource.getRepository(CommunityComment);
        const postRepo = AppDataSource.getRepository(CommunityPost);
        const userRepo = AppDataSource.getRepository(User);

        const comment = commentRepo.create({ userId, postId, content: content.trim() });
        await commentRepo.save(comment);
        await postRepo.increment({ id: postId }, "commentsCount", 1);

        const author = await userRepo.findOne({ where: { id: userId } });
        const authorUsername = author?.username || (author?.displayName
            ? author.displayName.toLowerCase().replace(/[^a-z0-9_]/g, '')
            : 'user');

        return res.status(201).json({
            comment: {
                id: comment.id,
                content: comment.content,
                createdAt: comment.createdAt,
                author: {
                    id: author ? author.id : userId,
                    displayName: author?.displayName || "Community Member",
                    photoUrl: author?.photoUrl || null,
                    username: authorUsername,
                },
            },
        });
    } catch (err: any) {
        console.error("POST /community/posts/:id/comment error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/posts/:id/comments — paginated comments (public/optionalAuth)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/posts/:id/comments", optionalAuth, async (req: Request, res: Response) => {
    try {
        const postId = parseInt(req.params.id, 10);
        if (isNaN(postId)) {
            return res.status(400).json({ error: "Invalid post ID" });
        }
        const page = parseInt((req.query.page as string) || "1", 10);
        const limit = parseInt((req.query.limit as string) || "20", 10);
        const skip = (page - 1) * limit;

        const commentRepo = AppDataSource.getRepository(CommunityComment);
        const comments = await commentRepo
            .createQueryBuilder("comment")
            .leftJoinAndSelect("comment.author", "author")
            .where("comment.postId = :postId", { postId })
            .orderBy("comment.createdAt", "DESC")
            .skip(skip)
            .take(limit)
            .getMany();

        return res.json({
            comments: comments.map((c) => ({
                id: c.id,
                content: c.content,
                createdAt: c.createdAt,
                author: {
                    id: c.author ? c.author.id : c.userId,
                    displayName: c.author?.displayName || "Community Member",
                    photoUrl: c.author?.photoUrl || null,
                    username: c.author?.username || (c.author?.displayName
                        ? c.author.displayName.toLowerCase().replace(/[^a-z0-9_]/g, '')
                        : 'user'),
                },
            })),
            page,
            hasMore: comments.length === limit,
        });
    } catch (err: any) {
        console.error("GET /community/posts/:id/comments error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/posts/:id/save — toggle save
// ─────────────────────────────────────────────────────────────────────────────
router.post("/posts/:id/save", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = parseInt((req as any).user?.id, 10);
        const postId = parseInt(req.params.id, 10);
        if (isNaN(userId) || isNaN(postId)) {
            return res.status(400).json({ error: "Invalid user or post ID" });
        }

        const saveRepo = AppDataSource.getRepository(CommunitySave);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const existing = await saveRepo.findOne({ where: { userId, postId } });

        if (existing) {
            await saveRepo.delete({ userId, postId });
            await postRepo
                .createQueryBuilder()
                .update(CommunityPost)
                .set({ savesCount: () => "GREATEST(saves_count - 1, 0)" })
                .where("id = :id", { id: postId })
                .execute();
            return res.json({ saved: false });
        } else {
            await saveRepo.save(saveRepo.create({ userId, postId }));
            await postRepo.increment({ id: postId }, "savesCount", 1);
            return res.json({ saved: true });
        }
    } catch (err: any) {
        console.error("POST /community/posts/:id/save error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/saved — current user's saved posts
// ─────────────────────────────────────────────────────────────────────────────
router.get("/saved", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = parseInt((req as any).user?.id, 10);
        if (isNaN(userId)) return res.json({ posts: [], page: 1, hasMore: false });

        const page = parseInt((req.query.page as string) || "1", 10);
        const limit = parseInt((req.query.limit as string) || "20", 10);
        const skip = (page - 1) * limit;

        const saveRepo = AppDataSource.getRepository(CommunitySave);
        const saves = await saveRepo
            .createQueryBuilder("save")
            .leftJoinAndSelect("save.post", "post")
            .leftJoinAndSelect("post.author", "author")
            .where("save.userId = :userId AND post.isApproved = true", { userId })
            .orderBy("save.createdAt", "DESC")
            .skip(skip)
            .take(limit)
            .getMany();

        const serialized = await Promise.all(
            saves.map((s) => serializePost(s.post, userId))
        );
        return res.json({ posts: serialized, page, hasMore: saves.length === limit });
    } catch (err: any) {
        console.error("GET /community/saved error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/posts/:id/download — track download
// ─────────────────────────────────────────────────────────────────────────────
router.post("/posts/:id/download", optionalAuth, async (req: Request, res: Response) => {
    try {
        const postId = parseInt(req.params.id, 10);
        if (isNaN(postId)) {
            return res.status(400).json({ error: "Invalid post ID" });
        }

        const postRepo = AppDataSource.getRepository(CommunityPost);
        const post = await postRepo.findOne({ where: { id: postId } });
        if (!post) return res.status(404).json({ error: "Post not found" });

        await postRepo.increment({ id: postId }, "downloadsCount", 1);
        const newDownloads = (post.downloadsCount || 0) + 1;
        return res.json({ success: true, downloads: newDownloads });
    } catch (err: any) {
        console.error("POST /community/posts/:id/download error:", err);
        return res.status(500).json({ error: "Failed to track download" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/posts/:id/report — report a post
// ─────────────────────────────────────────────────────────────────────────────
router.post("/posts/:id/report", authenticate, async (req: Request, res: Response) => {
    try {
        const reporterId = parseInt((req as any).user?.id, 10);
        const postId = parseInt(req.params.id, 10);
        const { reason } = req.body;

        if (isNaN(reporterId) || isNaN(postId)) {
            return res.status(400).json({ error: "Invalid reporter or post ID" });
        }

        const validReasons = ["spam", "nudity", "copyright", "other"];
        if (!validReasons.includes(reason)) {
            return res.status(400).json({ error: "Invalid report reason" });
        }

        const reportRepo = AppDataSource.getRepository(PostReport);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        // Check for duplicate report
        const existing = await reportRepo.findOne({ where: { reporterId, postId } });
        if (existing) {
            return res.status(409).json({ error: "You have already reported this post" });
        }

        const report = reportRepo.create({ reporterId, postId, reason });
        await reportRepo.save(report);

        // Mark post as reported
        await postRepo.update(postId, { isReported: true });

        return res.json({ success: true });
    } catch (err: any) {
        console.error("POST /community/posts/:id/report error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/follow/:userId — follow a user
// ─────────────────────────────────────────────────────────────────────────────
router.post("/follow/:userId", authenticate, async (req: Request, res: Response) => {
    try {
        const followerId = parseInt((req as any).user?.id, 10);
        const followingId = parseInt(req.params.userId, 10);

        if (isNaN(followerId) || isNaN(followingId)) {
            return res.status(400).json({ error: "Invalid IDs" });
        }

        if (followerId === followingId) {
            return res.status(400).json({ error: "Cannot follow yourself" });
        }

        const followRepo = AppDataSource.getRepository(Follow);
        const userRepo = AppDataSource.getRepository(User);

        const existing = await followRepo.findOne({ where: { followerId, followingId } });
        if (existing) {
            return res.json({ following: true, message: "Already following" });
        }

        await followRepo.save(followRepo.create({ followerId, followingId }));
        await userRepo.increment({ id: followerId }, "followingCount", 1);
        await userRepo.increment({ id: followingId }, "followersCount", 1);

        return res.json({ following: true });
    } catch (err: any) {
        console.error("POST /community/follow/:userId error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/community/follow/:userId — unfollow a user
// ─────────────────────────────────────────────────────────────────────────────
router.delete("/follow/:userId", authenticate, async (req: Request, res: Response) => {
    try {
        const followerId = parseInt((req as any).user?.id, 10);
        const followingId = parseInt(req.params.userId, 10);

        if (isNaN(followerId) || isNaN(followingId)) {
            return res.status(400).json({ error: "Invalid IDs" });
        }

        const followRepo = AppDataSource.getRepository(Follow);
        const userRepo = AppDataSource.getRepository(User);

        const existing = await followRepo.findOne({ where: { followerId, followingId } });
        if (!existing) {
            return res.json({ following: false, message: "Not following" });
        }

        await followRepo.delete({ followerId, followingId });
        await userRepo
            .createQueryBuilder()
            .update(User)
            .set({ followingCount: () => "GREATEST(following_count - 1, 0)" })
            .where("id = :id", { id: followerId })
            .execute();
        await userRepo
            .createQueryBuilder()
            .update(User)
            .set({ followersCount: () => "GREATEST(followers_count - 1, 0)" })
            .where("id = :id", { id: followingId })
            .execute();

        return res.json({ following: false });
    } catch (err: any) {
        console.error("DELETE /community/follow/:userId error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/users/:userId — public profile
// ─────────────────────────────────────────────────────────────────────────────
router.get("/users/:userId", optionalAuth, async (req: Request, res: Response) => {
    try {
        const viewerId = (req as any).user?.id ? parseInt((req as any).user.id, 10) : null;
        const targetId = parseInt(req.params.userId, 10);
        if (isNaN(targetId)) return res.status(400).json({ error: "Invalid user ID" });

        const userRepo = AppDataSource.getRepository(User);
        const followRepo = AppDataSource.getRepository(Follow);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const user = await userRepo.findOne({ where: { id: targetId, isActive: true } });
        if (!user) return res.status(404).json({ error: "User not found" });

        const [isFollowing, totalDownloadsResult] = await Promise.all([
            viewerId
                ? followRepo.findOne({ where: { followerId: viewerId, followingId: targetId } })
                : null,
            postRepo
                .createQueryBuilder("post")
                .select("COALESCE(SUM(post.downloadsCount), 0)", "totalDownloads")
                .where("post.userId = :userId AND post.isApproved = true", { userId: targetId })
                .getRawOne(),
        ]);

        const totalDownloads = parseInt(totalDownloadsResult?.totalDownloads || "0", 10);
        const authorUsername = user.username || (user.displayName
            ? user.displayName.toLowerCase().replace(/[^a-z0-9_]/g, '')
            : 'user');

        return res.json({
            user: {
                id: user.id,
                displayName: user.displayName || "Community Member",
                photoUrl: user.photoUrl,
                username: authorUsername,
                bio: user.bio,
                followersCount: user.followersCount || 0,
                followingCount: user.followingCount || 0,
                postsCount: user.postsCount || 0,
                totalDownloads,
                isFollowing: !!isFollowing,
            },
        });
    } catch (err: any) {
        console.error("GET /community/users/:userId error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/users/:userId/posts — user's posts
// ─────────────────────────────────────────────────────────────────────────────
router.get("/users/:userId/posts", optionalAuth, async (req: Request, res: Response) => {
    try {
        const viewerId = (req as any).user?.id ? parseInt((req as any).user.id, 10) : null;
        const targetId = parseInt(req.params.userId, 10);
        if (isNaN(targetId)) return res.status(400).json({ error: "Invalid user ID" });

        const page = parseInt((req.query.page as string) || "1", 10);
        const limit = parseInt((req.query.limit as string) || "20", 10);
        const skip = (page - 1) * limit;

        const postRepo = AppDataSource.getRepository(CommunityPost);
        let qb = postRepo
            .createQueryBuilder("post")
            .leftJoinAndSelect("post.author", "author")
            .where("post.userId = :userId", { userId: targetId })
            .orderBy("post.createdAt", "DESC");

        if (viewerId !== targetId) {
            qb = qb.andWhere("post.isApproved = true");
        }

        const posts = await qb
            .skip(skip)
            .take(limit)
            .getMany();

        const serialized = await Promise.all(posts.map((p) => serializePost(p, viewerId)));
        return res.json({ posts: serialized, page, hasMore: posts.length === limit });
    } catch (err: any) {
        console.error("GET /community/users/:userId/posts error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/users/:userId/followers
// ─────────────────────────────────────────────────────────────────────────────
router.get("/users/:userId/followers", optionalAuth, async (req: Request, res: Response) => {
    try {
        const targetId = parseInt(req.params.userId, 10);
        if (isNaN(targetId)) return res.status(400).json({ error: "Invalid user ID" });

        const page = parseInt((req.query.page as string) || "1", 10);
        const limit = parseInt((req.query.limit as string) || "30", 10);
        const skip = (page - 1) * limit;

        const followRepo = AppDataSource.getRepository(Follow);
        const follows = await followRepo
            .createQueryBuilder("follow")
            .leftJoinAndSelect("follow.follower", "follower")
            .where("follow.followingId = :id", { id: targetId })
            .orderBy("follow.createdAt", "DESC")
            .skip(skip)
            .take(limit)
            .getMany();

        return res.json({
            users: follows.map((f) => ({
                id: f.follower.id,
                displayName: f.follower.displayName,
                photoUrl: f.follower.photoUrl,
                username: f.follower.username,
            })),
            page,
            hasMore: follows.length === limit,
        });
    } catch (err: any) {
        console.error("GET /community/users/:userId/followers error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/users/:userId/following
// ─────────────────────────────────────────────────────────────────────────────
router.get("/users/:userId/following", optionalAuth, async (req: Request, res: Response) => {
    try {
        const targetId = parseInt(req.params.userId);
        const page = parseInt((req.query.page as string) || "1");
        const limit = parseInt((req.query.limit as string) || "30");
        const skip = (page - 1) * limit;

        const followRepo = AppDataSource.getRepository(Follow);
        const follows = await followRepo
            .createQueryBuilder("follow")
            .leftJoinAndSelect("follow.following", "following")
            .where("follow.followerId = :id", { id: targetId })
            .orderBy("follow.createdAt", "DESC")
            .skip(skip)
            .take(limit)
            .getMany();

        return res.json({
            users: follows.map((f) => ({
                id: f.following.id,
                displayName: f.following.displayName,
                photoUrl: f.following.photoUrl,
                username: f.following.username,
            })),
            page,
            hasMore: follows.length === limit,
        });
    } catch (err: any) {
        console.error("GET /community/users/:userId/following error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/me/posts — current user's own posts
// ─────────────────────────────────────────────────────────────────────────────
router.get("/me/posts", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id;
        const page = parseInt((req.query.page as string) || "1");
        const limit = parseInt((req.query.limit as string) || "20");
        const skip = (page - 1) * limit;

        const postRepo = AppDataSource.getRepository(CommunityPost);
        const posts = await postRepo
            .createQueryBuilder("post")
            .leftJoinAndSelect("post.author", "author")
            .where("post.userId = :userId", { userId })
            .orderBy("post.createdAt", "DESC")
            .skip(skip)
            .take(limit)
            .getMany();

        const serialized = await Promise.all(posts.map((p) => serializePost(p, userId)));
        return res.json({ posts: serialized, page, hasMore: posts.length === limit });
    } catch (err: any) {
        console.error("GET /community/me/posts error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/posts/:id/report — report inappropriate post
// ─────────────────────────────────────────────────────────────────────────────
router.post("/posts/:id/report", authenticate, async (req: Request, res: Response) => {
    try {
        const reporterId = (req as any).user?.id;
        const postId = parseInt(req.params.id);
        const { reason } = req.body;

        const postRepo = AppDataSource.getRepository(CommunityPost);
        const reportRepo = AppDataSource.getRepository(PostReport);

        const post = await postRepo.findOne({ where: { id: postId } });
        if (!post) return res.status(404).json({ error: "Post not found" });

        const validReasons = ["spam", "nudity", "copyright", "other"];
        const report = reportRepo.create({
            reporterId,
            postId,
            reason: validReasons.includes(reason) ? reason : "other",
        });
        await reportRepo.save(report);

        post.isReported = true;
        await postRepo.save(post);

        return res.json({ success: true, message: "Post reported successfully" });
    } catch (err: any) {
        console.error("POST /community/posts/:id/report error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

// GET /api/community/admin/stats — community overview stats
router.get("/admin/stats", authenticate, requireAdmin, async (req: Request, res: Response) => {
    try {
        const postRepo = AppDataSource.getRepository(CommunityPost);
        const reportRepo = AppDataSource.getRepository(PostReport);

        const totalPosts = await postRepo.count();
        const reportedPosts = await postRepo.count({ where: { isReported: true } });
        const unapprovedPosts = await postRepo.count({ where: { isApproved: false } });
        const totalReports = await reportRepo.count();

        return res.json({
            totalPosts,
            reportedPosts,
            unapprovedPosts,
            totalReports,
        });
    } catch (err: any) {
        console.error("GET /community/admin/stats error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// GET /api/community/admin/posts — list community posts for admin
router.get("/admin/posts", authenticate, requireAdmin, async (req: Request, res: Response) => {
    try {
        const page = Math.max(1, parseInt((req.query.page as string) || "1"));
        const limit = Math.max(1, Math.min(100, parseInt((req.query.limit as string) || "24")));
        const search = ((req.query.search as string) || "").trim();
        const filter = (req.query.filter as string) || "all";
        const skip = (page - 1) * limit;

        const postRepo = AppDataSource.getRepository(CommunityPost);
        let qb = postRepo
            .createQueryBuilder("post")
            .leftJoinAndSelect("post.author", "author")
            .orderBy("post.createdAt", "DESC");

        if (filter === "reported") {
            qb = qb.andWhere("post.isReported = true");
        } else if (filter === "unapproved" || filter === "pending") {
            qb = qb.andWhere("post.isApproved = false");
        } else if (filter === "approved" || filter === "live") {
            qb = qb.andWhere("post.isApproved = true");
        }

        if (search) {
            qb = qb.andWhere(
                "(post.title LIKE :search OR post.description LIKE :search OR author.displayName LIKE :search OR author.username LIKE :search OR author.email LIKE :search)",
                { search: `%${search}%` }
            );
        }

        const [posts, total] = await qb.skip(skip).take(limit).getManyAndCount();

        return res.json({
            posts: posts.map((p) => ({
                id: p.id,
                imageUrl: p.imageUrl,
                thumbnailUrl: p.thumbnailUrl,
                title: p.title,
                description: p.description,
                width: p.width,
                height: p.height,
                likesCount: p.likesCount,
                commentsCount: p.commentsCount,
                savesCount: p.savesCount,
                isApproved: p.isApproved,
                isReported: p.isReported,
                createdAt: p.createdAt,
                author: p.author
                    ? {
                          id: p.author.id,
                          displayName: p.author.displayName,
                          username: p.author.username,
                          email: p.author.email,
                          photoUrl: p.author.photoUrl,
                      }
                    : null,
            })),
            total,
            page,
            totalPages: Math.ceil(total / limit),
        });
    } catch (err: any) {
        console.error("GET /community/admin/posts error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// DELETE /api/community/admin/posts/:id — admin delete any post
router.delete("/admin/posts/:id", authenticate, requireAdmin, async (req: Request, res: Response) => {
    try {
        const postId = parseInt(req.params.id);
        const postRepo = AppDataSource.getRepository(CommunityPost);
        const userRepo = AppDataSource.getRepository(User);

        const post = await postRepo.findOne({ where: { id: postId } });
        if (!post) return res.status(404).json({ error: "Post not found" });

        await postRepo.delete(postId);
        await userRepo.decrement({ id: post.userId }, "postsCount", 1);

        return res.json({ success: true, message: "Post deleted" });
    } catch (err: any) {
        console.error("DELETE /community/admin/posts/:id error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// PATCH /api/community/admin/posts/:id/toggle-approve
router.patch("/admin/posts/:id/toggle-approve", authenticate, requireAdmin, async (req: Request, res: Response) => {
    try {
        const postId = parseInt(req.params.id);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const post = await postRepo.findOne({ where: { id: postId } });
        if (!post) return res.status(404).json({ error: "Post not found" });

        post.isApproved = !post.isApproved;
        await postRepo.save(post);

        return res.json({ success: true, isApproved: post.isApproved });
    } catch (err: any) {
        console.error("PATCH /community/admin/posts/:id/toggle-approve error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// PATCH /api/community/admin/posts/:id/approve — explicitly approve creator wallpaper
router.patch("/admin/posts/:id/approve", authenticate, requireAdmin, async (req: Request, res: Response) => {
    try {
        const postId = parseInt(req.params.id, 10);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const post = await postRepo.findOne({ where: { id: postId } });
        if (!post) return res.status(404).json({ error: "Post not found" });

        post.isApproved = true;
        await postRepo.save(post);

        return res.json({ success: true, message: "Wallpaper approved for live app", isApproved: true });
    } catch (err: any) {
        console.error("PATCH /community/admin/posts/:id/approve error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// PATCH /api/community/admin/posts/:id/reject — unapprove / reject creator wallpaper
router.patch("/admin/posts/:id/reject", authenticate, requireAdmin, async (req: Request, res: Response) => {
    try {
        const postId = parseInt(req.params.id, 10);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const post = await postRepo.findOne({ where: { id: postId } });
        if (!post) return res.status(404).json({ error: "Post not found" });

        post.isApproved = false;
        await postRepo.save(post);

        return res.json({ success: true, message: "Wallpaper hidden from live app", isApproved: false });
    } catch (err: any) {
        console.error("PATCH /community/admin/posts/:id/reject error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// GET /api/community/admin/reports — list user reports
router.get("/admin/reports", authenticate, requireAdmin, async (req: Request, res: Response) => {
    try {
        const reportRepo = AppDataSource.getRepository(PostReport);
        const reports = await reportRepo
            .createQueryBuilder("report")
            .leftJoinAndSelect("report.reporter", "reporter")
            .leftJoinAndSelect("report.post", "post")
            .leftJoinAndSelect("post.author", "author")
            .orderBy("report.createdAt", "DESC")
            .take(50)
            .getMany();

        return res.json({
            reports: reports.map((r) => ({
                id: r.id,
                reason: r.reason,
                createdAt: r.createdAt,
                reporter: r.reporter
                    ? {
                          id: r.reporter.id,
                          displayName: r.reporter.displayName,
                          username: r.reporter.username,
                          email: r.reporter.email,
                      }
                    : null,
                post: r.post
                    ? {
                          id: r.post.id,
                          imageUrl: r.post.imageUrl,
                          thumbnailUrl: r.post.thumbnailUrl,
                          title: r.post.title,
                          author: r.post.author
                              ? {
                                    id: r.post.author.id,
                                    displayName: r.post.author.displayName,
                                    username: r.post.author.username,
                                }
                              : null,
                      }
                    : null,
            })),
        });
    } catch (err: any) {
        console.error("GET /community/admin/reports error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// DELETE /api/community/admin/reports/:id — dismiss report
router.delete("/admin/reports/:id", authenticate, requireAdmin, async (req: Request, res: Response) => {
    try {
        const reportId = parseInt(req.params.id);
        const reportRepo = AppDataSource.getRepository(PostReport);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const report = await reportRepo.findOne({ where: { id: reportId } });
        if (!report) return res.status(404).json({ error: "Report not found" });

        const postId = report.postId;
        await reportRepo.delete(reportId);

        // If no more reports, clear isReported flag
        const remaining = await reportRepo.count({ where: { postId } });
        if (remaining === 0) {
            await postRepo.update(postId, { isReported: false });
        }

        return res.json({ success: true, message: "Report dismissed" });
    } catch (err: any) {
        console.error("DELETE /community/admin/reports/:id error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

export default router;
