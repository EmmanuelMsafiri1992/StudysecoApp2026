import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';

final blockedUsersProvider = FutureProvider.autoDispose<List<BlockedUserModel>>(
  (ref) => ref.read(apiServiceProvider).getBlockedUsers(),
);

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(BuildContext context, WidgetRef ref, BlockedUserModel user) async {
    try {
      await ref.read(apiServiceProvider).unblockUser(user.id);
      ref.invalidate(blockedUsersProvider);
      // Their posts can show again.
      ref.read(communityProvider.notifier).loadPosts(refresh: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name} unblocked.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ApiService.errorMessage(e, 'Could not unblock. Please try again.')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Blocked users'),
      ),
      body: blocked.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(ApiService.errorMessage(error, 'Could not load blocked users'),
                  style: const TextStyle(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.invalidate(blockedUsersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (users) => users.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    "You haven't blocked anyone. To block someone, tap ⋮ on their post or comment in Community.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surfaceVariant,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0] : 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(user.name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () => _unblock(context, ref, user),
                          child: const Text('Unblock'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
