import 'package:collection/collection.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/blog_category.dart';
import 'package:pp_tracker/models/blog/blog_models.dart';
import 'package:pp_tracker/models/blog/comment.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';

class MockBlogRepository implements BlogRepository {
  MockBlogRepository() {
    _seed();
  }

  final List<AppUser> _users = [];
  final List<BlogCategory> _categories = [];
  final List<Blog> _blogs = [];
  final List<Comment> _comments = [];
  final List<BlogReport> _reports = [];

  final Map<String, Set<String>> _bookmarks = {};
  final Map<String, Set<String>> _likes = {};
  final Map<String, Set<String>> _commentLikes = {};
  final Map<String, Map<String, ReadingProgress>> _progress = {};

  static const _latency = Duration(milliseconds: 350);
  Future<T> _io<T>(T value) => Future.delayed(_latency, () => value);

  Blog _decorate(Blog b, String? userId) {
    if (userId == null) return b;
    return b.copyWith(
      isBookmarked: _bookmarks[userId]?.contains(b.id) ?? false,
      isLikedByMe: _likes[userId]?.contains(b.id) ?? false,
    );
  }

  String? _currentUserId;

  @override
  void setCurrentUser(String? userId) => _currentUserId = userId;

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
            b.sections.any((s) => s.body.toLowerCase().contains(q)) ||
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

