import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../widgets/moderation_menu.dart';

final postDetailProvider = FutureProvider.family<CommunityPostModel, int>(
  (ref, postId) => ref.read(apiServiceProvider).getCommunityPost(postId),
);

class PostDetailScreen extends ConsumerStatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _isSending = false;
  final List<CommentModel> _localComments = [];
  // Comments the user reported, and people they blocked, hidden right away.
  final Set<int> _hiddenCommentIds = {};
  final Set<int> _hiddenUserIds = {};

  bool _isVisible(CommentModel comment) =>
      !_hiddenCommentIds.contains(comment.id) &&
      !_hiddenUserIds.contains(comment.userId);

  /// After reporting the post or blocking its author, leave the screen and
  /// take the post out of the list too.
  void _leavePost(CommunityPostModel post, {bool blocked = false}) {
    final notifier = ref.read(communityProvider.notifier);
    blocked ? notifier.removePostsBy(post.userId) : notifier.removePost(post.id);
    if (mounted) context.pop();
  }

  Widget _comment(CommentModel comment) {
    return _CommentTile(
      comment: comment,
      menu: ModerationMenu(
        authorId: comment.userId,
        authorName: comment.userName,
        contentLabel: 'comment',
        iconSize: 18,
        onReport: (reason, details) => ref
            .read(apiServiceProvider)
            .reportComment(comment.id, reason, details: details),
        onReported: () => setState(() => _hiddenCommentIds.add(comment.id)),
        onBlocked: () {
          setState(() => _hiddenUserIds.add(comment.userId));
          ref.read(communityProvider.notifier).removePostsBy(comment.userId);
        },
      ),
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      final comment = await ref
          .read(apiServiceProvider)
          .addComment(widget.postId, _commentCtrl.text.trim());
      _commentCtrl.clear();
      setState(() {
        _localComments.add(comment);
        _isSending = false;
      });
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ApiService.errorMessage(e, 'Could not post your comment.')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));

    return postAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Discussion'),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, __) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(ApiService.errorMessage(error, 'Failed to load post'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        )),
      ),
      data: (post) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Discussion'),
          actions: [
            IconButton(
              icon: Icon(
                post.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: post.isLiked ? AppColors.error : AppColors.textSecondary,
              ),
              onPressed: () =>
                  ref.read(communityProvider.notifier).toggleLike(post.id),
            ),
            ModerationMenu(
              authorId: post.userId,
              authorName: post.userName,
              iconSize: 22,
              onReport: (reason, details) => ref
                  .read(apiServiceProvider)
                  .reportPost(post.id, reason, details: details),
              onReported: () => _leavePost(post),
              onBlocked: () => _leavePost(post, blocked: true),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PostHeader(post: post),
                  const SizedBox(height: 16),
                  Text(
                    post.content,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Comments (${post.comments.where(_isVisible).length + _localComments.length})',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...post.comments.where(_isVisible).map(_comment),
                  ..._localComments.map(_comment),
                  if (!post.comments.any(_isVisible) && _localComments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('Be the first to comment!',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            _CommentInput(
              controller: _commentCtrl,
              isLoading: _isSending,
              onSend: _sendComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  final CommunityPostModel post;
  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              child: Text(
                post.userName.isNotEmpty ? post.userName[0] : 'U',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(
                  DateFormat('MMM d, y • h:mm a').format(post.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          post.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final Widget menu;
  const _CommentTile({required this.comment, required this.menu});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.5),
                child: Text(
                  comment.userName.isNotEmpty ? comment.userName[0] : 'U',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(comment.userName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Text(
                _timeAgo(comment.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
              SizedBox(width: 28, height: 24, child: menu),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _CommentInput({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                  ),
          ),
        ],
      ),
    );
  }
}
