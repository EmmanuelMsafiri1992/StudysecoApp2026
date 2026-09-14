import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/subject_model.dart';
import '../providers/subjects_provider.dart';
import 'package:shimmer/shimmer.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  String? _selectedForm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectsProvider.notifier).loadSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _FormFilter(
            selected: _selectedForm,
            onSelect: (form) {
              setState(() => _selectedForm = form);
              ref.read(subjectsProvider.notifier).filterByForm(form);
            },
          ),
          Expanded(
            child: state.isLoading
                ? _LoadingGrid()
                : state.error != null
                    ? _ErrorView(
                        onRetry: () => ref
                            .read(subjectsProvider.notifier)
                            .loadSubjects(form: _selectedForm))
                    : Builder(builder: (context) {
                        final enrolled = state.subjects
                            .where((s) => s.isEnrolled)
                            .toList();
                        final displayList = enrolled.isEmpty
                            ? state.subjects
                            : enrolled;
                        return displayList.isEmpty
                            ? const _EmptyView()
                            : GridView.builder(
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
                                  return SubjectCard(
                                    subject: displayList[index],
                                  )
                                      .animate()
                                      .fadeIn(delay: (index * 50).ms)
                                      .slideY(begin: 0.2, end: 0);
                                },
                              );
                      }),
          ),
        ],
      ),
    );
  }
}

class _FormFilter extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelect;

  const _FormFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final forms = ['All', ...AppConstants.forms];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: forms.length,
        itemBuilder: (context, index) {
          final form = forms[index];
          final isAll = form == 'All';
          final isSelected =
              (isAll && selected == null) || (!isAll && selected == form);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(form),
              selected: isSelected,
              onSelected: (_) => onSelect(isAll ? null : form),
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
          );
        },
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
      onTap: () => context.push('/subjects/${subject.slug}'),
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
            if (subject.isEnrolled && subject.progressPercent != null) ...[
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
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('No subjects found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
