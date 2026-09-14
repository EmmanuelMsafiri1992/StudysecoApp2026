import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/quiz_provider.dart';
import '../../../shared/widgets/app_button.dart';

class QuizResultScreen extends ConsumerWidget {
  final int quizId;
  const QuizResultScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeQuizProvider);
    final result = state.result;

    if (result == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No result found',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => context.go(AppRoutes.quizzes),
                  child: const Text('Back to Quizzes')),
            ],
          ),
        ),
      );
    }

    final percentage = result.score;
    final isPassed = result.score >= (state.quiz?.passScore ?? 50);
    final mins = result.durationSeconds ~/ 60;
    final secs = result.durationSeconds % 60;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  isPassed ? '🎉 Congratulations!' : '💪 Keep Trying!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 8),
                Text(
                  isPassed
                      ? 'You passed this quiz!'
                      : 'You need more practice.',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 40),
                CircularPercentIndicator(
                  radius: 80,
                  lineWidth: 10,
                  percent: (percentage / 100).clamp(0.0, 1.0),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isPassed ? 'Passed' : 'Failed',
                        style: TextStyle(
                          fontSize: 14,
                          color: isPassed
                              ? AppColors.secondary
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  progressColor:
                      isPassed ? AppColors.secondary : AppColors.error,
                  backgroundColor: AppColors.surfaceVariant,
                  animation: true,
                  animationDuration: 1200,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: _ResultCard(
                        icon: Icons.check_circle_rounded,
                        label: 'Correct',
                        value: '${result.correctAnswers}',
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultCard(
                        icon: Icons.cancel_rounded,
                        label: 'Wrong',
                        value:
                            '${result.totalQuestions - result.correctAnswers}',
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultCard(
                        icon: Icons.timer_rounded,
                        label: 'Time',
                        value:
                            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 32),
                Text(
                  'Review Answers',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 12),
                ...state.questions.asMap().entries.map(
                  (entry) => _ReviewItem(
                    index: entry.key,
                    question: entry.value,
                  ).animate().fadeIn(delay: ((entry.key * 50) + 800).ms),
                ),
                const SizedBox(height: 32),
                GradientButton(
                  label: 'Try Again',
                  onTap: () {
                    ref.read(activeQuizProvider.notifier).reset();
                    context.pop();
                  },
                ).animate().fadeIn(delay: 900.ms),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Back to Quizzes',
                  isOutlined: true,
                  onTap: () {
                    ref.read(activeQuizProvider.notifier).reset();
                    context.go(AppRoutes.quizzes);
                  },
                ).animate().fadeIn(delay: 1000.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ReviewItem extends ConsumerWidget {
  final int index;
  final dynamic question;

  const _ReviewItem({required this.index, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCorrect = question.isCorrect;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.secondary.withOpacity(0.05)
            : AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? AppColors.secondary.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: isCorrect ? AppColors.secondary : AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Q${index + 1}: ${question.question}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (question.selectedOption != null) ...[
            const SizedBox(height: 6),
            Text(
              'Your answer: ${question.options[question.selectedOption]}',
              style: TextStyle(
                  fontSize: 12,
                  color: isCorrect
                      ? AppColors.secondary
                      : AppColors.error),
            ),
          ],
          if (!isCorrect) ...[
            Text(
              'Correct: ${question.options[question.correctOption]}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.secondary),
            ),
          ],
          if (question.explanation != null) ...[
            const SizedBox(height: 4),
            Text(
              question.explanation!,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
