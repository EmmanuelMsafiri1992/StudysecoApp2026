import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../widgets/moderation_menu.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityProvider.notifier).loadPosts(refresh: true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(communityProvider.notifier).loadPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppRoutes.createPost),
          ),
        ],
      ),
      body: state.isLoading && state.posts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null && state.posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(state.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref
                            .read(communityProvider.notifier)
                            .loadPosts(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(communityProvider.notifier)
                      .loadPosts(refresh: true),
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.posts.length +
                        (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        );
                      }
                      return PostCard(post: state.posts[index])
                          .animate()
                          .fadeIn(delay: (index * 30).ms);
                    },
                  ),
                ),
    );
  }
}

class PostCard extends ConsumerWidget {
  final CommunityPostModel post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/community/${post.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    post.userName.isNotEmpty ? post.userName[0] : 'U',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(
                        _formatDate(post.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (post.tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.tag!,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ModerationMenu(
                  authorId: post.userId,
                  authorName: post.userName,
                  onReport: (reason, details) => ref
                      .read(apiServiceProvider)
                      .reportPost(post.id, reason, details: details),
                  onReported: () =>
                      ref.read(communityProvider.notifier).removePost(post.id),
                  onBlocked: () => ref
                      .read(communityProvider.notifier)
                      .removePostsBy(post.userId),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (post.isPinned)
              Row(
                children: const [
                  Icon(Icons.push_pin_rounded,
                      size: 13, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text('Pinned',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.accent)),
                  SizedBox(height: 6),
                ],
              ),
            Text(
              post.title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5),
            ),
            if (post.subjectName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.book_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(post.subjectName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => ref
                      .read(communityProvider.notifier)
                      .toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: post.isLiked
                            ? AppColors.error
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likesCount}',
                          style: TextStyle(
                              fontSize: 12,
                              color: post.isLiked
                                  ? AppColors.error
                                  : AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.comment_rounded,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${post.commentsCount}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}
