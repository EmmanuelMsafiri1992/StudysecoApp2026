import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/subject_model.dart';
import '../providers/subjects_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:shimmer/shimmer.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final form = ref.read(authProvider).user?.form;
      ref.read(subjectsProvider.notifier).loadSubjects(form: form);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subjectsProvider);
    final user = ref.watch(authProvider).user;
    final userForm = user?.form;
    final enrolledIds = user?.enrolledSubjectIds ?? [];

    String normalizeForm(String v) {
      final s = v.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
      final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
      return digits != null ? 'form$digits' : s;
    }

    final enrolled = state.subjects.where((s) {
      if (!s.isEnrolled) return false;
      if (userForm != null && userForm.isNotEmpty && s.form.isNotEmpty) {
        return normalizeForm(s.form) == normalizeForm(userForm);
      }
      return true;
    }).toList();

    final localEnrolledFromIds = enrolledIds.isNotEmpty && enrolled.isEmpty && state.subjects.isNotEmpty
        ? state.subjects.where((s) => enrolledIds.contains(s.id)).toList()
        : <SubjectModel>[];

    final displayList = enrolled.isNotEmpty ? enrolled : localEnrolledFromIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add More Subjects',
            onPressed: () => context.push(AppRoutes.enrollment),
          ),
        ],
      ),
      body: state.isLoading
          ? _LoadingGrid()
          : (state.error != null && displayList.isEmpty)
              ? _ErrorView(
                  onRetry: () =>
                      ref.read(subjectsProvider.notifier).loadSubjects(form: userForm))
              : displayList.isEmpty
                  ? (enrolledIds.isNotEmpty
                      ? _ErrorView(
                          onRetry: () => ref
                              .read(subjectsProvider.notifier)
                              .loadSubjects(form: userForm))
                      : _EmptyView(onEnroll: () => context.push(AppRoutes.enrollment)))
                  : Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              return SubjectCard(subject: displayList[index])
                                  .animate()
                                  .fadeIn(delay: (index * 50).ms)
                                  .slideY(begin: 0.2, end: 0);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;

  const SubjectCard({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(subject.color);
    return GestureDetector(
      onTap: () => context.push('/subjects/${subject.id}'),
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.$1.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(subject.icon),
                      color: colors.$1, size: 22),
                ),
                if (subject.isCore)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Core',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              subject.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${subject.topicsCount} topics',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            if (subject.progressPercent != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (subject.progressPercent! / 100).clamp(0, 1),
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colors.$1),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${subject.progressPercent!.toInt()}%',
                style: TextStyle(
                    fontSize: 10, color: colors.$1),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, Color) _getColors(String? colorStr) {
    switch (colorStr?.toLowerCase()) {
      case 'green':
        return (AppColors.secondary, const Color(0xFF059669));
      case 'amber':
      case 'yellow':
        return (AppColors.accent, const Color(0xFFD97706));
      case 'red':
        return (const Color(0xFFEF4444), const Color(0xFFB91C1C));
      case 'blue':
        return (const Color(0xFF3B82F6), const Color(0xFF1D4ED8));
      case 'pink':
        return (const Color(0xFFEC4899), const Color(0xFFBE185D));
      case 'cyan':
        return (const Color(0xFF06B6D4), const Color(0xFF0891B2));
      default:
        return (AppColors.primary, AppColors.primaryLight);
    }
  }

  IconData _getIcon(String? icon) {
    switch (icon) {
      case 'calculator':
        return Icons.calculate_rounded;
      case 'language':
        return Icons.translate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'history':
        return Icons.history_edu_rounded;
      case 'geography':
        return Icons.public_rounded;
      case 'commerce':
        return Icons.business_rounded;
      case 'computer':
        return Icons.computer_rounded;
      default:
        return Icons.book_rounded;
    }
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
        children: List.generate(
          6,
          (_) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
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
          const Text('Failed to load subjects',
              style: TextStyle(color: AppColors.textSecondary)),
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

class _EmptyView extends StatelessWidget {
  final VoidCallback onEnroll;
  const _EmptyView({required this.onEnroll});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'No subjects enrolled yet',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enroll in subjects to start learning',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onEnroll,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Enroll in Subjects'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
