import 'package:collection/collection.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/blog_category.dart';
import 'package:pp_tracker/models/blog/comment.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';

/// In-memory [BlogRepository] backed by seeded demo content.
///
/// Mimics async I/O (latency + pagination + per-user state) so the UI behaves
/// exactly as it will against Firestore. Swapping this for a Firestore-backed
/// implementation requires no changes to the controller or widgets.
class MockBlogRepository implements BlogRepository {
  MockBlogRepository() {
    _seed();
  }

  final List<AppUser> _users = [];
  final List<BlogCategory> _categories = [];
  final List<Blog> _blogs = [];
  final List<Comment> _comments = [];

  // Per-user state (would be subcollections / separate docs in Firestore).
  final Map<String, Set<String>> _bookmarks = {}; // userId -> blogIds
  final Map<String, Set<String>> _likes = {}; // userId -> blogIds
  final Map<String, Set<String>> _commentLikes = {}; // userId -> commentIds
  final Map<String, Map<String, ReadingProgress>> _progress =
      {}; // userId -> blogId -> progress

  static const _latency = Duration(milliseconds: 350);
  Future<T> _io<T>(T value) => Future.delayed(_latency, () => value);

  // -------------------------------------------------------------------------
  // Per-user decoration: attaches isBookmarked / isLikedByMe to a Blog.
  // -------------------------------------------------------------------------
  Blog _decorate(Blog b, String? userId) {
    if (userId == null) return b;
    return b.copyWith(
      isBookmarked: _bookmarks[userId]?.contains(b.id) ?? false,
      isLikedByMe: _likes[userId]?.contains(b.id) ?? false,
    );
  }

  String? _currentUserId; // set by the controller via [setCurrentUser]

  @override
  void setCurrentUser(String? userId) => _currentUserId = userId;

  // -------------------------------------------------------------------------
  // Reading
  // -------------------------------------------------------------------------

  @override
  Future<List<BlogCategory>> fetchCategories() => _io(
        List<BlogCategory>.from(_categories)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );

