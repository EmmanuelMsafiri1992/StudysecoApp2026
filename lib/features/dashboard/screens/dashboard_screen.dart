import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:shimmer/shimmer.dart';

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(apiServiceProvider).getDashboardStats();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_greeting()}, 👋',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.name.split(' ').first ?? 'Student',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _StreakBadge(streak: user?.streak ?? 0),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => context.push(AppRoutes.profile),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      (user?.name.isNotEmpty == true)
                                          ? user!.name[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (user?.hasActiveSubscription == false)
                          _PaymentBanner(context: context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: Image.asset('assets/images/icon.png', height: 36, fit: BoxFit.contain),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded,
                    color: AppColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () => _LoadingSkeleton(),
              error: (_, __) => _OfflineView(onRetry: () => ref.refresh(dashboardStatsProvider)),
              data: (stats) => _DashboardContent(stats: stats),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _PaymentBanner extends StatelessWidget {
  final BuildContext context;
  const _PaymentBanner({required this.context});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.payment),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: Row(
          children: const [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.accent, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Activate subscription to access all content',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.accent, size: 12),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final Map<String, dynamic> stats;
  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Subjects',
                  value: '${stats['subjects_count'] ?? 0}',
                  icon: Icons.book_rounded,
                  gradient: AppColors.primaryGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Quizzes Done',
                  value: '${stats['quizzes_done'] ?? 0}',
                  icon: Icons.quiz_rounded,
                  gradient: AppColors.secondaryGradient,
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Avg. Score',
                  value: '${stats['avg_score'] ?? 0}%',
                  icon: Icons.bar_chart_rounded,
                  gradient: AppColors.accentGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Points',
                  value: '${stats['total_points'] ?? 0}',
                  icon: Icons.star_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          const Text(
            'Quick Access',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _QuickAction(
                icon: Icons.book_rounded,
                label: 'Subjects',
                color: AppColors.primary,
                onTap: () => context.go(AppRoutes.subjects),
              ),
              _QuickAction(
                icon: Icons.quiz_rounded,
                label: 'Quizzes',
                color: AppColors.secondary,
                onTap: () => context.go(AppRoutes.quizzes),
              ),
              _QuickAction(
                icon: Icons.credit_card_rounded,
                label: 'Payment',
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.payment),
              ),
              _QuickAction(
                icon: Icons.school_rounded,
                label: 'Enroll',
                color: const Color(0xFFEC4899),
                onTap: () => context.push(AppRoutes.enrollment),
              ),
              _QuickAction(
                icon: Icons.emoji_events_rounded,
                label: 'Achievements',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push(AppRoutes.achievements),
              ),
              _QuickAction(
                icon: Icons.forum_rounded,
                label: 'Community',
                color: const Color(0xFF06B6D4),
                onTap: () => context.go(AppRoutes.community),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          if ((stats['enrolled_subjects'] as List?)?.isNotEmpty == true) ...[
            const Text(
              'Continue Learning',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 12),
            ...(stats['enrolled_subjects'] as List).take(3).map(
              (subject) => _ContinueLearningCard(subject: subject),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final dynamic subject;

  const _ContinueLearningCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final progress = (subject['progress_percent'] ?? 0.0) / 100.0;
    return GestureDetector(
      onTap: () =>
          context.push('/subjects/${subject['slug'] ?? ''}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.book_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  LinearPercentIndicator(
                    lineHeight: 4,
                    percent: progress.clamp(0.0, 1.0),
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.surfaceVariant,
                    linearGradient: AppColors.primaryGradient,
                    barRadius: const Radius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toInt()}% complete',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('Failed to load dashboard',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
