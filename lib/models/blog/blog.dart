import 'package:pp_tracker/models/blog/blog_models.dart';

/// Visibility / lifecycle state of an article.
enum BlogVisibility {
  draft, // not yet published; visible only to its author
  pendingReview, // awaiting AI/human verification
  public, // live and listed
  hidden, // unlisted but reachable by direct link
  archived, // retired from feeds
  rejected; // failed moderation/verification

  bool get isPublic => this == BlogVisibility.public;

  static BlogVisibility fromName(String? name) =>
      BlogVisibility.values.firstWhere(
        (v) => v.name == name,
        orElse: () => BlogVisibility.public,
      );
}

/// A professional health & wellness article.
class Blog {
  final String id;
  final String title;
  final String subtitle;
  final String summary;
  
  /// Structured content for better UI rendering and section-level references.
  final List<BlogSection> sections;
  
  /// Global references that apply to the entire article.
  final List<BlogReference> globalReferences;

  final String? coverImageUrl;

  // Author details (denormalized)
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool authorIsExpert;

  final String categoryId;
  final List<String> tags;

  final int readingTimeMinutes;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final DateTime? lastVerifiedAt;

  final bool isFeatured;
  final BlogVisibility visibility;

  // Aggregate counters
  final int likeCount;
  final int commentCount;
  final int viewCount;

  final Map<String, dynamic> metadata;

  // Transient view state
  final bool isBookmarked;
  final bool isLikedByMe;

  const Blog({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.summary = '',
    this.sections = const [],
    this.globalReferences = const [],
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
    this.lastVerifiedAt,
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

  /// Joins section bodies for simple text searches or fallback rendering.
  String get content => sections.map((s) => s.body).join('\n\n');

  double get engagementScore =>
      likeCount * 2.0 + commentCount * 3.0 + viewCount * 0.4;

  Blog copyWith({
    String? title,
    String? subtitle,
    String? summary,
    List<BlogSection>? sections,
    List<BlogReference>? globalReferences,
    String? coverImageUrl,
    String? authorName,
    String? authorAvatarUrl,
    bool? authorIsExpert,
    String? categoryId,
    List<String>? tags,
    int? readingTimeMinutes,
    DateTime? updatedAt,
    DateTime? lastVerifiedAt,
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
      sections: sections ?? this.sections,
      globalReferences: globalReferences ?? this.globalReferences,
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
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'summary': summary,
        'sections': sections.map((s) => s.toMap()).toList(),
        'globalReferences': globalReferences.map((r) => r.toMap()).toList(),
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
        'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
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
        sections: (map['sections'] as List?)
                ?.map((s) => BlogSection.fromMap(s as Map<String, dynamic>))
                .toList() ??
            const [],
        globalReferences: (map['globalReferences'] as List?)
                ?.map((r) => BlogReference.fromMap(r as Map<String, dynamic>))
                .toList() ??
            const [],
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
        lastVerifiedAt: DateTime.tryParse(map['lastVerifiedAt'] as String? ?? ''),
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
