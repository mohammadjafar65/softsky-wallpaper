import 'package:flutter/foundation.dart';
import '../models/community_post.dart';
import '../models/community_comment.dart';
import '../models/community_user.dart';
import '../services/api_service.dart';

class CommunityProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // Feed state
  List<CommunityPost> _feedPosts = [];
  List<CommunityPost> _trendingPosts = [];
  List<CommunityPost> _myPosts = [];

  bool _feedLoading = false;
  bool _trendingLoading = false;
  bool _myPostsLoading = false;

  bool _feedHasMore = true;
  bool _trendingHasMore = true;
  bool _myPostsHasMore = true;

  int _feedPage = 1;
  int _trendingPage = 1;
  int _myPostsPage = 1;

  String? _error;

  // Getters
  List<CommunityPost> get feedPosts => _feedPosts;
  List<CommunityPost> get trendingPosts => _trendingPosts;
  List<CommunityPost> get myPosts => _myPosts;
  bool get feedLoading => _feedLoading;
  bool get trendingLoading => _trendingLoading;
  bool get myPostsLoading => _myPostsLoading;
  bool get feedHasMore => _feedHasMore;
  bool get trendingHasMore => _trendingHasMore;
  String? get error => _error;

  // ─── Feed ─────────────────────────────────────────────────────────────────

  Future<void> loadFeed({bool refresh = false}) async {
    if (_feedLoading) return;
    if (refresh) {
      _feedPage = 1;
      _feedHasMore = true;
      _feedPosts = [];
    }
    if (!_feedHasMore) return;

    _feedLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getCommunityFeed(page: _feedPage, limit: 20);
      final posts = (data['posts'] as List)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();

      _feedPosts = refresh ? posts : [..._feedPosts, ...posts];
      _feedHasMore = data['hasMore'] as bool? ?? false;
      _feedPage++;
    } catch (e) {
      _error = e.toString();
      debugPrint('loadFeed error: $e');
    } finally {
      _feedLoading = false;
      notifyListeners();
    }
  }

  // ─── Trending ─────────────────────────────────────────────────────────────

  Future<void> loadTrending({bool refresh = false}) async {
    if (_trendingLoading) return;
    if (refresh) {
      _trendingPage = 1;
      _trendingHasMore = true;
      _trendingPosts = [];
    }
    if (!_trendingHasMore) return;

    _trendingLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getTrendingPosts(page: _trendingPage, limit: 20);
      final posts = (data['posts'] as List)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();

      _trendingPosts = refresh ? posts : [..._trendingPosts, ...posts];
      _trendingHasMore = data['hasMore'] as bool? ?? false;
      _trendingPage++;
    } catch (e) {
      _error = e.toString();
      debugPrint('loadTrending error: $e');
    } finally {
      _trendingLoading = false;
      notifyListeners();
    }
  }

  // ─── My Posts ─────────────────────────────────────────────────────────────

  Future<void> loadMyPosts({bool refresh = false}) async {
    if (_myPostsLoading) return;
    if (refresh) {
      _myPostsPage = 1;
      _myPostsHasMore = true;
      _myPosts = [];
    }
    if (!_myPostsHasMore) return;

    _myPostsLoading = true;
    notifyListeners();

    try {
      final data = await _api.getMyPosts(page: _myPostsPage);
      final posts = (data['posts'] as List)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();

      _myPosts = refresh ? posts : [..._myPosts, ...posts];
      _myPostsHasMore = data['hasMore'] as bool? ?? false;
      _myPostsPage++;
    } catch (e) {
      debugPrint('loadMyPosts error: $e');
    } finally {
      _myPostsLoading = false;
      notifyListeners();
    }
  }

  // ─── Like ─────────────────────────────────────────────────────────────────

  Future<void> toggleLike(int postId) async {
    _optimisticToggleLike(postId);
    try {
      final liked = await _api.toggleLike(postId);
      // Sync actual value from server
      _updatePostLike(postId, liked);
    } catch (e) {
      // Revert on failure
      _optimisticToggleLike(postId);
      debugPrint('toggleLike error: $e');
    }
    notifyListeners();
  }

  void _optimisticToggleLike(int postId) {
    for (final list in [_feedPosts, _trendingPosts, _myPosts]) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == postId) {
          final p = list[i];
          p.isLiked = !p.isLiked;
          p.likesCount += p.isLiked ? 1 : -1;
        }
      }
    }
  }

  void _updatePostLike(int postId, bool liked) {
    for (final list in [_feedPosts, _trendingPosts, _myPosts]) {
      for (final p in list) {
        if (p.id == postId) {
          p.isLiked = liked;
        }
      }
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> toggleSave(int postId) async {
    _optimisticToggleSave(postId);
    try {
      final saved = await _api.toggleSave(postId);
      _updatePostSave(postId, saved);
    } catch (e) {
      _optimisticToggleSave(postId);
      debugPrint('toggleSave error: $e');
    }
    notifyListeners();
  }

  void _optimisticToggleSave(int postId) {
    for (final list in [_feedPosts, _trendingPosts, _myPosts]) {
      for (final p in list) {
        if (p.id == postId) {
          p.isSaved = !p.isSaved;
          p.savesCount += p.isSaved ? 1 : -1;
        }
      }
    }
  }

  void _updatePostSave(int postId, bool saved) {
    for (final list in [_feedPosts, _trendingPosts, _myPosts]) {
      for (final p in list) {
        if (p.id == postId) {
          p.isSaved = saved;
        }
      }
    }
  }

  // ─── Comments ─────────────────────────────────────────────────────────────

  Future<List<CommunityComment>> loadComments(int postId, {int page = 1}) async {
    try {
      final data = await _api.getComments(postId, page: page);
      return (data['comments'] as List)
          .map((e) => CommunityComment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadComments error: $e');
      return [];
    }
  }

  Future<CommunityComment?> addComment(int postId, String content) async {
    try {
      final data = await _api.addComment(postId, content);
      final comment = CommunityComment.fromJson(
          data['comment'] as Map<String, dynamic>);

      // Increment comment count in local lists
      for (final list in [_feedPosts, _trendingPosts, _myPosts]) {
        for (final p in list) {
          if (p.id == postId) p.commentsCount++;
        }
      }
      notifyListeners();
      return comment;
    } catch (e) {
      debugPrint('addComment error: $e');
      return null;
    }
  }

  // ─── Follow ───────────────────────────────────────────────────────────────

  Future<bool> toggleFollow(CommunityUser user) async {
    final wasFollowing = user.isFollowing;
    try {
      if (wasFollowing) {
        await _api.unfollowUser(user.id);
      } else {
        await _api.followUser(user.id);
      }
      return !wasFollowing;
    } catch (e) {
      debugPrint('toggleFollow error: $e');
      return wasFollowing;
    }
  }

  // ─── Post Management ──────────────────────────────────────────────────────

  void addPostToFeed(CommunityPost post) {
    _feedPosts.insert(0, post);
    _myPosts.insert(0, post);
    notifyListeners();
  }

  Future<void> deletePost(int postId) async {
    try {
      await _api.deleteCommunityPost(postId);
      _feedPosts.removeWhere((p) => p.id == postId);
      _trendingPosts.removeWhere((p) => p.id == postId);
      _myPosts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('deletePost error: $e');
    }
  }

  // ─── Reporting ────────────────────────────────────────────────────────────

  Future<void> reportPost(int postId, String reason) async {
    await _api.reportPost(postId, reason);
  }

  // ─── User Profile ─────────────────────────────────────────────────────────

  Future<CommunityUser?> getCommunityUser(int userId) async {
    try {
      final data = await _api.getCommunityUser(userId);
      return CommunityUser.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('getCommunityUser error: $e');
      return null;
    }
  }

  Future<List<CommunityPost>> getUserPosts(int userId, {int page = 1}) async {
    try {
      final data = await _api.getUserPosts(userId, page: page);
      return (data['posts'] as List)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getUserPosts error: $e');
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
