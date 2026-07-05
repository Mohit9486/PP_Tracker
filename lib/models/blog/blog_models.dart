import 'package:pp_tracker/models/blog/app_user.dart';

/// A professional author entity.
///
/// Extends the base user with content-specific metadata like bio and expertise.
class BlogAuthor {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final bool isExpert;
  final String? credentials;
  final List<String> socialLinks;

  const BlogAuthor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.isExpert = false,
    this.credentials,
    this.socialLinks = const [],
  });

  factory BlogAuthor.fromAppUser(AppUser user) => BlogAuthor(
        id: user.id,
        name: user.displayName,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        isExpert: user.isExpert,
        credentials: user.credentials,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'isExpert': isExpert,
        'credentials': credentials,
        'socialLinks': socialLinks,
      };

  factory BlogAuthor.fromMap(Map<String, dynamic> map) => BlogAuthor(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarUrl: map['avatarUrl'] as String?,
        bio: map['bio'] as String?,
        isExpert: map['isExpert'] as bool? ?? false,
        credentials: map['credentials'] as String?,
        socialLinks: (map['socialLinks'] as List?)?.cast<String>() ?? const [],
      );
}

/// A structured citation for content authenticity.
class BlogReference {
  final String title;
  final String? author;
  final String source; // e.g., "The Lancet", "WHO", "PubMed"
  final String? url;
  final String? publishedYear;

  const BlogReference({
    required this.title,
    this.author,
    required this.source,
    this.url,
    this.publishedYear,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'author': author,
        'source': source,
        'url': url,
        'publishedYear': publishedYear,
      };

  factory BlogReference.fromMap(Map<String, dynamic> map) => BlogReference(
        title: map['title'] as String,
        author: map['author'] as String?,
        source: map['source'] as String,
        url: map['url'] as String?,
        publishedYear: map['publishedYear'] as String?,
      );
}

/// A section of a blog post to support rich visual hierarchy.
class BlogSection {
  final String? title;
  final String body; // Supports Markdown
  final List<BlogReference> sectionReferences;

  const BlogSection({
    this.title,
    required this.body,
    this.sectionReferences = const [],
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'sectionReferences': sectionReferences.map((r) => r.toMap()).toList(),
      };

  factory BlogSection.fromMap(Map<String, dynamic> map) => BlogSection(
        title: map['title'] as String?,
        body: map['body'] as String,
        sectionReferences: (map['sectionReferences'] as List?)
                ?.map((r) => BlogReference.fromMap(r as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// User report model for content moderation.
enum ReportReason {
  incorrect,
  spam,
  offensive,
  duplicate,
  copyright,
  misleading,
  other;

  static ReportReason fromName(String name) =>
      ReportReason.values.firstWhere((r) => r.name == name, orElse: () => ReportReason.other);
}

class BlogReport {
  final String id;
  final String blogId;
  final String reporterId;
  final ReportReason reason;
  final String? detail;
  final DateTime createdAt;

  const BlogReport({
    required this.id,
    required this.blogId,
    required this.reporterId,
    required this.reason,
    this.detail,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'blogId': blogId,
        'reporterId': reporterId,
        'reason': reason.name,
        'detail': detail,
        'createdAt': createdAt.toIso8601String(),
      };
}
