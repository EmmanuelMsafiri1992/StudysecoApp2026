import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import 'package:shimmer/shimmer.dart';

class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesListProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: quizzesAsync.when(
        loading: () => _LoadingList(),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('Failed to load quizzes',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => ref.refresh(quizzesListProvider(null)),
                  child: const Text('Retry')),
            ],
          ),
        ),
        data: (quizzes) => quizzes.isEmpty
            ? const Center(
                child: Text('No quizzes available',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  return QuizCard(quiz: quizzes[index])
                      .animate()
                      .fadeIn(delay: (index * 50).ms)
                      .slideX(begin: 0.1, end: 0);
                },
              ),
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  const QuizCard({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/quizzes/${quiz.id}'),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: quiz.isPassed
                    ? AppColors.secondaryGradient
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                quiz.isPassed
                    ? Icons.check_circle_rounded
                    : Icons.quiz_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Tag(
                          label: '${quiz.questionsCount} Qs',
                          icon: Icons.help_outline_rounded),
                      const SizedBox(width: 8),
                      _Tag(
                          label: '${quiz.durationMinutes} min',
                          icon: Icons.timer_rounded),
                      const SizedBox(width: 8),
                      _Tag(
                        label: quiz.difficulty,
                        icon: Icons.bar_chart_rounded,
                        color: _getDifficultyColor(quiz.difficulty),
                      ),
                    ],
                  ),
                  if (quiz.bestScore != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Best: ${quiz.bestScore}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: quiz.isPassed
                                ? AppColors.secondary
                                : AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${quiz.attemptsCount} attempt${quiz.attemptsCount != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.secondary;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Tag({
    required this.label,
    required this.icon,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
