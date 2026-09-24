import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/payment/providers/payment_provider.dart';
import '../../../features/subjects/providers/subjects_provider.dart';
import '../../../shared/widgets/app_button.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  int _step = 0;
  final Set<int> _selectedSubjectIds = {};
  String? _loadedForForm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjectsForUser();
    });
  }

  void _loadSubjectsForUser() {
    final user = ref.read(authProvider).user;
    final form = user?.form;
    if (_loadedForForm != form) {
      _loadedForForm = form;
      ref.read(subjectsProvider.notifier).loadSubjects(form: form);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    if (user?.form != null && user!.form != _loadedForForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubjectsForUser());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subjects'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _step > 0
              ? () => setState(() => _step--)
              : () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(step: _step),
          Expanded(
            child: _step == 0
                ? _SubjectSelectionStep(
                    userForm: user?.form,
                    selectedIds: _selectedSubjectIds,
                    onToggle: (id) {
                      setState(() {
                        if (_selectedSubjectIds.contains(id)) {
                          _selectedSubjectIds.remove(id);
                        } else {
                          _selectedSubjectIds.add(id);
                        }
                      });
                    },
                  )
                : _ConfirmStep(
                    selectedSubjectIds: _selectedSubjectIds,
                    user: user,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _step == 0
                ? GradientButton(
                    label: 'Continue (${_selectedSubjectIds.length} selected)',
                    onTap: _next,
                  )
                : GradientButton(
                    label: 'Confirm & Proceed to Payment',
                    onTap: _enroll,
                  ),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_selectedSubjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one subject'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _step = 1);
  }

  void _enroll() {
    ref.read(pendingEnrollmentSubjectsProvider.notifier).state =
        _selectedSubjectIds.toList();
    if (mounted) context.go('/payment');
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Select', 'Confirm'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isActive = step == i;
          final isDone = step > i;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isDone
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : Text('${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textMuted,
                                )),
                      ),
                    ),
                    Text(label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textMuted,
                        )),
                  ],
                ),
                if (i < labels.length - 1) const Expanded(child: SizedBox()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubjectSelectionStep extends ConsumerWidget {
  final String? userForm;
  final Set<int> selectedIds;
  final void Function(int) onToggle;

  const _SubjectSelectionStep({
    required this.userForm,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subjectsProvider);

    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    String normalizeForm(String f) {
      final s = f.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
      final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
      return digits != null ? 'form$digits' : s;
    }

    final anyHasForm = state.subjects.any((s) => s.form.isNotEmpty);
    final formSubjects = (userForm != null && userForm!.isNotEmpty && anyHasForm)
        ? state.subjects.where((s) => normalizeForm(s.form) == normalizeForm(userForm!)).toList()
        : state.subjects;
    final enrolled = formSubjects.where((s) => s.isEnrolled).toList();
    final unenrolled = formSubjects.where((s) => !s.isEnrolled).toList();

    if (state.error != null && formSubjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Failed to load subjects',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => ref.read(subjectsProvider.notifier).loadSubjects(form: userForm),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (formSubjects.isEmpty && !state.isLoading && state.error == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 56, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              userForm != null
                  ? 'No subjects available for $userForm'
                  : 'No subjects available',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            if (userForm == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Please update your profile with your current form.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          userForm != null ? 'Subjects for $userForm' : 'Select Subjects',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        Text(
          '${selectedIds.length} selected',
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        if (enrolled.isNotEmpty) ...[
          const Text(
            'Already Enrolled',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: enrolled.length,
            itemBuilder: (context, index) {
              final subject = enrolled[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
        if (unenrolled.isNotEmpty) ...[
          const Text(
            'Available to Add',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: unenrolled.length,
            itemBuilder: (context, index) {
              final subject = unenrolled[index];
              final isSelected = selectedIds.contains(subject.id);
              return GestureDetector(
                onTap: () => onToggle(subject.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      Icon(
                        isSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subject.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 30).ms);
            },
          ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'You are already enrolled in all available subjects for your class.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _ConfirmStep extends ConsumerWidget {
  final Set<int> selectedSubjectIds;
  final dynamic user;

  const _ConfirmStep({
    required this.selectedSubjectIds,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider).subjects;
    final selected =
        subjects.where((s) => selectedSubjectIds.contains(s.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Subjects',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          _SummaryCard(
            label: 'Student',
            value: user?.name ?? '',
            icon: Icons.person_rounded,
          ),
          _SummaryCard(
            label: 'Form',
            value: user?.form ?? '',
            icon: Icons.class_rounded,
          ),
          const SizedBox(height: 16),
          const Text(
            'Subjects to Add',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...selected.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(s.name,
                      style: const TextStyle(
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.accent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payment is required to access content for these subjects.',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
