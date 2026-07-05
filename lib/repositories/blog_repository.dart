import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/blog_category.dart';
import 'package:pp_tracker/models/blog/blog_models.dart';
import 'package:pp_tracker/models/blog/comment.dart';

/// How a feed query should be ordered.
enum BlogSort { latest, trending, mostViewed }

/// A filter/sort descriptor for paginated feed queries. Maps directly onto a
/// Firestore query (where + orderBy) when the real backend is wired in.
class BlogQuery {
  final String? categoryId; // null or 'all' => no category filter
  final String? searchTerm;
  final String? tag;
  final BlogSort sort;
  final BlogVisibility visibility;

  const BlogQuery({
    this.categoryId,
    this.searchTerm,
    this.tag,
    this.sort = BlogSort.latest,
    this.visibility = BlogVisibility.public,
  });

  BlogQuery copyWith({
    String? categoryId,
    String? searchTerm,
    String? tag,
    BlogSort? sort,
  }) {
    return BlogQuery(
      categoryId: categoryId ?? this.categoryId,
      searchTerm: searchTerm ?? this.searchTerm,
      tag: tag ?? this.tag,
      sort: sort ?? this.sort,
      visibility: visibility,
    );
  }
}

/// One page of results plus an opaque [nextCursor] for the following page.
/// The cursor stays opaque to callers so swapping offset-paging for Firestore
/// `startAfterDocument` cursors requires no UI/controller changes.
class Page<T> {
  final List<T> items;
  final String? nextCursor;
  bool get hasMore => nextCursor != null;

  const Page({required this.items, this.nextCursor});

  const Page.empty()
      : items = const [],
        nextCursor = null;
}

/// Reading position for the "Continue reading" rail and history.
class ReadingProgress {
  final String blogId;
  final double progress; // 0..1
  final DateTime lastReadAt;

  const ReadingProgress({
    required this.blogId,
    required this.progress,
    required this.lastReadAt,
  });

  bool get isFinished => progress >= 0.95;
  bool get isInProgress => progress > 0.02 && !isFinished;
}

/// Data-access contract for the blog module.
///
/// The UI/controller depend only on this interface. The current
/// [MockBlogRepository] keeps everything in memory; a `FirestoreBlogRepository`
/// (with an offline cache layer) can implement the same surface later with no
/// changes above this line.
abstract class BlogRepository {
  /// Scopes per-user view-state (bookmarks, likes) attached to returned blogs.
  /// Call once after sign-in; a Firestore implementation uses it to join the
  /// current user's bookmark/like subcollections.
  void setCurrentUser(String? userId);

  // ---- Reading ----------------------------------------------------------
  Future<List<BlogCategory>> fetchCategories();

  Future<Page<Blog>> fetchBlogs({
    BlogQuery query = const BlogQuery(),
    String? cursor,
    int limit = 10,
  });

  Future<Blog?> fetchBlogById(String id);
  Future<List<Blog>> fetchFeatured({int limit = 5});
  Future<List<Blog>> fetchTrending({int limit = 6});
  Future<List<Blog>> fetchRecommended({String? forUserId, int limit = 6});
  Future<List<Blog>> fetchRelated(Blog blog, {int limit = 3});

  // ---- Per-user state ---------------------------------------------------
  Future<void> setBookmark(String blogId, String userId, bool bookmarked);
  Future<List<Blog>> fetchBookmarks(String userId);

  Future<void> toggleLike(String blogId, String userId);

  Future<void> recordView(String blogId, String userId);
  Future<void> saveReadingProgress(String blogId, String userId, double progress);
  Future<List<Blog>> fetchContinueReading(String userId, {int limit = 5});
  Future<List<Blog>> fetchReadingHistory(String userId, {int limit = 20});

  // ---- Authoring (drafts / publishing) ----------------------------------
  Future<Blog> upsertBlog(Blog blog);

  // ---- Moderation -------------------------------------------------------
  Future<void> reportBlog(BlogReport report);

  // ---- Comments ---------------------------------------------------------
  Future<Page<Comment>> fetchComments(
    String blogId, {
    String? parentCommentId,
    String? cursor,
    int limit = 20,
  });
  Future<Comment> addComment({
    required String blogId,
    required AppUser author,
    required String content,
    String? parentCommentId,
  });
  Future<void> toggleCommentLike(String commentId, String userId);
  Future<void> deleteComment(String commentId);

  // ---- Users ------------------------------------------------------------
  Future<AppUser?> fetchUser(String id);
}
