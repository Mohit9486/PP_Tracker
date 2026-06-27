/// A shared user entity used across the whole app (blogs today, more later).
///
/// Pure Dart with no Flutter dependency so it can be unit-tested and mapped
/// straight to/from a Firestore document. When Firebase Auth is added, its
/// `User` becomes the auth identity and this remains the app-level profile —
/// hence the `AppUser` name (avoids clashing with `firebase_auth`'s `User`).
class AppUser {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;

  /// Marks verified experts (doctors, dietitians) for the "Expert advice" rail.
  final bool isExpert;

  /// e.g. "OB-GYN", "Registered Dietitian". Shown beside expert names.
  final String? credentials;

  final DateTime joinedAt;

  /// Free-form bag for forward-compatible backend fields (followers, roles…)
  /// so adding columns later doesn't break deserialization.
  final Map<String, dynamic> metadata;

  const AppUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.isExpert = false,
    this.credentials,
    required this.joinedAt,
    this.metadata = const {},
  });

  /// Initials for avatar placeholders, e.g. "Sarah Wilson" -> "SW".
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  AppUser copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isExpert,
    String? credentials,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isExpert: isExpert ?? this.isExpert,
      credentials: credentials ?? this.credentials,
      joinedAt: joinedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'isExpert': isExpert,
        'credentials': credentials,
        'joinedAt': joinedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String,
        displayName: map['displayName'] as String? ?? 'Unknown',
        avatarUrl: map['avatarUrl'] as String?,
        bio: map['bio'] as String?,
        isExpert: map['isExpert'] as bool? ?? false,
        credentials: map['credentials'] as String?,
        joinedAt: DateTime.tryParse(map['joinedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        metadata: (map['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  @override
  bool operator ==(Object other) => other is AppUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
