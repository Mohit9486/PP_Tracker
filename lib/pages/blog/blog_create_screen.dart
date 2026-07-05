import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/blog_models.dart';
import 'package:pp_tracker/components/blog/blog_category_style.dart';
import 'package:pp_tracker/state/blog_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class BlogCreateScreen extends StatefulWidget {
  const BlogCreateScreen({super.key});

  @override
  State<BlogCreateScreen> createState() => _BlogCreateScreenState();
}

class _BlogCreateScreenState extends State<BlogCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategoryId = 'cycle';

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<BlogController>();
    final now = DateTime.now();
    
    // In a real app, this would use the signed-in user's data
    final newBlog = Blog(
      id: 'b_local_${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      summary: _summaryController.text.trim(),
      sections: [
        BlogSection(body: _contentController.text.trim()),
      ],
      authorId: 'me',
      authorName: 'You',
      categoryId: _selectedCategoryId,
      publishedAt: now,
      updatedAt: now,
      visibility: BlogVisibility.public,
    );

    await controller.repository.upsertBlog(newBlog);
    controller.refresh();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article published locally!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.read<BlogController>().categories.where((c) => !c.isAll).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Article'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text('Publish', style: AppText.bodyStrong.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Topic Category', style: AppText.label),
              const SizedBox(height: 8),
              SizedBox(
                height: 45,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final selected = _selectedCategoryId == cat.id;
                    return ChoiceChip(
                      label: Text(cat.name),
                      selected: selected,
                      onSelected: (val) => setState(() => _selectedCategoryId = cat.id),
                      selectedColor: AppColors.alpha(cat.color, 0.2),
                      labelStyle: AppText.caption.copyWith(
                        color: selected ? cat.color : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _textField(_titleController, 'Title', 'e.g. My Wellness Journey', true),
              _textField(_subtitleController, 'Subtitle', 'A brief hook for the reader', false),
              _textField(_summaryController, 'Summary', 'Appears in the feed cards', true, maxLines: 2),
              _textField(_contentController, 'Content', 'Write your article here... (Markdown supported)', true, maxLines: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label, String hint, bool required, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
            validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
          ),
        ],
      ),
    );
  }
}
