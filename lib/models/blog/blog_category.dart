/// A content category for blogs (e.g. "Hormones", "Nutrition").
///
/// Pure data. Visuals (colour/icon) are kept as a serializable [colorValue]
/// (ARGB int) and [iconKey] (string), resolved to Flutter `Color`/`IconData`
/// in the UI layer — so the model stays backend- and test-friendly.
class BlogCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final int colorValue; // ARGB, e.g. 0xFFE26D7E
  final String iconKey; // resolved by the UI (see blog_category_style.dart)
  final int sortOrder;

  const BlogCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.colorValue,
    required this.iconKey,
    this.sortOrder = 0,
  });

  /// Synthetic "All" pseudo-category used by the filter rail.
  static const BlogCategory all = BlogCategory(
    id: 'all',
    name: 'All',
    slug: 'all',
    colorValue: 0xFFB76E84,
    iconKey: 'grid',
    sortOrder: -1,
  );

  bool get isAll => id == all.id;

  BlogCategory copyWith({
    String? name,
    String? description,
    int? colorValue,
    String? iconKey,
    int? sortOrder,
  }) {
    return BlogCategory(
      id: id,
      name: name ?? this.name,
      slug: slug,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'colorValue': colorValue,
        'iconKey': iconKey,
        'sortOrder': sortOrder,
      };

  factory BlogCategory.fromMap(Map<String, dynamic> map) => BlogCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        slug: map['slug'] as String,
        description: map['description'] as String?,
        colorValue: map['colorValue'] as int? ?? 0xFFB76E84,
        iconKey: map['iconKey'] as String? ?? 'grid',
        sortOrder: map['sortOrder'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) => other is BlogCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
