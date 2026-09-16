import { Router, Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { CommunityPost } from "../entities/CommunityPost";
import { CommunityLike } from "../entities/CommunityLike";
import { CommunityComment } from "../entities/CommunityComment";
import { CommunitySave } from "../entities/CommunitySave";
import { Follow } from "../entities/Follow";
import { PostReport } from "../entities/PostReport";
import { User } from "../entities/User";
import { authenticate, AuthRequest } from "../middleware/auth";

const router = Router();

// ─── Helper: serialize a post with viewer context ────────────────────────────
async function serializePost(post: CommunityPost, viewerId: number | null) {
    const likeRepo = AppDataSource.getRepository(CommunityLike);
    const saveRepo = AppDataSource.getRepository(CommunitySave);
    const followRepo = AppDataSource.getRepository(Follow);

    const [isLiked, isSaved, isFollowing] = await Promise.all([
        viewerId
            ? likeRepo.findOne({ where: { userId: viewerId, postId: post.id } })
            : null,
        viewerId
            ? saveRepo.findOne({ where: { userId: viewerId, postId: post.id } })
            : null,
        viewerId && post.author
            ? followRepo.findOne({ where: { followerId: viewerId, followingId: post.userId } })
            : null,
    ]);

    return {
        id: post.id,
        imageUrl: post.imageUrl,
        thumbnailUrl: post.thumbnailUrl,
        title: post.title,
        description: post.description,
        width: post.width,
        height: post.height,
        likesCount: post.likesCount,
        commentsCount: post.commentsCount,
        savesCount: post.savesCount,
        isLiked: !!isLiked,
        isSaved: !!isSaved,
        createdAt: post.createdAt,
        author: post.author
            ? {
                  id: post.author.id,
                  displayName: post.author.displayName,
                  photoUrl: post.author.photoUrl,
                  username: post.author.username,
                  bio: post.author.bio,
                  followersCount: post.author.followersCount,
                  followingCount: post.author.followingCount,
                  postsCount: post.author.postsCount,
                  isFollowing: !!isFollowing,
              }
            : null,
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/community/posts — create a new post
// ─────────────────────────────────────────────────────────────────────────────
router.post("/posts", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id;
        const { imageUrl, thumbnailUrl, title, description, width, height } = req.body;

        if (!imageUrl) {
            return res.status(400).json({ error: "imageUrl is required" });
        }

        const postRepo = AppDataSource.getRepository(CommunityPost);
        const userRepo = AppDataSource.getRepository(User);

        const post = postRepo.create({
            userId,
            imageUrl,
            thumbnailUrl,
            title,
            description,
            width: width ? parseInt(width) : undefined,
            height: height ? parseInt(height) : undefined,
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
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/feed — paginated feed (following + own posts)
// ─────────────────────────────────────────────────────────────────────────────
router.get("/feed", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id;
        const page = parseInt((req.query.page as string) || "1");
        const limit = parseInt((req.query.limit as string) || "20");
        const skip = (page - 1) * limit;

        const postRepo = AppDataSource.getRepository(CommunityPost);
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
        return res.json({ posts: serialized, page, hasMore: posts.length === limit });
    } catch (err: any) {
        console.error("GET /community/feed error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/trending — top liked posts from last 7 days
// ─────────────────────────────────────────────────────────────────────────────
router.get("/trending", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id;
        const page = parseInt((req.query.page as string) || "1");
        const limit = parseInt((req.query.limit as string) || "20");
        const skip = (page - 1) * limit;

        const postRepo = AppDataSource.getRepository(CommunityPost);
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
        return res.json({ posts: serialized, page, hasMore: posts.length === limit });
    } catch (err: any) {
        console.error("GET /community/trending error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/posts/:id — single post
// ─────────────────────────────────────────────────────────────────────────────
router.get("/posts/:id", authenticate, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.id;
        const postId = parseInt(req.params.id);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const post = await postRepo.findOne({
            where: { id: postId, isApproved: true },
            relations: ["author"],
        });

        if (!post) return res.status(404).json({ error: "Post not found" });

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
        const postId = parseInt(req.params.id);
        const postRepo = AppDataSource.getRepository(CommunityPost);
        const userRepo = AppDataSource.getRepository(User);

        const post = await postRepo.findOne({ where: { id: postId } });
        if (!post) return res.status(404).json({ error: "Post not found" });
        if (post.userId !== userId) return res.status(403).json({ error: "Forbidden" });

        await postRepo.delete(postId);
        await userRepo.decrement({ id: userId }, "postsCount", 1);

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
        const userId = (req as any).user?.id;
        const postId = parseInt(req.params.id);
        const likeRepo = AppDataSource.getRepository(CommunityLike);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const existing = await likeRepo.findOne({ where: { userId, postId } });

        if (existing) {
            await likeRepo.delete({ userId, postId });
            await postRepo.decrement({ id: postId }, "likesCount", 1);
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
        const userId = (req as any).user?.id;
        const postId = parseInt(req.params.id);
        const { content } = req.body;

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

        return res.status(201).json({
            comment: {
                id: comment.id,
                content: comment.content,
                createdAt: comment.createdAt,
                author: {
                    id: author!.id,
                    displayName: author!.displayName,
                    photoUrl: author!.photoUrl,
                    username: author!.username,
                },
            },
        });
    } catch (err: any) {
        console.error("POST /community/posts/:id/comment error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/posts/:id/comments — paginated comments
// ─────────────────────────────────────────────────────────────────────────────
router.get("/posts/:id/comments", authenticate, async (req: Request, res: Response) => {
    try {
        const postId = parseInt(req.params.id);
        const page = parseInt((req.query.page as string) || "1");
        const limit = parseInt((req.query.limit as string) || "20");
        const skip = (page - 1) * limit;

        const commentRepo = AppDataSource.getRepository(CommunityComment);
        const comments = await commentRepo
            .createQueryBuilder("comment")
            .leftJoinAndSelect("comment.author", "author")
            .where("comment.postId = :postId", { postId })
            .orderBy("comment.createdAt", "ASC")
            .skip(skip)
            .take(limit)
            .getMany();

        return res.json({
            comments: comments.map((c) => ({
                id: c.id,
                content: c.content,
                createdAt: c.createdAt,
                author: {
                    id: c.author.id,
                    displayName: c.author.displayName,
                    photoUrl: c.author.photoUrl,
                    username: c.author.username,
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
        const userId = (req as any).user?.id;
        const postId = parseInt(req.params.id);
        const saveRepo = AppDataSource.getRepository(CommunitySave);
        const postRepo = AppDataSource.getRepository(CommunityPost);

        const existing = await saveRepo.findOne({ where: { userId, postId } });

        if (existing) {
            await saveRepo.delete({ userId, postId });
            await postRepo.decrement({ id: postId }, "savesCount", 1);
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
        const userId = (req as any).user?.id;
        const page = parseInt((req.query.page as string) || "1");
        const limit = parseInt((req.query.limit as string) || "20");
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
// POST /api/community/posts/:id/report — report a post
// ─────────────────────────────────────────────────────────────────────────────
router.post("/posts/:id/report", authenticate, async (req: Request, res: Response) => {
    try {
        const reporterId = (req as any).user?.id;
        const postId = parseInt(req.params.id);
        const { reason } = req.body;

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
        const followerId = (req as any).user?.id;
        const followingId = parseInt(req.params.userId);

        if (followerId === followingId) {
            return res.status(400).json({ error: "Cannot follow yourself" });
        }

        const followRepo = AppDataSource.getRepository(Follow);
        const userRepo = AppDataSource.getRepository(User);

        const existing = await followRepo.findOne({ where: { followerId, followingId } });
        if (existing) {
            return res.status(409).json({ error: "Already following" });
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
        const followerId = (req as any).user?.id;
        const followingId = parseInt(req.params.userId);

        const followRepo = AppDataSource.getRepository(Follow);
        const userRepo = AppDataSource.getRepository(User);

        const existing = await followRepo.findOne({ where: { followerId, followingId } });
        if (!existing) {
            return res.status(404).json({ error: "Not following" });
        }

        await followRepo.delete({ followerId, followingId });
        await userRepo.decrement({ id: followerId }, "followingCount", 1);
        await userRepo.decrement({ id: followingId }, "followersCount", 1);

        return res.json({ following: false });
    } catch (err: any) {
        console.error("DELETE /community/follow/:userId error:", err);
        return res.status(500).json({ error: "Internal server error" });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/community/users/:userId — public profile
// ─────────────────────────────────────────────────────────────────────────────
router.get("/users/:userId", authenticate, async (req: Request, res: Response) => {
    try {
        const viewerId = (req as any).user?.id;
        const targetId = parseInt(req.params.userId);

        const userRepo = AppDataSource.getRepository(User);
        const followRepo = AppDataSource.getRepository(Follow);

        const user = await userRepo.findOne({ where: { id: targetId, isActive: true } });
        if (!user) return res.status(404).json({ error: "User not found" });

        const isFollowing = viewerId
            ? !!(await followRepo.findOne({ where: { followerId: viewerId, followingId: targetId } }))
            : false;

        return res.json({
            user: {
                id: user.id,
                displayName: user.displayName,
                photoUrl: user.photoUrl,
                username: user.username,
                bio: user.bio,
                followersCount: user.followersCount,
                followingCount: user.followingCount,
                postsCount: user.postsCount,
                isFollowing,
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
router.get("/users/:userId/posts", authenticate, async (req: Request, res: Response) => {
    try {
        const viewerId = (req as any).user?.id;
        const targetId = parseInt(req.params.userId);
        const page = parseInt((req.query.page as string) || "1");
        const limit = parseInt((req.query.limit as string) || "20");
        const skip = (page - 1) * limit;

        const postRepo = AppDataSource.getRepository(CommunityPost);
        const posts = await postRepo
            .createQueryBuilder("post")
            .leftJoinAndSelect("post.author", "author")
            .where("post.userId = :userId AND post.isApproved = true", { userId: targetId })
            .orderBy("post.createdAt", "DESC")
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
router.get("/users/:userId/followers", authenticate, async (req: Request, res: Response) => {
    try {
        const targetId = parseInt(req.params.userId);
        const page = parseInt((req.query.page as string) || "1");
        const limit = parseInt((req.query.limit as string) || "30");
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
router.get("/users/:userId/following", authenticate, async (req: Request, res: Response) => {
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

export default router;