  @override
  Future<void> reportBlog(BlogReport report) {
    _reports.add(report);
    return _io(null);
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

  Comment _decorateComment(Comment c, String? userId) {
    if (userId == null) return c;
    return c.copyWith(
      isLikedByMe: _commentLikes[userId]?.contains(c.id) ?? false,
    );
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

  @override
  Future<AppUser?> fetchUser(String id) =>
      _io(_users.where((u) => u.id == id).firstOrNull);

  void _seed() {
    final now = DateTime.now();
    final petalId = 'u_petal';
    final petal = AppUser(
      id: petalId,
      displayName: 'Petal',
      isExpert: true,
      credentials: 'Wellness Platform',
      bio: 'Verified educational content for cycle health.',
      joinedAt: now.subtract(const Duration(days: 500)),
    );
    _users.add(petal);

    _categories.addAll(const [
      BlogCategory(id: 'cycle', name: 'Cycle', slug: 'cycle', colorValue: 0xFFE26D7E, iconKey: 'cycle', sortOrder: 0),
      BlogCategory(id: 'hormones', name: 'Hormones', slug: 'hormones', colorValue: 0xFF9B8AC9, iconKey: 'hormones', sortOrder: 1),
      BlogCategory(id: 'nutrition', name: 'Nutrition', slug: 'nutrition', colorValue: 0xFF5FB49C, iconKey: 'nutrition', sortOrder: 2),
      BlogCategory(id: 'mind', name: 'Mental Health', slug: 'mind', colorValue: 0xFF7FB0E0, iconKey: 'mind', sortOrder: 3),
      BlogCategory(id: 'fitness', name: 'Fitness', slug: 'fitness', colorValue: 0xFFE0A24E, iconKey: 'fitness', sortOrder: 4),
    ]);

    _addBlog(
      id: 'b_1',
      title: 'The Biological Clock: Understanding Your Infradian Rhythm',
      subtitle: 'The second masterclock that governs your life',
      summary: 'Imagine your body has two clocks. One is the familiar 24-hour circadian rhythm. But for those with a menstrual cycle, there’s a second, quieter masterclock: the infradian rhythm.',
      sections: [
        BlogSection(
          title: 'The Monthly Masterclock',
          body: 'While the world is obsessed with the 24-hour cycle, half the population operates on a secondary rhythm that spans roughly 28 to 30 days. This is the **infradian rhythm**. It isn\'t just about reproduction; it’s a systemic biological mandate that influences your metabolism, immune system, and neurochemistry. In men, hormone levels are relatively "flat" daily. In women, they follow a massive, sweeping arc that changes the very landscape of your brain and body every week.',
        ),
        BlogSection(
          title: 'The Four Seasons of You',
          body: 'Think of your cycle as a year condensed into a month.\n\n- **Winter (Menstrual Phase)**: Progesterone and estrogen crash. The body focuses on shedding and renewal. Serotonin is low, leading to a natural desire for solitude and rest.\n- **Spring (Follicular Phase)**: Estrogen begins its climb. Serotonin and dopamine boost, bringing cognitive clarity and social energy.\n- **Summer (Ovulatory Phase)**: The peak. Communication skills and libido are at their maximum as Luteinizing Hormone (LH) surges.\n- **Autumn (Luteal Phase)**: Progesterone becomes the dominant "stabilizer." Metabolism speeds up, requiring more calories, while the mind begins to turn inward.',
          sectionReferences: [
            BlogReference(title: 'The Ovarian Cycle as an Infradian Rhythm', source: 'NIH / PubMed', url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10300078/'),
          ],
        ),
        BlogSection(
          title: 'The Medical Blueprint',
          body: 'This rhythm is driven by the **Hypothalamic-Pituitary-Ovarian (HPO) axis**. The hypothalamus releases GnRH, prompting the pituitary to secrete FSH and LH. This orchestration is sensitive to external factors like light and stress. In fact, research shows that women isolated from natural light see their infradian rhythms shift, proving that our environment is a "zeitgeber" (time-giver) for our monthly health.',
          sectionReferences: [
            BlogReference(title: 'Circadian and Infradian Regulation', source: 'Endocrine Society', url: 'https://academic.oup.com/jcem/article/104/8/3359/5370438'),
          ],
        ),
      ],
      globalRefs: [
        BlogReference(title: 'Understanding the Menstrual Cycle', source: 'Cleveland Clinic', url: 'https://my.clevelandclinic.org/health/articles/10132-menstrual-cycle'),
      ],
      author: petal,
      categoryId: 'cycle',
      tags: ['biohacking', 'hormones', 'science'],
      isFeatured: true,
    );

    _addBlog(
      id: 'b_2',
      title: 'Cycle Syncing: The Science of Movement and Nutrition',
      subtitle: 'Aligning your lifestyle with your internal biology',
      summary: 'Tailoring your exercise and plate to your hormonal fluctuations isn\'t just a trend—it’s supported by metabolic research.',
      sections: [
        BlogSection(
          title: 'Metabolic Substrate Utilization',
          body: 'Your body doesn\'t burn fuel the same way on Day 5 as it does on Day 25. During the **Follicular phase**, rising estrogen makes you more "insulin sensitive." This means your body is highly efficient at using stored carbohydrates for energy. This is the time to push: high-intensity interval training (HIIT) and heavy lifting are perfectly timed for when your muscles can recover fastest.',
        ),
        BlogSection(
          title: 'The Luteal Shift',
          body: 'Once you pass ovulation and enter the **Luteal phase**, progesterone takes over. This hormone is catabolic—it increases the breakdown of muscle and raises your core body temperature. High-intensity work feels significantly harder because your cardiovascular strain is higher. Your body shifts to "fat-burning" mode (glycogen sparing). Steady-state aerobic work, Pilates, and swimming are better suited for this biological environment.',
          sectionReferences: [
            BlogReference(title: 'Metabolic utilization across the cycle', source: 'Sports Medicine', publishedYear: '2010'),
          ],
        ),
        BlogSection(
          title: 'Eating for the Phase',
          body: '- **Menstrual**: Replenish iron (red meat, lentils) and pair with Vitamin C (peppers) to boost absorption. Heavy bleeding can cost you 1.6mg of iron daily.\n- **Follicular**: Focus on complex carbs and fiber to support rising energy and estrogen clearance.\n- **Ovulatory**: Focus on cruciferous vegetables (broccoli) to help the liver process peak estrogen levels.\n- **Luteal**: Your metabolic rate increases by 5-10% (150-300 calories). Focus on magnesium-rich dark chocolate and seeds to stabilize the mood drops associated with falling serotonin.',
        ),
      ],
      globalRefs: [
        BlogReference(title: 'Cycle Syncing Guide', source: 'Cleveland Clinic', url: 'https://my.clevelandclinic.org/health/articles/cycle-syncing'),
        BlogReference(title: 'Nutrition and Exercise for your Cycle', source: 'Mayo Clinic', url: 'https://www.mayoclinic.org/healthy-lifestyle/womens-health/in-depth/menstrual-cycle/art-20047186'),
      ],
      author: petal,
      categoryId: 'nutrition',
      tags: ['fitness', 'nutrition', 'metabolism'],
    );

    _addBlog(
      id: 'b_3',
      title: 'The Stress Hijack: How Cortisol Steals Your Cycle',
      subtitle: 'The cross-talk between survival and reproduction',
      summary: 'When your brain perceives a threat, it prioritizes your survival over your period. Here is how stress-induced amenorrhea works.',
      sections: [
        BlogSection(
          title: 'HPA vs. HPG Axis',
          body: 'Your brain has two primary communication lines: the HPA axis (Stress) and the HPG axis (Reproduction). In a state of high stress, the HPA axis releases **Corticotropin-Releasing Hormone (CRH)**. CRH and cortisol act as a biological "brake" on the reproductive system. They inhibit the master switch called **Kisspeptin**, which is responsible for triggering the release of GnRH. Without GnRH, your cycle essentially stays in a "holding pattern."',
        ),
        BlogSection(
          title: 'Blunting the LH Surge',
          body: 'Even if your cycle starts, high cortisol can blunt the **Luteinizing Hormone (LH) surge**. This surge is the essential "starting gun" for ovulation. If the LH surge is weak or non-existent, the follicle won\'t rupture, ovulation is skipped, and you won\'t produce the progesterone needed to keep your mood stable and your lining healthy.',
          sectionReferences: [
            BlogReference(title: 'Glucocorticoids and fertility', author: 'Whirledge & Cidlowski', source: 'Minerva Endocrinologica', publishedYear: '2010'),
          ],
        ),
        BlogSection(
          title: 'The Myth of the "Progesterone Steal"',
          body: 'You may have heard that the body "steals" progesterone to make cortisol. Medical reality is different: the adrenals and ovaries have independent precursor pools. You have low progesterone during stress not because it was "stolen," but because **ovulation never happened**. No ovulation means no corpus luteum, which means no progesterone.',
          sectionReferences: [
            BlogReference(title: 'Functional Hypothalamic Amenorrhea', source: 'New England Journal of Medicine', url: 'https://pubmed.ncbi.nlm.nih.gov/20647201/'),
          ],
        ),
      ],
      author: petal,
      categoryId: 'hormones',
      tags: ['stress', 'cortisol', 'medical-science'],
    );

    _addBlog(
      id: 'b_4',
      title: 'PCOS and Insulin Resistance: Rewriting the Narrative',
      subtitle: 'Beyond "cysts" and toward metabolic health',
      summary: 'PCOS is increasingly recognized as a polyendocrine metabolic disorder. Understanding the insulin-androgen axis is the key to management.',
      sections: [
        BlogSection(
          title: 'The Insulin-Androgen Axis',
          body: 'Insulin resistance is the driver for 70-80% of PCOS cases. When your cells stop responding to insulin, your pancreas pumps out more. This excess insulin acts as a "co-gonadotropin"—it tells your ovaries to produce more **testosterone**. This excess testosterone is what prevents follicles from maturing, leading to the "pearl necklace" appearance on ultrasounds and symptoms like hirsutism and acne.',
        ),
        BlogSection(
          title: 'The SHBG Problem',
          body: 'High insulin also suppresses **Sex Hormone-Binding Globulin (SHBG)** in the liver. SHBG is like a "sponge" that mops up excess testosterone. When it\'s low, you have more "free" (active) testosterone circulating, which wreaks havoc on your skin and hair follicles.',
          sectionReferences: [
            BlogReference(title: 'Insulin Resistance and PCOS', source: 'PubMed / NIH', url: 'https://pubmed.ncbi.nlm.nih.gov/3309040/'),
          ],
        ),
        BlogSection(
          title: 'A Multi-Faceted Treatment',
          body: 'Management focuses on insulin sensitivity. **Metformin** or **Inositol** (a B-vitamin derivative) help cells respond to insulin. Lifestyle changes like low-glycemic eating and strength training help the muscles use glucose more effectively, naturally lowering the need for excess insulin and breaking the cycle of androgen production.',
          sectionReferences: [
            BlogReference(title: 'Metformin in PCOS treatment', source: 'PubMed', url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC3475283/'),
          ],
        ),
      ],
      globalRefs: [
        BlogReference(title: 'PCOS Overview', source: 'Cleveland Clinic', url: 'https://my.clevelandclinic.org/health/diseases/8316-polycystic-ovary-syndrome-pcos'),
      ],
      author: petal,
      categoryId: 'cycle',
      tags: ['PCOS', 'insulin', 'metabolic-health'],
    );

    _addBlog(
      id: 'b_5',
      title: 'The Gut-Hormone Axis: Why Your Microbiome Controls Your Period',
      subtitle: 'Understanding the estrobolome and estrogen recycling',
      summary: 'Your gut isn\'t just for digestion—it’s a secondary control center for your hormones. Learn why fiber is your best friend.',
      sections: [
        BlogSection(
          title: 'The Estrobolome',
          body: 'The **estrobolome** is a specific collection of gut bacteria that can metabolize and recycle estrogen. Normally, your liver "packages" used estrogen for export. But if your gut microbiome is imbalanced, certain bacteria produce an enzyme called **beta-glucuronidase**. This enzyme "unboxes" the estrogen, allowing it to be reabsorbed into your bloodstream. This contributes to "estrogen dominance," leading to heavier periods and worse PMS.',
        ),
        BlogSection(
          title: 'Fiber: The Estrogen Sweep',
          body: 'Fiber regulates estrogen in three ways: it inhibits the beta-glucuronidase enzyme, it physically binds to estrogen to "sweep" it out, and it increases transit speed. Research shows that women consuming 25-35g of fiber daily have significantly lower circulating estrogen levels than those on low-fiber diets.',
          sectionReferences: [
            BlogReference(title: 'Estrobolome and Estrogen Homeostasis', author: 'Plottel & Blaser', source: 'Maturitas', publishedYear: '2011'),
            BlogReference(title: 'Fiber and Estradiol', source: 'American Journal of Clinical Nutrition', url: 'https://pubmed.ncbi.nlm.nih.gov/19692496/'),
          ],
        ),
      ],
      author: petal,
      categoryId: 'nutrition',
      tags: ['gut-health', 'microbiome', 'estrogen'],
    );

    _addBlog(
      id: 'b_6',
      title: 'PMDD: Beyond the Blues - The Science of Cellular Sensitivity',
      subtitle: 'It isn\'t a mood disorder; it\'s a neuroendocrine disorder',
      summary: 'PMDD affects 3-8% of women. It isn\'t caused by an "imbalance" of hormones, but an abnormal brain response to normal changes.',
      sections: [
        BlogSection(
          title: 'Pathological Sensitivity',
          body: 'Women with PMDD have normal levels of estrogen and progesterone. The problem is in the **GABA-A receptors** in the brain. Progesterone is metabolized into a calming neurosteroid called **allopregnanolone**. In the PMDD brain, the receptors fail to adapt to this neurosteroid, causing it to have a paradoxical effect: instead of calming the brain, it triggers rage, despair, or intense anxiety.',
        ),
        BlogSection(
          title: 'The Genetic Signature',
          body: 'A landmark NIH study in 2017 found that women with PMDD have a distinct genetic complex called **ESC/E(Z)**. This complex regulates how cells respond to sex hormones. This means PMDD is literally written into the cellular signature of those who suffer from it.',
          sectionReferences: [
            BlogReference(title: 'PMDD Sensitivity Hypothesis', source: 'Nature Molecular Psychiatry', url: 'https://www.nature.com/articles/mp2016229'),
          ],
        ),
        BlogSection(
          title: 'Treatment Truths',
          body: 'SSRIs like Zoloft or Prozac are the gold standard. Interestingly, for PMDD, they often work within **hours** rather than weeks, because they act on neurosteroid modulation rather than just serotonin reuptake. Calcium (1200mg/day) is one of the only supplements with strong clinical backing for symptom reduction.',
          sectionReferences: [
            BlogReference(title: 'Management of PMDD', source: 'APA / DSM-5', url: 'https://www.psychiatry.org/patients-families/pmms'),
          ],
        ),
      ],
      author: petal,
      categoryId: 'mind',
      tags: ['PMDD', 'mental-health', 'neuroscience'],
    );

    _addBlog(
      id: 'b_7',
      title: 'Navigating the Great Transition: Perimenopause and Menopause',
      subtitle: 'Understanding the STRAW criteria and HRT',
      summary: 'Menopause isn\'t a single event; it\'s a 7-10 year transition. Here is the medical roadmap for the journey.',
      sections: [
        BlogSection(
          title: 'The Stages of Transition',
          body: 'Clinicians use the **STRAW+10 criteria** to track the transition. **Early Perimenopause** starts with subtle cycle irregularities (differences of 7+ days). **Late Perimenopause** is marked by intervals of 60+ days without a period. This is when symptoms like hot flashes and night sweats usually peak as estrogen begins its erratic final surges and drops.',
        ),
        BlogSection(
          title: 'HRT: Benefits and Risks',
          body: 'The 2022 North American Menopause Society (NAMS) position statement is clear: for healthy women under 60 or within 10 years of menopause, the benefits of Hormone Replacement Therapy (HRT) usually outweigh the risks. HRT is the most effective treatment for vasomotor symptoms and protects against osteoporosis.',
          sectionReferences: [
            BlogReference(title: 'NAMS Position Statement 2022', source: 'Menopause Journal', url: 'https://pubmed.ncbi.nlm.nih.gov/35797481/'),
          ],
        ),
      ],
      author: petal,
      categoryId: 'hormones',
      tags: ['menopause', 'aging', 'HRT'],
    );

    _addBlog(
      id: 'b_8',
      title: 'Fertility Awareness Method: Decoding Your Body\'s Language',
      subtitle: 'Natural family planning based on biological markers',
      summary: 'FAM is 99% effective with perfect use. Learn the science of tracking BBT and cervical mucus.',
      sections: [
        BlogSection(
          title: 'The Three Biomarkers',
          body: '- **Cervical Mucus**: Rising estrogen makes mucus clear and stretchy (like egg whites), allowing sperm to survive for 5 days. This is the "opening" of the fertile window.\n- **Basal Body Temperature (BBT)**: Progesterone raises your baseline temp by 0.5°F. A "thermal shift" confirms that ovulation has already occurred.\n- **LH Strips**: Detect the hormone surge that triggers the egg release within 24-36 hours.',
        ),
        BlogSection(
          title: 'Perfect vs. Typical Use',
          body: 'The Symptothermal method (mucus + temp) has a failure rate of 0.4% with perfect use—comparable to the pill. However, typical use failure is closer to 2-10% because it requires daily consistency and understanding the biological rules.',
          sectionReferences: [
            BlogReference(title: 'Effectiveness of FABMs', source: 'Obstetrics & Gynecology', url: 'https://pubmed.ncbi.nlm.nih.gov/30095777/'),
          ],
        ),
      ],
      author: petal,
      categoryId: 'cycle',
      tags: ['fertility', 'FAM', 'NFP'],
    );

    _addBlog(
      id: 'b_9',
      title: 'The Iron Deficit: Why "Normal" Isn\'t Enough for Fatigue',
      subtitle: 'Understanding Non-Anemic Iron Deficiency (NAID)',
      summary: 'You can have normal hemoglobin and still be profoundly exhausted. Learn why ferritin is the real number to watch.',
      sections: [
        BlogSection(
          title: 'Beyond Oxygen Transport',
          body: 'We think of iron as just "blood," but it’s actually a rate-limiting factor for **mitochondrial energy production** and neurotransmitter synthesis (dopamine and serotonin). If your iron stores are low, your mitochondria literally cannot produce enough ATP (energy), even if your oxygen levels are perfect.',
        ),
        BlogSection(
          title: 'The Ferritin Threshold',
          body: 'Many labs say 15 ng/mL of ferritin is "normal." But medical research shows premenopausal women often experience fatigue, brain fog, and restless legs until their ferritin is **above 50 ng/mL**. Heavy menstrual bleeding (HMB) is the primary cause of this depletion.',
          sectionReferences: [
            BlogReference(title: 'Iron therapy for non-anemic women', source: 'BMJ / Lancet', url: 'https://pubmed.ncbi.nlm.nih.gov/22777991/'),
          ],
        ),
        BlogSection(
          title: 'Strategic Supplementation',
          body: 'Taking iron every **other** day has been shown to be just as effective as daily dosing, with fewer stomach side effects, because it prevents the rise of hepcidin—a hormone that blocks iron absorption.',
          sectionReferences: [
            BlogReference(title: 'Alternate-day iron dosing', source: 'Lancet Haematology', publishedYear: '2017'),
          ],
        ),
      ],
      author: petal,
      categoryId: 'nutrition',
      tags: ['iron', 'fatigue', 'wellness'],
    );

    _addBlog(
      id: 'b_10',
      title: 'The Sleep-Hormone Connection: Why Your Period Needs Rest',
      subtitle: 'Melatonin, progesterone, and the HPO axis',
      summary: 'One night of poor sleep can disrupt your hormones for days. Learn why sleep hygiene is cycle hygiene.',
      sections: [
        BlogSection(
          title: 'The Melatonin-Progesterone Link',
          body: 'Melatonin and progesterone rise in tandem during your luteal phase. Melatonin acts as an ovarian antioxidant and a "pacemaker" for the cycle. Suppressing melatonin with late-night light exposure or poor sleep directly impairs progesterone production.',
        ),
        BlogSection(
          title: 'Cortisol vs. Ovulation',
          body: 'Sleep deprivation elevates cortisol. High cortisol inhibits the mid-cycle LH surge. This is why high-stress weeks or travel across time zones often result in a "late" or "missed" period.',
          sectionReferences: [
            BlogReference(title: 'Sleep and the Menstrual Cycle', source: 'Sleep Medicine Clinics', url: 'https://pubmed.ncbi.nlm.nih.gov/30098748/'),
          ],
        ),
      ],
      author: petal,
      categoryId: 'fitness',
      tags: ['sleep', 'rest', 'circadian-rhythm'],
    );
  }

  void _addBlog({
    required String id,
    required String title,
    required String subtitle,
    required String summary,
    required List<BlogSection> sections,
    List<BlogReference> globalRefs = const [],
    required AppUser author,
    required String categoryId,
    required List<String> tags,
    bool isFeatured = false,
  }) {
    final now = DateTime.now();
    _blogs.add(Blog(
      id: id,
      title: title,
      subtitle: subtitle,
      summary: summary,
      sections: sections,
      globalReferences: globalRefs,
      authorId: author.id,
      authorName: author.displayName,
      authorIsExpert: author.isExpert,
      categoryId: categoryId,
      tags: tags,
      readingTimeMinutes: (sections.map((s) => s.body).join().split(' ').length / 200).ceil().clamp(3, 15),
      publishedAt: now.subtract(Duration(days: int.parse(id.split('_')[1]))),
      updatedAt: now,
      lastVerifiedAt: now.subtract(const Duration(days: 1)),
      isFeatured: isFeatured,
      likeCount: 50 + int.parse(id.split('_')[1]) * 15,
      viewCount: 500 + int.parse(id.split('_')[1]) * 120,
    ));
  }
}
