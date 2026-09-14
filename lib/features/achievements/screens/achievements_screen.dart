import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/achievement_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) {
  return ref.read(apiServiceProvider).getAchievements();
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Points',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Text(
                        '${user?.totalPoints ?? 0}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          const Text('🔥 ',
                              style: TextStyle(fontSize: 16)),
                          Text(
                            '${user?.streak ?? 0} day streak',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ),
          SliverToBoxAdapter(
            child: achievementsAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              )),
              error: (_, __) => const Center(
                  child: Text('Failed to load achievements',
                      style: TextStyle(color: AppColors.textSecondary))),
              data: (achievements) {
                final earned = achievements.where((a) => a.isEarned).toList();
                final locked =
                    achievements.where((a) => !a.isEarned).toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (earned.isNotEmpty) ...[
                        Text(
                          'Earned (${earned.length})',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: earned.length,
                          itemBuilder: (context, index) {
                            return _AchievementBadge(
                              achievement: earned[index],
                            ).animate().fadeIn(delay: (index * 50).ms);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (locked.isNotEmpty) ...[
                        Text(
                          'Locked (${locked.length})',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: locked.length,
                          itemBuilder: (context, index) {
                            return _AchievementBadge(
                              achievement: locked[index],
                            ).animate().fadeIn(
                                delay: ((earned.length + index) * 50).ms);
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;
  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => _AchievementDialog(achievement: achievement),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: achievement.isEarned
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achievement.isEarned
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: achievement.isEarned
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.5, 0,
                    ]),
              child: Text(
                _getEmoji(achievement.icon),
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: achievement.isEarned
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (achievement.pointsValue > 0) ...[
              const SizedBox(height: 2),
              Text(
                '+${achievement.pointsValue} pts',
                style: TextStyle(
                  fontSize: 10,
                  color: achievement.isEarned
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getEmoji(String icon) {
    switch (icon) {
      case 'star':
        return '⭐';
      case 'fire':
        return '🔥';
      case 'trophy':
        return '🏆';
      case 'medal':
        return '🥇';
      case 'book':
        return '📚';
      case 'brain':
        return '🧠';
      case 'target':
        return '🎯';
      case 'rocket':
        return '🚀';
      case 'crown':
        return '👑';
      case 'diamond':
        return '💎';
      default:
        return '🏅';
    }
  }
}

class _AchievementDialog extends StatelessWidget {
  final AchievementModel achievement;
  const _AchievementDialog({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            achievement.isEarned ? '⭐' : '🔒',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.description,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (achievement.isEarned && achievement.earnedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Earned on ${achievement.earnedAt!.day}/${achievement.earnedAt!.month}/${achievement.earnedAt!.year}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          if (!achievement.isEarned &&
              achievement.progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (achievement.progress! /
                        (achievement.progressMax ?? 100))
                    .clamp(0, 1),
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${achievement.progress!.toInt()} / ${achievement.progressMax ?? 100}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
