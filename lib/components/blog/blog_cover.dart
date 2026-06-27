import 'package:flutter/material.dart';
import 'package:pp_tracker/components/blog/blog_category_style.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/blog_category.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// Renders a blog's cover. Uses the network image when available, otherwise a
/// tasteful gradient keyed to the category colour with the category glyph —
/// so the hub looks polished even with no uploaded artwork (mock data).
class BlogCover extends StatelessWidget {
  final Blog blog;
  final BlogCategory category;
  final double? height;
  final double radius;
  final bool showGlyph;

  const BlogCover({
    super.key,
    required this.blog,
    required this.category,
    this.height,
    this.radius = AppRadius.md,
    this.showGlyph = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = category.color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: blog.coverImageUrl != null
            ? Image.network(
                blog.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _gradient(accent),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _gradient(accent),
              )
            : _gradient(accent),
      ),
    );
  }

  Widget _gradient(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.white, 0.15)!,
            Color.lerp(accent, AppColors.primaryDeep, 0.35)!,
          ],
        ),
      ),
      child: showGlyph
          ? Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -16,
                  child: Icon(
                    category.icon,
                    size: 110,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