  @override
  Future<Page<Blog>> fetchBlogs({
    BlogQuery query = const BlogQuery(),
    String? cursor,
    int limit = 10,
  }) {
    var list = _blogs.where((b) => b.visibility == query.visibility).toList();

    if (query.categoryId != null && query.categoryId != BlogCategory.all.id) {
      list = list.where((b) => b.categoryId == query.categoryId).toList();
    }
    if (query.tag != null) {
      list = list.where((b) => b.tags.contains(query.tag)).toList();
    }
    if (query.searchTerm != null && query.searchTerm!.trim().isNotEmpty) {
      final q = query.searchTerm!.toLowerCase();
      list = list.where((b) {
        return b.title.toLowerCase().contains(q) ||
            b.summary.toLowerCase().contains(q) ||
            b.content.toLowerCase().contains(q) ||
            b.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    switch (query.sort) {
      case BlogSort.latest:
        list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case BlogSort.trending:
        list.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
        break;
      case BlogSort.mostViewed:
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }

    final offset = int.tryParse(cursor ?? '0') ?? 0;
    final slice = list.skip(offset).take(limit).toList();
    final nextOffset = offset + slice.length;
    final hasMore = nextOffset < list.length;

    return _io(Page(
      items: slice.map((b) => _decorate(b, _currentUserId)).toList(),
      nextCursor: hasMore ? '$nextOffset' : null,
    ));
  }

  @override
  Future<Blog?> fetchBlogById(String id) {
    final blog = _blogs.where((b) => b.id == id).firstOrNull;
    return _io(blog == null ? null : _decorate(blog, _currentUserId));
  }

  @override
  Future<List<Blog>> fetchFeatured({int limit = 5}) {
    final list = _blogs
        .where((b) => b.isFeatured && b.visibility.isPublic)
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return _io(
        list.take(limit).map((b) => _decorate(b, _currentUserId)).toList());
  }

  @override
  Future<List<Blog>> fetchTrending({int limit = 6}) {
    final list = _blogs.where((b) => b.visibility.isPublic).toList()
      ..sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    return _io(
        list.take(limit).map((b) => _decorate(b, _currentUserId)).toList());
  }

  @override
  Future<List<Blog>> fetchRecommended({String? forUserId, int limit = 6}) {
    // Heuristic: favour categories the user has read, else most engaging.
    final history = _progress[forUserId]?.values.toList() ?? [];
    final readCategoryIds = history
        .map((p) => _blogs.where((b) => b.id == p.blogId).firstOrNull?.categoryId)
        .whereType<String>()
        .toSet();

    final list = _blogs.where((b) => b.visibility.isPublic).toList();
    list.sort((a, b) {
      final aw = readCategoryIds.contains(a.categoryId) ? 1 : 0;
      final bw = readCategoryIds.contains(b.categoryId) ? 1 : 0;
      if (aw != bw) return bw - aw;
      return b.engagementScore.compareTo(a.engagementScore);
    });
    return _io(
        list.take(limit).map((b) => _decorate(b, _currentUserId)).toList());
  }

  @override
  Future<List<Blog>> fetchRelated(Blog blog, {int limit = 3}) {
    final list = _blogs.where((b) {
      if (b.id == blog.id || !b.visibility.isPublic) return false;
      final sameCategory = b.categoryId == blog.categoryId;
      final sharedTag = b.tags.any(blog.tags.contains);
      return sameCategory || sharedTag;
    }).toList()
      ..sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    return _io(
        list.take(limit).map((b) => _decorate(b, _currentUserId)).toList());
  }

  // -------------------------------------------------------------------------
  // Per-user state
  // -------------------------------------------------------------------------

  @override
  Future<void> setBookmark(String blogId, String userId, bool bookmarked) {
    final set = _bookmarks.putIfAbsent(userId, () => {});
    bookmarked ? set.add(blogId) : set.remove(blogId);
    return _io(null);
  }

  @override
  Future<List<Blog>> fetchBookmarks(String userId) {
    final ids = _bookmarks[userId] ?? {};
    final list = _blogs.where((b) => ids.contains(b.id)).toList();
    return _io(list.map((b) => _decorate(b, userId)).toList());
  }

  @override
  Future<void> toggleLike(String blogId, String userId) {
    final set = _likes.putIfAbsent(userId, () => {});
    final idx = _blogs.indexWhere((b) => b.id == blogId);
    if (idx == -1) return _io(null);
    if (set.contains(blogId)) {
      set.remove(blogId);
      _blogs[idx] = _blogs[idx]
          .copyWith(likeCount: (_blogs[idx].likeCount - 1).clamp(0, 1 << 31));
    } else {
      set.add(blogId);
      _blogs[idx] = _blogs[idx].copyWith(likeCount: _blogs[idx].likeCount + 1);
    }
    return _io(null);
  }

  @override
  Future<void> recordView(String blogId, String userId) {
    final idx = _blogs.indexWhere((b) => b.id == blogId);
    if (idx != -1) {
      _blogs[idx] = _blogs[idx].copyWith(viewCount: _blogs[idx].viewCount + 1);
    }
    return _io(null);
  }

  @override
  Future<void> saveReadingProgress(
      String blogId, String userId, double progress) {
    final map = _progress.putIfAbsent(userId, () => {});
    map[blogId] = ReadingProgress(
      blogId: blogId,
      progress: progress.clamp(0.0, 1.0),
      lastReadAt: DateTime.now(),
    );
    return _io(null);
  }

  @override
  Future<List<Blog>> fetchContinueReading(String userId, {int limit = 5}) {
    final map = _progress[userId] ?? {};
    final inProgress = map.values.where((p) => p.isInProgress).toList()
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    final list = inProgress
        .map((p) => _blogs.where((b) => b.id == p.blogId).firstOrNull)
        .whereType<Blog>()
        .take(limit)
        .map((b) => _decorate(b, userId))
        .toList();
    return _io(list);
  }

  @override
  Future<List<Blog>> fetchReadingHistory(String userId, {int limit = 20}) {
    final map = _progress[userId] ?? {};
    final entries = map.values.toList()
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    final list = entries
        .map((p) => _blogs.where((b) => b.id == p.blogId).firstOrNull)
        .whereType<Blog>()
        .take(limit)
        .map((b) => _decorate(b, userId))
        .toList();
    return _io(list);
  }

  /// Reading progress fraction for a blog (used by the reader to resume).
  double progressFor(String userId, String blogId) =>
      _progress[userId]?[blogId]?.progress ?? 0.0;

  // -------------------------------------------------------------------------
  // Authoring
  // -------------------------------------------------------------------------

  @override
  Future<Blog> upsertBlog(Blog blog) {
    final idx = _blogs.indexWhere((b) => b.id == blog.id);
    if (idx == -1) {
      _blogs.insert(0, blog);
    } else {
      _blogs[idx] = blog;
    }
    return _io(blog);
  }

  // -------------------------------------------------------------------------
  // Comments
  // -------------------------------------------------------------------------

  Comment _decorateComment(Comment c, String? userId) {
    if (userId == null) return c;
    return c.copyWith(
      isLikedByMe: _commentLikes[userId]?.contains(c.id) ?? false,
    );
  }

  @override
  Future<Page<Comment>> fetchComments(
    String blogId, {
    String? parentCommentId,
    String? cursor,
    int limit = 20,
  }) {
    var list = _comments
        .where((c) =>
            c.blogId == blogId &&
            c.parentCommentId == parentCommentId &&
            c.status != CommentStatus.hidden)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final offset = int.tryParse(cursor ?? '0') ?? 0;
    final slice = list.skip(offset).take(limit).toList();
    final nextOffset = offset + slice.length;

    return _io(Page(
      items: slice.map((c) => _decorateComment(c, _currentUserId)).toList(),
      nextCursor: nextOffset < list.length ? '$nextOffset' : null,
    ));
  }

  @override
  Future<Comment> addComment({
    required String blogId,
    required AppUser author,
    required String content,
    String? parentCommentId,
  }) {
    final now = DateTime.now();
    final comment = Comment(
      id: 'c_${now.microsecondsSinceEpoch}',
      blogId: blogId,
      userId: author.id,
      authorName: author.displayName,
      authorAvatarUrl: author.avatarUrl,
      parentCommentId: parentCommentId,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    _comments.add(comment);

    // Maintain denormalized counters.
    if (parentCommentId != null) {
      final pIdx = _comments.indexWhere((c) => c.id == parentCommentId);
      if (pIdx != -1) {
        _comments[pIdx] =
            _comments[pIdx].copyWith(replyCount: _comments[pIdx].replyCount + 1);
      }
    }
    final bIdx = _blogs.indexWhere((b) => b.id == blogId);
    if (bIdx != -1) {
      _blogs[bIdx] =
          _blogs[bIdx].copyWith(commentCount: _blogs[bIdx].commentCount + 1);
    }
    return _io(comment);
  }

  @override
  Future<void> toggleCommentLike(String commentId, String userId) {
    final set = _commentLikes.putIfAbsent(userId, () => {});
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return _io(null);
    if (set.contains(commentId)) {
      set.remove(commentId);
      _comments[idx] = _comments[idx]
          .copyWith(likeCount: (_comments[idx].likeCount - 1).clamp(0, 1 << 31));
    } else {
      set.add(commentId);
      _comments[idx] =
          _comments[idx].copyWith(likeCount: _comments[idx].likeCount + 1);
    }
    return _io(null);
  }

  @override
  Future<void> deleteComment(String commentId) {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx != -1) {
      _comments[idx] = _comments[idx]
          .copyWith(status: CommentStatus.deleted, content: '');
    }
    return _io(null);
  }

  // -------------------------------------------------------------------------
  // Users
  // -------------------------------------------------------------------------

  @override
  Future<AppUser?> fetchUser(String id) =>
      _io(_users.where((u) => u.id == id).firstOrNull);

  // -------------------------------------------------------------------------
  // Seed data
  // -------------------------------------------------------------------------

  void _seed() {
    final now = DateTime.now();

    _categories.addAll(const [
      BlogCategory(id: 'cycle', name: 'Cycle', slug: 'cycle', colorValue: 0xFFE26D7E, iconKey: 'cycle', sortOrder: 0),
      BlogCategory(id: 'hormones', name: 'Hormones', slug: 'hormones', colorValue: 0xFF9B8AC9, iconKey: 'hormones', sortOrder: 1),
      BlogCategory(id: 'nutrition', name: 'Nutrition', slug: 'nutrition', colorValue: 0xFF5FB49C, iconKey: 'nutrition', sortOrder: 2),
      BlogCategory(id: 'mind', name: 'Mental Health', slug: 'mind', colorValue: 0xFF7FB0E0, iconKey: 'mind', sortOrder: 3),
      BlogCategory(id: 'fitness', name: 'Fitness', slug: 'fitness', colorValue: 0xFFE0A24E, iconKey: 'fitness', sortOrder: 4),
      BlogCategory(id: 'pcos', name: 'PCOS', slug: 'pcos', colorValue: 0xFFB76E84, iconKey: 'pcos', sortOrder: 5),
      BlogCategory(id: 'sleep', name: 'Sleep', slug: 'sleep', colorValue: 0xFF6FB7D4, iconKey: 'sleep', sortOrder: 6),
      BlogCategory(id: 'fertility', name: 'Fertility', slug: 'fertility', colorValue: 0xFFE0A24E, iconKey: 'fertility', sortOrder: 7),
    ]);

    _users.addAll([
      AppUser(id: 'u_sarah', displayName: 'Dr. Sarah Wilson', isExpert: true, credentials: 'OB-GYN', bio: 'Women\'s health physician focused on cycle education.', joinedAt: now.subtract(const Duration(days: 400))),
      AppUser(id: 'u_emily', displayName: 'Dr. Emily Chen', isExpert: true, credentials: 'Endocrinologist', bio: 'Hormone health researcher.', joinedAt: now.subtract(const Duration(days: 320))),
      AppUser(id: 'u_maya', displayName: 'Maya Patel', isExpert: true, credentials: 'Registered Dietitian', bio: 'Cycle-syncing nutrition.', joinedAt: now.subtract(const Duration(days: 260))),
      AppUser(id: 'u_alex', displayName: 'Alex Rivera', isExpert: true, credentials: 'Womens Fitness Coach', bio: 'Training with your cycle, not against it.', joinedAt: now.subtract(const Duration(days: 210))),
      AppUser(id: 'u_jord', displayName: 'Jordan Lee', bio: 'Wellness writer & community member.', joinedAt: now.subtract(const Duration(days: 120))),
    ]);

    final seeds = <_Seed>[
      _Seed('Understanding Period Cramps: Causes & Relief', 'Why they happen and what actually helps', 'cycle', 'u_sarah', ['cramps', 'pain', 'relief'], true),
      _Seed('Eating for Every Phase of Your Cycle', 'Match your plate to your hormones', 'nutrition', 'u_maya', ['food', 'diet', 'energy'], true),
      _Seed('The Estrogen–Serotonin Connection', 'How hormones shape your mood', 'hormones', 'u_emily', ['mood', 'estrogen', 'pms'], true),
      _Seed('Training With Your Cycle, Not Against It', 'When to push and when to rest', 'fitness', 'u_alex', ['exercise', 'energy', 'recovery'], false),
      _Seed('PCOS, Explained Simply', 'Symptoms, myths and management', 'pcos', 'u_emily', ['pcos', 'hormones'], false),
      _Seed('Sleep & Your Menstrual Cycle', 'Why rest shifts across the month', 'sleep', 'u_sarah', ['sleep', 'rest', 'luteal'], false),
      _Seed('Calming the Luteal-Phase Mind', 'Gentle practices for PMS weeks', 'mind', 'u_emily', ['pms', 'anxiety', 'calm'], false),
      _Seed('Iron, Fatigue & Your Period', 'Replenishing what you lose', 'nutrition', 'u_maya', ['iron', 'fatigue', 'food'], false),
      _Seed('Tracking Fertility Signs Naturally', 'Reading your body\'s signals', 'fertility', 'u_sarah', ['fertility', 'ovulation'], false),
      _Seed('Magnesium: The Calm Mineral', 'A quiet hero for cramps and sleep', 'nutrition', 'u_maya', ['magnesium', 'cramps', 'sleep'], false),
      _Seed('Yoga Poses for Cramp Relief', 'Five gentle shapes to try tonight', 'fitness', 'u_alex', ['yoga', 'cramps', 'relief'], false),
      _Seed('Why Your Skin Changes With Your Cycle', 'The hormonal rhythm behind breakouts', 'hormones', 'u_emily', ['skin', 'acne', 'hormones'], false),
      _Seed('Mindful Journaling Through the Month', 'A prompt for every phase', 'mind', 'u_jord', ['journal', 'mindfulness'], false),
      _Seed('Hydration and Menstrual Flow', 'Small sips, real difference', 'cycle', 'u_maya', ['water', 'bloating'], false),
      _Seed('Strength Training in the Follicular Phase', 'Ride your energy peak', 'fitness', 'u_alex', ['strength', 'follicular'], false),
    ];

    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final author = _users.firstWhere((u) => u.id == s.authorId);
      final content = _articleBody(s.title, s.subtitle);
      final words = content.split(RegExp(r'\s+')).length;
      _blogs.add(Blog(
        id: 'b_${i + 1}',
        title: s.title,
        subtitle: s.subtitle,
        summary: _summaryFor(s.title),
        content: content,
        coverImageUrl: null,
        authorId: author.id,
        authorName: author.displayName,
        authorIsExpert: author.isExpert,
        categoryId: s.categoryId,
        tags: s.tags,
        readingTimeMinutes: (words / 200).ceil().clamp(2, 12),
        publishedAt: now.subtract(Duration(days: i * 2 + 1, hours: i)),
        updatedAt: now.subtract(Duration(days: i * 2 + 1)),
        isFeatured: s.featured,
        likeCount: 40 - i * 2 + (i % 3) * 5,
        commentCount: i % 4,
        viewCount: 900 - i * 40 + (i % 5) * 30,
      ));
    }

    // A couple of seeded comments on the first article.
    final first = _blogs.first;
    final jordan = _users.firstWhere((u) => u.id == 'u_jord');
    _comments.add(Comment(
      id: 'c_seed1',
      blogId: first.id,
      userId: jordan.id,
      authorName: jordan.displayName,
      content: 'This finally explained why heat helps me so much. Thank you!',
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(hours: 6)),
      likeCount: 4,
    ));
    _comments.add(Comment(
      id: 'c_seed2',
      blogId: first.id,
      userId: 'u_sarah',
      authorName: 'Dr. Sarah Wilson',
      authorAvatarUrl: null,
      content: 'So glad it helped — magnesium before bed is worth trying too.',
      createdAt: now.subtract(const Duration(hours: 5)),
      updatedAt: now.subtract(const Duration(hours: 5)),
      likeCount: 7,
    ));
    _blogs[0] = _blogs[0].copyWith(commentCount: 2);
  }

  String _summaryFor(String title) =>
      'A practical, evidence-informed look at ${title.toLowerCase()} — what\'s '
      'happening in your body and the small changes that make a real difference.';

  String _articleBody(String title, String subtitle) => '''$subtitle.

There's a quiet wisdom in your cycle. Once you understand the rhythm beneath it, the month stops feeling random and starts feeling readable. This piece walks through the essentials in plain language.

## What's really happening
Your hormones rise and fall in a predictable arc across the month. Those shifts touch far more than your period — they shape your energy, mood, appetite, sleep and skin. Naming the pattern is the first step to working with it.

## What helps
- Notice the signal early, before it peaks.
- Adjust one small habit — hydration, movement, or rest — rather than overhauling everything.
- Give changes a couple of cycles before judging them.

## Putting it into practice
Track how you feel for one full cycle. Look for the days that repeat. Then meet those days with a little extra care. Small, consistent adjustments compound into a noticeably gentler month.

Remember: this is general wellness guidance, not medical advice. If something feels off or pain disrupts your life, talk to a clinician you trust.''';
}

class _Seed {
  final String title;
  final String subtitle;
  final String categoryId;
  final String authorId;
  final List<String> tags;
  final bool featured;
  const _Seed(this.title, this.subtitle, this.categoryId, this.authorId,
      this.tags, this.featured);
}
