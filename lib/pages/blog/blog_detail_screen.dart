import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/components/blog/article_cards.dart';
import 'package:pp_tracker/components/blog/blog_category_style.dart';
import 'package:pp_tracker/components/blog/blog_cover.dart';
import 'package:pp_tracker/components/blog/comment_section.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/state/blog_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class BlogDetailScreen extends StatefulWidget {
  final Blog blog;
  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final _scroll = ScrollController();
  late Blog _blog;
  late BlogController _controller;
  double _progress = 0;
  double _lastSaved = 0;

  @override
  void initState() {
    super.initState();
    _blog = widget.blog;
    _controller = context.read<BlogController>();
    _controller.recordView(_blog);
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients || _scroll.position.maxScrollExtent <= 0) return;
    final p = (_scroll.position.pixels / _scroll.position.maxScrollExtent)
        .clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.005) setState(() => _progress = p);
    // Persist progress in ~10% steps to avoid chatty writes.
    if (p - _lastSaved > 0.1 || p >= 0.99) {
      _lastSaved = p;
      _controller.saveProgress(_blog, p);
    }
  }

  @override
  void dispose() {
    _controller.saveProgress(_blog, _progress);
    _scroll.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    _controller.toggleBookmark(_blog);
    setState(() => _blog = _blog.copyWith(isBookmarked: !_blog.isBookmarked));
  }

  void _toggleLike() {
    _controller.toggleLike(_blog);
    final liked = !_blog.isLikedByMe;
    setState(() => _blog = _blog.copyWith(
          isLikedByMe: liked,
          likeCount: (_blog.likeCount + (liked ? 1 : -1)).clamp(0, 1 << 31),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final category = _controller.categoryById(_blog.categoryId);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 260,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                leading: _glassButton(
                    Icons.arrow_back_rounded, () => Navigator.pop(context)),
                actions: [
                  _glassButton(Icons.ios_share_rounded, () {}),
                  const SizedBox(width: AppSpacing.xs),
                  _glassButton(
                    _blog.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    _toggleBookmark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      BlogCover(blog: _blog, category: category, radius: 0),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(category.color),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryPill(label: category.name, color: category.color),
                      const SizedBox(height: AppSpacing.sm),
                      Text(_blog.title, style: AppText.display.copyWith(fontSize: 28)),
                      if (_blog.subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(_blog.subtitle, style: AppText.body.copyWith(fontSize: 16)),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _authorRow(),
                      const Divider(height: AppSpacing.xl, color: AppColors.divider),
                      _ArticleBody(content: _blog.content),
                      const SizedBox(height: AppSpacing.lg),
                      _tags(),
                      const SizedBox(height: AppSpacing.lg),
                      _relatedSection(category),
                      const Divider(height: AppSpacing.xxl, color: AppColors.divider),
                      CommentSection(blog: _blog, controller: _controller),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating like/comment action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _actionBar(),
          ),
        ],
      ),
    );
  }

  Widget _authorRow() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.alpha(AppColors.primary, 0.14),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _blog.authorName.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(),
            style: AppText.label.copyWith(color: AppColors.primaryDeep),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: Text(_blog.authorName, style: AppText.bodyStrong)),
                  if (_blog.authorIsExpert) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        size: 15, color: AppColors.primary),
                  ],
                ],
              ),
              Text(
                '${DateFormat.MMMMd().format(_blog.publishedAt)} · ${_blog.readingTimeMinutes} min read',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tags() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _blog.tags
          .map((t) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('#$t', style: AppText.caption),
              ))
          .toList(),
    );
  }

  Widget _relatedSection(category) {
    return FutureBuilder<List<Blog>>(
      future: _controller.repository.fetchRelated(_blog, limit: 3),
      builder: (context, snap) {
        final related = snap.data ?? [];
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Related reads', style: AppText.h2),
            const SizedBox(height: AppSpacing.sm),
            ...related.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ArticleListCard(
                    blog: b,
                    category: _controller.categoryById(b.categoryId),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BlogDetailScreen(blog: b))),
                    onBookmark: () => _controller.toggleBookmark(b),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _actionBar() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.lifted,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                Icon(
                  _blog.isLikedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: AppColors.menstrual,
                ),
                const SizedBox(width: 6),
                Text('${_blog.likeCount}', style: AppText.bodyStrong),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Icon(Icons.mode_comment_outlined,
              color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 6),
          Text('${_blog.commentCount}', style: AppText.bodyStrong),
          const Spacer(),
          GestureDetector(
            onTap: _toggleBookmark,
            child: Row(
              children: [
                Icon(
                  _blog.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(_blog.isBookmarked ? 'Saved' : 'Save',
                    style: AppText.label.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
          style: AppText.caption
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

/// Lightweight renderer for the article's markdown-ish body (## headings,
/// "- " bullets and paragraphs). Avoids a markdown dependency for this scope.
class _ArticleBody extends StatelessWidget {
  final String content;
  const _ArticleBody({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 4),
          child: Text(line.substring(3), style: AppText.h2),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 9, right: 10),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(line.substring(2),
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary, fontSize: 16, height: 1.6)),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Text(
          line,
          style: AppText.body
              .copyWith(color: AppColors.textPrimary, fontSize: 16, height: 1.7),
        ));
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
