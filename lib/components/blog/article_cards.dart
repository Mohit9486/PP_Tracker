import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pp_tracker/components/app_card.dart';
import 'package:pp_tracker/components/blog/blog_category_style.dart';
import 'package:pp_tracker/components/blog/blog_cover.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/blog_category.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// A small "5 min read" / view-count metadata strip.
class _MetaRow extends StatelessWidget {
  final Blog blog;
  final Color? color;
  const _MetaRow({required this.blog, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textTertiary;
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 13, color: c),
        const SizedBox(width: 4),
        Text('${blog.readingTimeMinutes} min', style: AppText.caption.copyWith(color: c)),
        const SizedBox(width: 10),
        Icon(Icons.favorite_rounded, size: 13, color: c),
        const SizedBox(width: 4),
        Text('${blog.likeCount}', style: AppText.caption.copyWith(color: c)),
        const SizedBox(width: 10),
        Icon(Icons.remove_red_eye_rounded, size: 13, color: c),
        const SizedBox(width: 4),
        Text('${blog.viewCount}', style: AppText.caption.copyWith(color: c)),
      ],
    );
  }
}

class BookmarkButton extends StatelessWidget {
  final bool bookmarked;
  final VoidCallback onTap;
  final Color background;
  final Color iconColor;
  const BookmarkButton({
    super.key,
    required this.bookmarked,
    required this.onTap,
    this.background = AppColors.surface,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedSwitcher(
            duration: AppDuration.fast,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              key: ValueKey(bookmarked),
              size: 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Large hero card for the featured rail.
class FeaturedArticleCard extends StatelessWidget {
  final Blog blog;
  final BlogCategory category;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const FeaturedArticleCard({
    super.key,
    required this.blog,
    required this.category,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BlogCover(blog: blog, category: category, radius: AppRadius.lg),
              // Legibility scrim
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Tag(label: 'Featured', color: Colors.white.withValues(alpha: 0.22), textColor: Colors.white),
                        const SizedBox(width: AppSpacing.xs),
                        _Tag(label: category.name, color: Colors.white.withValues(alpha: 0.22), textColor: Colors.white),
                        const Spacer(),
                        BookmarkButton(
                          bookmarked: blog.isBookmarked,
                          onTap: onBookmark,
                          background: Colors.white.withValues(alpha: 0.22),
                          iconColor: Colors.white,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'By ${blog.authorName}',
                            style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ),
                        if (blog.authorIsExpert) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 14, color: Colors.white),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MetaRow(blog: blog, color: Colors.white.withValues(alpha: 0.85)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width row card used in the main feed.
class ArticleListCard extends StatelessWidget {
  final Blog blog;
  final BlogCategory category;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const ArticleListCard({
    super.key,
    required this.blog,
    required this.category,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: BlogCover(blog: blog, category: category),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Tag(label: category.name, color: AppColors.alpha(category.color, 0.14), textColor: category.color),
                    const Spacer(),
                    if (blog.authorIsExpert)
                      const Icon(Icons.verified_user_rounded,
                          size: 15, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  blog.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h3,
                ),
                const SizedBox(height: 6),
                _MetaRow(blog: blog),
              ],
            ),
          ),
          BookmarkButton(
            bookmarked: blog.isBookmarked,
            onTap: onBookmark,
            background: AppColors.surfaceAlt,
          ),
        ],
      ),
    );
  }
}

/// Compact card for the horizontal trending / recommended carousels.
class TrendingCard extends StatelessWidget {
  final Blog blog;
  final BlogCategory category;
  final VoidCallback onTap;
  final int? rank;

  const TrendingCard({
    super.key,
    required this.blog,
    required this.category,
    required this.onTap,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 210,
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: BlogCover(blog: blog, category: category)),
                    if (rank != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text('#$rank',
                              style: AppText.caption
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(category.name,
                  style: AppText.caption.copyWith(
                      color: category.color, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                blog.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyStrong.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 6),
              _MetaRow(blog: blog),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card with a resume progress bar for the "Continue reading" rail.
class ContinueReadingCard extends StatelessWidget {
  final Blog blog;
  final BlogCategory category;
  final double progress;
  final VoidCallback onTap;

  const ContinueReadingCard({
    super.key,
    required this.blog,
    required this.category,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 260,
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                  width: 64,
                  height: 64,
                  child: BlogCover(blog: blog, category: category)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor:
                                  AppColors.alpha(category.color, 0.15),
                              valueColor:
                                  AlwaysStoppedAnimation(category.color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${(progress * 100).round()}%',
                            style: AppText.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Tag(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: AppText.caption
              .copyWith(color: textColor, fontWeight: FontWeight.w700)),
    );
  }
}

/// Date formatter shared by detail/headers.
String formatBlogDate(DateTime d) => DateFormat.MMMd().format(d);
