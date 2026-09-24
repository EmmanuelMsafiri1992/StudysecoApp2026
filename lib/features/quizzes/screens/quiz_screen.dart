import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import '../../../shared/widgets/app_button.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final int quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  Timer? _timer;
  bool _quizStarted = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(activeQuizProvider.notifier).incrementTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeQuizProvider);

    ref.listen<String?>(activeQuizProvider.select((s) => s.error), (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error));
      }
    });

    if (state.isCompleted) {
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace('/quizzes/${widget.quizId}/result');
      });
    }

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (state.questions.isNotEmpty && !_quizStarted) {
      _quizStarted = true;
      _startTimer();
    }

    if (!_quizStarted || state.quiz == null) {
      return _QuizIntroScreen(quizId: widget.quizId);
    }

    return _QuizActiveScreen(
      state: state,
      onSubmit: () => ref.read(activeQuizProvider.notifier).submitQuiz(),
    );
  }
}

class _QuizIntroScreen extends ConsumerWidget {
  final int quizId;
  const _QuizIntroScreen({required this.quizId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesListProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: quizzesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) =>
            const Center(child: Text('Quiz not found')),
        data: (quizzes) {
          final quiz = quizzes.firstWhere(
            (q) => q.id == quizId,
            orElse: () => quizzes.first,
          );
          return _IntroContent(quiz: quiz);
        },
      ),
    );
  }
}

class _IntroContent extends ConsumerWidget {
  final QuizModel quiz;
  const _IntroContent({required this.quiz});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.quiz_rounded,
                    color: Colors.white, size: 36),
                const SizedBox(height: 12),
                Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (quiz.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    quiz.description!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _InfoCard(
                icon: Icons.help_rounded,
                label: 'Questions',
                value: '${quiz.questionsCount}',
                color: AppColors.primary,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _InfoCard(
                icon: Icons.timer_rounded,
                label: 'Duration',
                value: '${quiz.durationMinutes} min',
                color: AppColors.secondary,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _InfoCard(
                icon: Icons.grade_rounded,
                label: 'Pass Score',
                value: '${quiz.passScore}%',
                color: AppColors.accent,
              )),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Instructions',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _Instruction('Read each question carefully'),
                _Instruction('Select the best answer'),
                _Instruction('You can review before submitting'),
                _Instruction(
                    'Timer starts when you begin the quiz'),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const Spacer(),
          GradientButton(
            label: 'Start Quiz',
            onTap: () {
              ref.read(activeQuizProvider.notifier).startQuiz(quiz);
            },
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  final String text;
  const _Instruction(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _QuizActiveScreen extends StatelessWidget {
  final ActiveQuizState state;
  final VoidCallback onSubmit;

  const _QuizActiveScreen({required this.state, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox();

    final progress =
        (state.currentIndex + 1) / state.questions.length;
    final mins = state.elapsedSeconds ~/ 60;
    final secs = state.elapsedSeconds % 60;

    return Consumer(builder: (context, ref, _) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              'Question ${state.currentIndex + 1}/${state.questions.length}'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Quit Quiz?'),
                  content: const Text(
                      'Your progress will be lost.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        ref.read(activeQuizProvider.notifier).reset();
                        context.pop();
                        context.pop();
                      },
                      child: const Text('Quit',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            ClipRRect(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 4,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),
                    ...question.options.asMap().entries.map((entry) {
                      final optIndex = entry.key;
                      final option = entry.value;
                      final isSelected =
                          question.selectedOption == optIndex;
                      return _OptionTile(
                        option: option,
                        index: optIndex,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(activeQuizProvider.notifier)
                              .answerQuestion(
                                  state.currentIndex, optIndex);
                        },
                      ).animate().fadeIn(
                          delay: (optIndex * 80).ms);
                    }),
                    const SizedBox(height: 20),
                    _QuestionGrid(state: state),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (state.currentIndex > 0)
                    Expanded(
                      child: AppButton(
                        label: 'Previous',
                        isOutlined: true,
                        onTap: () => ref
                            .read(activeQuizProvider.notifier)
                            .previousQuestion(),
                      ),
                    ),
                  if (state.currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: state.isLastQuestion
                        ? GradientButton(
                            label: 'Submit Quiz',
                            onTap: onSubmit,
                            isLoading: state.isSubmitting,
                          )
                        : GradientButton(
                            label: 'Next',
                            onTap: () => ref
                                .read(activeQuizProvider.notifier)
                                .nextQuestion(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _OptionTile extends StatelessWidget {
  final String option;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letters = ['A', 'B', 'C', 'D'];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letters[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: isSelected
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionGrid extends StatelessWidget {
  final ActiveQuizState state;

  const _QuestionGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: state.questions.asMap().entries.map((entry) {
          final i = entry.key;
          final q = entry.value;
          final isCurrent = i == state.currentIndex;
          final isAnswered = q.isAnswered;

          return GestureDetector(
            onTap: () =>
                ref.read(activeQuizProvider.notifier).goToQuestion(i),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary
                    : isAnswered
                        ? AppColors.secondary.withOpacity(0.2)
                        : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary
                      : isAnswered
                          ? AppColors.secondary
                          : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCurrent
                        ? Colors.white
                        : isAnswered
                            ? AppColors.secondary
                            : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
