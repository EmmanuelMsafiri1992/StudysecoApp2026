import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/subject_model.dart';
import '../providers/subjects_provider.dart';
import 'package:shimmer/shimmer.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String slug;
  const SubjectDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsState = ref.watch(topicsProvider(slug));

    return Scaffold(
      body: topicsState.isLoading
          ? _Loading()
          : topicsState.error != null
              ? _ErrorView(
                  onRetry: () => ref
                      .read(topicsProvider(slug).notifier)
                      .loadTopics(slug))
              : _SubjectContent(slug: slug, topics: topicsState.topics),
    );
  }
}

class _SubjectContent extends StatelessWidget {
  final String slug;
  final List<TopicModel> topics;

  const _SubjectContent({required this.slug, required this.topics});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              slug.replaceAll('-', ' ').split(' ').map((w) =>
                  w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
                  .join(' '),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: const Center(
                child: Icon(Icons.book_rounded,
                    size: 80, color: Colors.white24),
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final topic = topics[index];
                return _TopicAccordion(
                  topic: topic,
                  subjectSlug: slug,
                ).animate().fadeIn(delay: (index * 50).ms);
              },
              childCount: topics.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _TopicAccordion extends StatefulWidget {
  final TopicModel topic;
  final String subjectSlug;

  const _TopicAccordion({required this.topic, required this.subjectSlug});

  @override
  State<_TopicAccordion> createState() => _TopicAccordionState();
}

class _TopicAccordionState extends State<_TopicAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final completedLessons =
        widget.topic.lessons.where((l) => l.isCompleted).length;
    final total = widget.topic.lessons.length;
    final progress = total > 0 ? completedLessons / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 22,
                    lineWidth: 3,
                    percent: progress.clamp(0, 1),
                    center: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                    progressColor: AppColors.secondary,
                    backgroundColor: AppColors.surfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.topic.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$completedLessons/$total lessons',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            ...widget.topic.lessons.map((lesson) => _LessonTile(
                  lesson: lesson,
                  subjectSlug: widget.subjectSlug,
                )),
          ],
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LessonModel lesson;
  final String subjectSlug;

  const _LessonTile({required this.lesson, required this.subjectSlug});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
          '/subjects/$subjectSlug/lessons/${lesson.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: lesson.isCompleted
                    ? AppColors.secondary.withOpacity(0.15)
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                lesson.isCompleted
                    ? Icons.check_circle_rounded
                    : _getLessonIcon(lesson.type),
                color: lesson.isCompleted
                    ? AppColors.secondary
                    : AppColors.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: lesson.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${lesson.durationMinutes} min • ${lesson.type}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}

class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        children: [
          Container(height: 200, color: Colors.white),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Failed to load content',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
