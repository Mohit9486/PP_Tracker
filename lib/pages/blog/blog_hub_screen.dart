import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/components/app_card.dart';
import 'package:pp_tracker/components/blog/article_cards.dart';
import 'package:pp_tracker/components/blog/blog_category_style.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/pages/blog/blog_create_screen.dart';
import 'package:pp_tracker/pages/blog/blog_detail_screen.dart';
import 'package:pp_tracker/pages/blog/bookmarks_screen.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';
import 'package:pp_tracker/state/blog_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class BlogHubScreen extends StatefulWidget {
  const BlogHubScreen({super.key});

  @override
  State<BlogHubScreen> createState() => _BlogHubScreenState();
}

class _BlogHubScreenState extends State<BlogHubScreen> {
  final _scroll = ScrollController();
  final _searchField = TextEditingController();
  final _featuredPage = PageController(viewportFraction: 0.9);

  @override
  void initState() {
    super.initState();
    final controller = context.read<BlogController>();
    if (controller.status == LoadStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.load();
      });
    }
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 400) {
        controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchField.dispose();
    _featuredPage.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, Blog blog) {
    final controller = context.read<BlogController>();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: blog)))
        .then((_) => controller.refreshContinueReading());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BlogController>(
      builder: (context, c, _) {
        final showRails = !c.isSearching && c.selectedCategory.isAll;
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: c.refresh,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: _header(context, c)),
              SliverToBoxAdapter(child: _searchBar(c)),
              if (showRails && c.featured.isNotEmpty)
                SliverToBoxAdapter(child: _featured(context, c)),
              SliverToBoxAdapter(child: _categories(c)),
              if (showRails && c.continueReading.isNotEmpty)
                SliverToBoxAdapter(
                    child: _rail(context, c, 'Continue reading',
                        c.continueReading, continueReading: true)),
              if (showRails && c.trending.isNotEmpty)
                SliverToBoxAdapter(
                    child: _rail(context, c, 'Trending now', c.trending,
                        ranked: true)),
              if (showRails && c.recommended.isNotEmpty)
                SliverToBoxAdapter(
                    child: _rail(context, c, 'Recommended for you',
                        c.recommended)),
              SliverToBoxAdapter(child: _feedHeader(c)),
              ..._feedSlivers(context, c),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  // ---- Header & search ----

  Widget _header(BuildContext context, BlogController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wellness library', style: AppText.label),
                  const SizedBox(height: 2),
                  Text('Health Hub', style: AppText.h1),
                ],
              ),
            ),
            _circleButton(
              icon: Icons.add_rounded,
              onTap: () {
                // Future: Check auth and roles here
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BlogCreateScreen()));
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _circleButton(
              icon: Icons.bookmark_border_rounded,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BookmarksScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BlogController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.soft,
        ),
        child: TextField(
          controller: _searchField,
          textInputAction: TextInputAction.search,
          onChanged: (v) => c.search(v),
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search articles, topics, tags…',
            hintStyle: AppText.body,
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.textTertiary),
            suffixIcon: c.isSearching
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textTertiary),
                    onPressed: () {
                      _searchField.clear();
                      c.clearSearch();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ---- Featured ----

  Widget _featured(BuildContext context, BlogController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        height: 230,
        child: PageView.builder(
          controller: _featuredPage,
          itemCount: c.featured.length,
          padEnds: false,
          itemBuilder: (context, i) {
            final blog = c.featured[i];
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: i == c.featured.length - 1 ? AppSpacing.md : 0,
              ),
              child: FeaturedArticleCard(
                blog: blog,
                category: c.categoryById(blog.categoryId),
                onTap: () => _openDetail(context, blog),
                onBookmark: () => c.toggleBookmark(blog),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---- Categories ----

  Widget _categories(BlogController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: c.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (context, i) {
            final cat = c.categories[i];
            final selected = cat == c.selectedCategory;
            final accent = cat.isAll ? AppColors.primary : cat.color;
            return GestureDetector(
              onTap: () => c.selectCategory(cat),
              child: AnimatedContainer(
                duration: AppDuration.fast,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: selected ? accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    Icon(cat.icon,
                        size: 16,
                        color: selected ? Colors.white : accent),
                    const SizedBox(width: 6),
                    Text(cat.name,
                        style: AppText.label.copyWith(
                            color: selected ? Colors.white : AppColors.textPrimary)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---- Horizontal rails ----

  Widget _rail(BuildContext context, BlogController c, String title,
      List<Blog> blogs,
      {bool ranked = false, bool continueReading = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Text(title, style: AppText.h2),
          ),
          SizedBox(
            height: continueReading ? 96 : 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: blogs.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final blog = blogs[i];
                final cat = c.categoryById(blog.categoryId);
                if (continueReading) {
                  return ContinueReadingCard(
                    blog: blog,
                    category: cat,
                    progress: (blog.metadata['progress'] as double?) ?? 0.4,
                    onTap: () => _openDetail(context, blog),
                  );
                }
                return TrendingCard(
                  blog: blog,
                  category: cat,
                  rank: ranked ? i + 1 : null,
                  onTap: () => _openDetail(context, blog),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- Feed ----

  Widget _feedHeader(BlogController c) {
    final title = c.isSearching
        ? 'Results'
        : c.selectedCategory.isAll
            ? 'Latest articles'
            : c.selectedCategory.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.h2),
          if (!c.isSearching)
            _SortMenu(current: c.sort, onSelect: c.setSort),
        ],
      ),
    );
  }

  List<Widget> _feedSlivers(BuildContext context, BlogController c) {
    if (c.status == LoadStatus.loading && c.feed.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SkeletonCard(),
              ),
              childCount: 5,
            ),
          ),
        ),
      ];
    }
    if (c.status == LoadStatus.error) {
      return [SliverToBoxAdapter(child: _ErrorState(onRetry: c.refresh))];
    }
    if (c.status == LoadStatus.empty || c.feed.isEmpty) {
      return [SliverToBoxAdapter(child: _EmptyState(searching: c.isSearching))];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final blog = c.feed[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ArticleListCard(
                  blog: blog,
                  category: c.categoryById(blog.categoryId),
                  onTap: () => _openDetail(context, blog),
                  onBookmark: () => c.toggleBookmark(blog),
                ),
              );
            },
            childCount: c.feed.length,
          ),
        ),
      ),
      if (c.loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
        ),
    ];
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle, boxShadow: AppShadows.soft),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final BlogSort current;
  final ValueChanged<BlogSort> onSelect;
  const _SortMenu({required this.current, required this.onSelect});

  String _label(BlogSort s) => switch (s) {
        BlogSort.latest => 'Latest',
        BlogSort.trending => 'Trending',
        BlogSort.mostViewed => 'Most viewed',
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<BlogSort>(
      initialValue: current,
      onSelected: onSelect,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      itemBuilder: (_) => BlogSort.values
          .map((s) => PopupMenuItem(value: s, child: Text(_label(s), style: AppText.body.copyWith(color: AppColors.textPrimary))))
          .toList(),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(_label(current),
              style: AppText.label.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ---- States ----

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 0.9).animate(_ac),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        shadows: const [],
        color: AppColors.surfaceAlt,
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(70),
                  const SizedBox(height: 8),
                  _bar(double.infinity),
                  const SizedBox(height: 6),
                  _bar(140),
                  const SizedBox(height: 14),
                  _bar(90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double width) => Container(
        width: width,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  const _EmptyState({required this.searching});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Text(searching ? '🔍' : '🌸', style: const TextStyle(fontSize: 44)),
          const SizedBox(height: AppSpacing.md),
          Text(searching ? 'No matches found' : 'Nothing here yet',
              style: AppText.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            searching
                ? 'Try a different word or browse by category.'
                : 'New articles will appear here soon.',
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const Text('😔', style: TextStyle(fontSize: 44)),
          const SizedBox(height: AppSpacing.md),
          Text('Couldn\'t load articles', style: AppText.h3),
          const SizedBox(height: AppSpacing.xs),
          Text('Please check your connection and try again.',
              style: AppText.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
