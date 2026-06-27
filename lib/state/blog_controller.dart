import 'package:flutter/foundation.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/blog_category.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';

enum LoadStatus { initial, loading, loaded, error, empty }

/// State layer for the blog hub.
///
/// Holds the in-memory cache of loaded content for the current user and is the
/// single source of truth the widgets bind to. It talks to a [BlogRepository]
/// for persistence, so the same controller works unchanged against the mock or
/// a future Firestore implementation. Mutations are optimistic — the cache is
/// updated immediately and the repository call follows.
class BlogController extends ChangeNotifier {
  BlogController(this._repo, {required this.currentUser}) {
    _repo.setCurrentUser(currentUser.id);
  }

  final BlogRepository _repo;
  final AppUser currentUser;

  /// Exposed for screens that need direct, read-only data access (e.g. the
  /// comment thread and related-articles rail on the detail screen).
  BlogRepository get repository => _repo;

  // ---- Categories & filters ----
  List<BlogCategory> categories = [BlogCategory.all];
  BlogCategory selectedCategory = BlogCategory.all;
  BlogSort sort = BlogSort.latest;
  String searchTerm = '';

  // ---- Curated rails ----
  List<Blog> featured = [];
  List<Blog> trending = [];
  List<Blog> recommended = [];
  List<Blog> continueReading = [];

  // ---- Main feed (paginated) ----
  final List<Blog> feed = [];
  LoadStatus status = LoadStatus.initial;
  bool loadingMore = false;
  bool hasMore = false;
  String? _cursor;
  String? errorMessage;

  bool get isSearching => searchTerm.trim().isNotEmpty;

  /// Looks up a category by id (falls back to the "All" pseudo-category).
  BlogCategory categoryById(String id) => categories.firstWhere(
        (c) => c.id == id,
        orElse: () => BlogCategory.all,
      );

  BlogQuery get _query => BlogQuery(
        categoryId: selectedCategory.id,
        searchTerm: isSearching ? searchTerm : null,
        sort: sort,
      );

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Full initial load: categories, curated rails and the first feed page.
  Future<void> load() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final cats = await _repo.fetchCategories();
      categories = [BlogCategory.all, ...cats];
      await Future.wait([_loadRails(), _loadFirstPage()]);
      status = feed.isEmpty ? LoadStatus.empty : LoadStatus.loaded;
    } catch (e) {
      status = LoadStatus.error;
      errorMessage = 'We couldn\'t load articles. Pull to try again.';
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> _loadRails() async {
    final results = await Future.wait([
      _repo.fetchFeatured(limit: 5),
      _repo.fetchTrending(limit: 6),
      _repo.fetchRecommended(forUserId: currentUser.id, limit: 6),
      _repo.fetchContinueReading(currentUser.id, limit: 5),
    ]);
    featured = results[0];
    trending = results[1];
    recommended = results[2];
    continueReading = results[3];
  }

  Future<void> _loadFirstPage() async {
    final page = await _repo.fetchBlogs(query: _query, limit: 8);
    feed
      ..clear()
      ..addAll(page.items);
    _cursor = page.nextCursor;
    hasMore = page.hasMore;
  }

  /// Re-runs only the feed query (after a category / search / sort change),
  /// keeping the curated rails intact for a snappier feel.
  Future<void> _reloadFeed() async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      await _loadFirstPage();
      status = feed.isEmpty ? LoadStatus.empty : LoadStatus.loaded;
    } catch (e) {
      status = LoadStatus.error;
      errorMessage = 'Something went wrong. Try again.';
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore || status == LoadStatus.loading) return;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await _repo.fetchBlogs(query: _query, cursor: _cursor, limit: 8);
      feed.addAll(page.items);
      _cursor = page.nextCursor;
      hasMore = page.hasMore;
    } catch (_) {
      // Keep what we have; surface a soft failure via hasMore staying true.
    }
    loadingMore = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  Future<void> selectCategory(BlogCategory category) async {
    if (selectedCategory == category) return;
    selectedCategory = category;
    await _reloadFeed();
  }

  Future<void> setSort(BlogSort newSort) async {
    if (sort == newSort) return;
    sort = newSort;
    await _reloadFeed();
  }

  Future<void> search(String term) async {
    searchTerm = term;
    await _reloadFeed();
  }

  void clearSearch() {
    if (searchTerm.isEmpty) return;
    searchTerm = '';
    _reloadFeed();
  }

  // ---------------------------------------------------------------------------
  // Per-user mutations (optimistic)
  // ---------------------------------------------------------------------------

  List<Blog> bookmarks = [];

  Future<void> loadBookmarks() async {
    bookmarks = await _repo.fetchBookmarks(currentUser.id);
    notifyListeners();
  }

  Future<void> toggleBookmark(Blog blog) async {
    final next = !blog.isBookmarked;
    _patch(blog.id, (b) => b.copyWith(isBookmarked: next));
    if (next) {
      bookmarks = [blog.copyWith(isBookmarked: true), ...bookmarks.where((b) => b.id != blog.id)];
    } else {
      bookmarks = bookmarks.where((b) => b.id != blog.id).toList();
    }
    notifyListeners();
    await _repo.setBookmark(blog.id, currentUser.id, next);
  }

  Future<void> toggleLike(Blog blog) async {
    final liked = !blog.isLikedByMe;
    _patch(
      blog.id,
      (b) => b.copyWith(
        isLikedByMe: liked,
        likeCount: (b.likeCount + (liked ? 1 : -1)).clamp(0, 1 << 31),
      ),
    );
    notifyListeners();
    await _repo.toggleLike(blog.id, currentUser.id);
  }

  Future<void> recordView(Blog blog) async {
    await _repo.recordView(blog.id, currentUser.id);
  }

  Future<void> saveProgress(Blog blog, double progress) async {
    await _repo.saveReadingProgress(blog.id, currentUser.id, progress);
  }

  /// Refreshes the "Continue reading" rail (e.g. after returning from a reader).
  Future<void> refreshContinueReading() async {
    continueReading = await _repo.fetchContinueReading(currentUser.id, limit: 5);
    notifyListeners();
  }

  /// Applies [fn] to every cached copy of the blog with [id] across all lists,
  /// keeping feed and rails in sync after a mutation.
  void _patch(String id, Blog Function(Blog) fn) {
    void apply(List<Blog> list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].id == id) list[i] = fn(list[i]);
      }
    }

    apply(feed);
    apply(featured);
    apply(trending);
    apply(recommended);
    apply(continueReading);
    apply(bookmarks);
  }
}
