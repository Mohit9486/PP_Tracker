import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pp_tracker/components/app_card.dart';
import 'package:pp_tracker/models/blog/blog.dart';
import 'package:pp_tracker/models/blog/comment.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';
import 'package:pp_tracker/state/blog_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// Threaded comment list + composer for the article reader.
///
/// Drives off [BlogController.repository] so it works against the mock today
/// and Firestore later. Built for nested replies, likes, deletion and
/// pagination; moderation/edit hooks live on the model and repository already.
class CommentSection extends StatefulWidget {
  final Blog blog;
  final BlogController controller;
  const CommentSection({super.key, required this.blog, required this.controller});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  BlogRepository get _repo => widget.controller.repository;

  final _composer = TextEditingController();
  final List<Comment> _comments = [];
  bool _loading = true;
  bool _posting = false;
  String? _cursor;
  bool _hasMore = false;
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final page = await _repo.fetchComments(widget.blog.id, limit: 10);
    if (!mounted) return;
    setState(() {
      _comments
        ..clear()
        ..addAll(page.items);
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    final page =
        await _repo.fetchComments(widget.blog.id, cursor: _cursor, limit: 10);
    if (!mounted) return;
    setState(() {
      _comments.addAll(page.items);
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
    });
  }

  Future<void> _post() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    final created = await _repo.addComment(
      blogId: widget.blog.id,
      author: widget.controller.currentUser,
      content: text,
      parentCommentId: _replyingTo?.id,
    );
    if (!mounted) return;
    _composer.clear();
    FocusScope.of(context).unfocus();
    final replyingToId = _replyingTo?.id;
    setState(() {
      _posting = false;
      _replyingTo = null;
      if (replyingToId == null) {
        _comments.insert(0, created);
      } else {
        // Bump the parent's reply count; thread expands on demand.
        final i = _comments.indexWhere((c) => c.id == replyingToId);
        if (i != -1) {
          _comments[i] =
              _comments[i].copyWith(replyCount: _comments[i].replyCount + 1);
        }
      }
    });
  }

  Future<void> _toggleLike(Comment c) async {
    final liked = !c.isLikedByMe;
    setState(() {
      final i = _comments.indexWhere((x) => x.id == c.id);
      if (i != -1) {
        _comments[i] = _comments[i].copyWith(
          isLikedByMe: liked,
          likeCount: (c.likeCount + (liked ? 1 : -1)).clamp(0, 1 << 31),
        );
      }
    });
    await _repo.toggleCommentLike(c.id, widget.controller.currentUser.id);
  }

  Future<void> _delete(Comment c) async {
    setState(() {
      final i = _comments.indexWhere((x) => x.id == c.id);
      if (i != -1) {
        _comments[i] =
            _comments[i].copyWith(status: CommentStatus.deleted, content: '');
      }
    });
    await _repo.deleteComment(c.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Comments', style: AppText.h2),
            const SizedBox(width: AppSpacing.xs),
            if (!_loading)
              Text('${_comments.length}',
                  style: AppText.label.copyWith(color: AppColors.textTertiary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (_comments.isEmpty)
          _EmptyComments()
        else ...[
          ..._comments.map((c) => _CommentTile(
                comment: c,
                isMine: c.userId == widget.controller.currentUser.id,
                onLike: () => _toggleLike(c),
                onReply: () => setState(() => _replyingTo = c),
                onDelete: () => _delete(c),
                repo: _repo,
                currentUserId: widget.controller.currentUser.id,
              )),
          if (_hasMore)
            Center(
              child: TextButton(
                onPressed: _loadMore,
                child: Text('Load more comments',
                    style: AppText.label.copyWith(color: AppColors.primary)),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        _Composer(
          controller: _composer,
          posting: _posting,
          replyingTo: _replyingTo,
          onCancelReply: () => setState(() => _replyingTo = null),
          onSend: _post,
        ),
      ],
    );
  }
}

class _CommentTile extends StatefulWidget {
  final Comment comment;
  final bool isMine;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final BlogRepository repo;
  final String currentUserId;

  const _CommentTile({
    required this.comment,
    required this.isMine,
    required this.onLike,
    required this.onReply,
    required this.onDelete,
    required this.repo,
    required this.currentUserId,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = false;
  List<Comment> _replies = [];
  bool _loadingReplies = false;

  Future<void> _toggleReplies() async {
    if (_showReplies) {
      setState(() => _showReplies = false);
      return;
    }
    setState(() {
      _showReplies = true;
      _loadingReplies = true;
    });
    final page = await widget.repo.fetchComments(
      widget.comment.blogId,
      parentCommentId: widget.comment.id,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _replies = page.items;
      _loadingReplies = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(c, mine: widget.isMine),
          if (c.replyCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: GestureDetector(
                onTap: _toggleReplies,
                child: Text(
                  _showReplies
                      ? 'Hide replies'
                      : 'View ${c.replyCount} ${c.replyCount == 1 ? "reply" : "replies"}',
                  style: AppText.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          if (_showReplies)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: AppSpacing.xs),
              child: _loadingReplies
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary)),
                    )
                  : Column(
                      children: _replies
                          .map((r) => _row(r, mine: r.userId == widget.currentUserId, isReply: true))
                          .toList(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _row(Comment c, {required bool mine, bool isReply = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isReply ? AppSpacing.xs : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(name: c.authorName, size: isReply ? 28 : 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(c.authorName,
                                style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ),
                          const SizedBox(width: 6),
                          Text(_timeAgo(c.createdAt),
                              style: AppText.caption
                                  .copyWith(color: AppColors.textTertiary)),
                          if (c.isEdited)
                            Text(' · edited',
                                style: AppText.caption
                                    .copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c.isDeleted ? 'This comment was removed.' : c.content,
                        style: AppText.body.copyWith(
                          color: c.isDeleted
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          fontStyle:
                              c.isDeleted ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!c.isDeleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onLike,
                          child: Row(
                            children: [
                              Icon(
                                c.isLikedByMe
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 15,
                                color: c.isLikedByMe
                                    ? AppColors.menstrual
                                    : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text('${c.likeCount}', style: AppText.caption),
                            ],
                          ),
                        ),
                        if (!isReply) ...[
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: widget.onReply,
                            child: Text('Reply',
                                style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                        if (mine) ...[
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: widget.onDelete,
                            child: Text('Delete',
                                style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.menstrual)),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool posting;
  final Comment? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.posting,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (replyingTo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.reply_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Replying to ${replyingTo!.authorName}',
                    style: AppText.caption.copyWith(color: AppColors.primary)),
                const Spacer(),
                GestureDetector(
                  onTap: onCancelReply,
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                style: AppText.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Share a supportive thought…',
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: posting ? null : onSend,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: posting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((p) => p[0]).take(2).join().toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.alpha(AppColors.primary, 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: AppText.caption.copyWith(
              color: AppColors.primaryDeep, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceAlt,
      shadows: const [],
      child: Row(
        children: [
          const Text('💬', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('No comments yet — be the first to share a kind word.',
                style: AppText.body),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat.MMMd().format(d);
}
