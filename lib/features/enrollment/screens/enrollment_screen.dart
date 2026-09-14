import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/subjects/providers/subjects_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class EnrollmentScreen extends ConsumerStatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  ConsumerState<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends ConsumerState<EnrollmentScreen> {
  int _step = 0;
  final Set<int> _selectedSubjectIds = {};
  final _formKey = GlobalKey<FormState>();
  String _selectedForm = 'Form 1';
  final _schoolCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectsProvider.notifier).loadSubjects();
    });
  }

  @override
  void dispose() {
    _schoolCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll'),
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
            child: [
              _SubjectSelectionStep(
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
              ),
              _PersonalDetailsStep(
                formKey: _formKey,
                selectedForm: _selectedForm,
                schoolCtrl: _schoolCtrl,
                phoneCtrl: _phoneCtrl,
                onFormChanged: (v) => setState(() => _selectedForm = v!),
              ),
              _SummaryStep(
                selectedSubjectIds: _selectedSubjectIds,
                selectedForm: _selectedForm,
                school: _schoolCtrl.text,
                phone: _phoneCtrl.text,
              ),
            ][_step],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _step == 2
                ? GradientButton(
                    label: 'Complete Enrollment',
                    onTap: _enroll,
                    isLoading: _isLoading,
                  )
                : GradientButton(
                    label: _step == 0
                        ? 'Continue (${_selectedSubjectIds.length} selected)'
                        : 'Next',
                    onTap: _next,
                  ),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_step == 0) {
      if (_selectedSubjectIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one subject'),
              backgroundColor: AppColors.error),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _step = 2);
    }
  }

  Future<void> _enroll() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(apiServiceProvider).createEnrollment(
        subjectIds: _selectedSubjectIds.toList(),
        personalDetails: {
          'form': _selectedForm,
          'school_name': _schoolCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        },
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SuccessDialog(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Enrollment failed: ${e.toString()}'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Subjects', 'Details', 'Summary'];
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
                      color:
                          isDone ? AppColors.primary : AppColors.divider,
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
                if (i < labels.length - 1)
                  const Expanded(child: SizedBox()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubjectSelectionStep extends ConsumerWidget {
  final Set<int> selectedIds;
  final void Function(int) onToggle;

  const _SubjectSelectionStep({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Your Subjects',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              Text(
                '${selectedIds.length} selected',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: state.subjects.length,
            itemBuilder: (context, index) {
              final subject = state.subjects[index];
              final isSelected = selectedIds.contains(subject.id);
              return GestureDetector(
                onTap: () => onToggle(subject.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
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
        ),
      ],
    );
  }
}

class _PersonalDetailsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String selectedForm;
  final TextEditingController schoolCtrl;
  final TextEditingController phoneCtrl;
  final void Function(String?) onFormChanged;

  const _PersonalDetailsStep({
    required this.formKey,
    required this.selectedForm,
    required this.schoolCtrl,
    required this.phoneCtrl,
    required this.onFormChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Details',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Form',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: selectedForm,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 15),
                    items: AppConstants.forms
                        .map((f) =>
                            DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: onFormChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'School Name (optional)',
              hint: 'St. Michael Secondary School',
              controller: schoolCtrl,
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.business_rounded,
                  color: AppColors.textMuted, size: 20),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Phone Number (optional)',
              hint: '+265 999 000 000',
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_rounded,
                  color: AppColors.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStep extends ConsumerWidget {
  final Set<int> selectedSubjectIds;
  final String selectedForm;
  final String school;
  final String phone;

  const _SummaryStep({
    required this.selectedSubjectIds,
    required this.selectedForm,
    required this.school,
    required this.phone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider).subjects;
    final selected = subjects
        .where((s) => selectedSubjectIds.contains(s.id))
        .toList();
    final user = ref.watch(authProvider).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enrollment Summary',
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
            label: 'Email',
            value: user?.email ?? '',
            icon: Icons.email_rounded,
          ),
          _SummaryCard(
            label: 'Form',
            value: selectedForm,
            icon: Icons.class_rounded,
          ),
          if (school.isNotEmpty)
            _SummaryCard(
              label: 'School',
              value: school,
              icon: Icons.business_rounded,
            ),
          const SizedBox(height: 16),
          const Text(
            'Selected Subjects',
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
              border: Border.all(
                  color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.accent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your account will be created. Payment required to access content.',
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

class _SuccessDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              gradient: AppColors.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 36),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          const Text('Enrolled!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'You\'re enrolled. Complete your payment to access all content.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Make Payment',
            onTap: () {
              Navigator.pop(context);
              context.go('/payment');
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            child: const Text('Pay Later'),
          ),
        ],
      ),
    );
  }
}
