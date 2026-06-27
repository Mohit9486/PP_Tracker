/// Moderation / lifecycle status for a comment. Keeping deleted/flagged as
/// states (rather than hard-deleting) preserves reply threads and supports
/// future moderation tooling.
enum CommentStatus {
  visible,
  flagged, // reported, pending review
  hidden, // hidden by a moderator
  deleted; // tombstoned ("This comment was removed")

  static CommentStatus fromName(String? name) =>
      CommentStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => CommentStatus.visible,
      );
}

/// A comment on a blog. Supports threaded replies via [parentCommentId] and
/// carries denormalized author fields for cheap rendering, mirroring how this
/// would live as a Firestore subcollection (`blogs/{id}/comments`).
class Comment {
  final String id;
  final String blogId;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;

  /// Null for top-level comments; set to the parent's id for replies.
  final String? parentCommentId;

  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;

  final int likeCount;
  final int replyCount;
  final CommentStatus status;

  /// Transient: whether the current user has liked this comment.
  final bool isLikedByMe;

  final Map<String, dynamic> metadata;

  const Comment({
    required this.id,
    required this.blogId,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
    this.likeCount = 0,
    this.replyCount = 0,
    this.status = CommentStatus.visible,
    this.isLikedByMe = false,
    this.metadata = const {},
  });

  bool get isReply => parentCommentId != null;
  bool get isDeleted => status == CommentStatus.deleted;

  Comment copyWith({
    String? content,
    DateTime? updatedAt,
    bool? isEdited,
    int? likeCount,
    int? replyCount,
    CommentStatus? status,
    bool? isLikedByMe,
    Map<String, dynamic>? metadata,
  }) {
    return Comment(
      id: id,
      blogId: blogId,
      userId: userId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      parentCommentId: parentCommentId,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      status: status ?? this.status,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'blogId': blogId,
        'userId': userId,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'parentCommentId': parentCommentId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isEdited': isEdited,
        'likeCount': likeCount,
        'replyCount': replyCount,
        'status': status.name,
        'metadata': metadata,
      };

  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
        id: map['id'] as String,
        blogId: map['blogId'] as String,
        userId: map['userId'] as String,
        authorName: map['authorName'] as String? ?? 'Unknown',
        authorAvatarUrl: map['authorAvatarUrl'] as String?,
        parentCommentId: map['parentCommentId'] as String?,
        content: map['content'] as String? ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        isEdited: map['isEdited'] as bool? ?? false,
        likeCount: map['likeCount'] as int? ?? 0,
        replyCount: map['replyCount'] as int? ?? 0,
        status: CommentStatus.fromName(map['status'] as String?),
        metadata: (map['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  @override
  bool operator ==(Object other) => other is Comment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
