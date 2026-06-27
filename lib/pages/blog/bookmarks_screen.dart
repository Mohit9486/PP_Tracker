import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/components/blog/article_cards.dart';
import 'package:pp_tracker/pages/blog/blog_detail_screen.dart';
import 'package:pp_tracker/state/blog_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// Saved articles. Reads the current user's bookmarks from the controller.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<BlogController>().loadBookmarks().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Saved articles', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<BlogController>(
        builder: (context, c, _) {
          if (_loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (c.bookmarks.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔖', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: AppSpacing.md),
                  Text('No saved articles yet', style: AppText.h3),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap the bookmark icon on any article to keep it here for later.',
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: c.bookmarks.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final blog = c.bookmarks[i];
              return ArticleListCard(
                blog: blog,
                category: c.categoryById(blog.categoryId),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BlogDetailScreen(blog: blog))),
                onBookmark: () => c.toggleBookmark(blog),
              );
            },
          );
        },
      ),
    );
  }
}
