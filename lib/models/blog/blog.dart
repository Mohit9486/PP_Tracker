/// Visibility / lifecycle state of an article. Maps cleanly to a Firestore
/// enum field and lets us support drafts and archiving without separate tables.
enum BlogVisibility {
  draft, // not yet published; visible only to its author
  public, // live and listed
  hidden, // unlisted but reachable by direct link
  archived; // retired from feeds

  bool get isPublic => this == BlogVisibility.public;

  static BlogVisibility fromName(String? name) =>
      BlogVisibility.values.firstWhere(
        (v) => v.name == name,
        orElse: () => BlogVisibility.public,
      );
}

/// A wellness article.
///
/// Pure Dart + `toMap`/`fromMap` so swapping the mock repository for Firestore
/// is a serialization detail, not a model rewrite. Author display fields are
/// denormalized (Firestore-style) so feed cards render without extra reads;
/// per-user flags ([isBookmarked]/[isLikedByMe]) are view-state the repository
/// populates for the current user and are never persisted on the document.
class Blog {
  final String id;
  final String title;
  final String subtitle;
  final String summary;
  final String content;
  final String? coverImageUrl;

  // Author (denormalized for cheap reads; source of truth is the users collection)
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool authorIsExpert;

  final String categoryId;
  final List<String> tags;

  final int readingTimeMinutes;
  final DateTime publishedAt;
  final DateTime updatedAt;

  final bool isFeatured;
  final BlogVisibility visibility;

  // Aggregate counters (denormalized; incremented server-side later)
  final int likeCount;
  final int commentCount;
  final int viewCount;

  /// Forward-compatible bag for analytics / experimental backend fields.
  final Map<String, dynamic> metadata;

  // ---- Transient per-user view state (not serialized to the document) ----
  final bool isBookmarked;
  final bool isLikedByMe;

  const Blog({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.summary = '',
    required this.content,
    this.coverImageUrl,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorIsExpert = false,
    required this.categoryId,
    this.tags = const [],
    this.readingTimeMinutes = 1,
    required this.publishedAt,
    required this.updatedAt,
    this.isFeatured = false,
    this.visibility = BlogVisibility.public,
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.metadata = const {},
    this.isBookmarked = false,
    this.isLikedByMe = false,
  });

  bool get isDraft => visibility == BlogVisibility.draft;

  /// Simple popularity heuristic used to rank trending content.
  double get engagementScore =>
      likeCount * 2.0 + commentCount * 3.0 + viewCount * 0.4;

  Blog copyWith({
    String? title,
    String? subtitle,
    String? summary,
    String? content,
    String? coverImageUrl,
    String? authorName,
    String? authorAvatarUrl,
    bool? authorIsExpert,
    String? categoryId,
    List<String>? tags,
    int? readingTimeMinutes,
    DateTime? updatedAt,
    bool? isFeatured,
    BlogVisibility? visibility,
    int? likeCount,
    int? commentCount,
    int? viewCount,
    Map<String, dynamic>? metadata,
    bool? isBookmarked,
    bool? isLikedByMe,
  }) {
    return Blog(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      authorId: authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorIsExpert: authorIsExpert ?? this.authorIsExpert,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      publishedAt: publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      visibility: visibility ?? this.visibility,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      metadata: metadata ?? this.metadata,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  /// Persisted document shape. Transient view-state is intentionally excluded.
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'summary': summary,
        'content': content,
        'coverImageUrl': coverImageUrl,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'authorIsExpert': authorIsExpert,
        'categoryId': categoryId,
        'tags': tags,
        'readingTimeMinutes': readingTimeMinutes,
        'publishedAt': publishedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isFeatured': isFeatured,
        'visibility': visibility.name,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'viewCount': viewCount,
        'metadata': metadata,
      };

  factory Blog.fromMap(Map<String, dynamic> map) => Blog(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        subtitle: map['subtitle'] as String? ?? '',
        summary: map['summary'] as String? ?? '',
        content: map['content'] as String? ?? '',
        coverImageUrl: map['coverImageUrl'] as String?,
        authorId: map['authorId'] as String? ?? '',
        authorName: map['authorName'] as String? ?? 'Unknown',
        authorAvatarUrl: map['authorAvatarUrl'] as String?,
        authorIsExpert: map['authorIsExpert'] as bool? ?? false,
        categoryId: map['categoryId'] as String? ?? 'all',
        tags: (map['tags'] as List?)?.cast<String>() ?? const [],
        readingTimeMinutes: map['readingTimeMinutes'] as int? ?? 1,
        publishedAt: DateTime.tryParse(map['publishedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        isFeatured: map['isFeatured'] as bool? ?? false,
        visibility: BlogVisibility.fromName(map['visibility'] as String?),
        likeCount: map['likeCount'] as int? ?? 0,
        commentCount: map['commentCount'] as int? ?? 0,
        viewCount: map['viewCount'] as int? ?? 0,
        metadata: (map['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  @override
  bool operator ==(Object other) => other is Blog && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
