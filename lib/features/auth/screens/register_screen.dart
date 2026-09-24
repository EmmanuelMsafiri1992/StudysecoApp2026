import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../../subjects/providers/subjects_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _selectedForm = 'Form 1';
  String _selectedCurrency = 'MWK';
  final Set<int> _selectedSubjectIds = {};
  int _step = 0;
  bool _accountCreated = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_accountCreated) return;
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).registerOnly({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'password_confirmation': _confirmCtrl.text,
      'form': _selectedForm,
      'grade_level': _selectedForm,
      'currency': _selectedCurrency,
      'country': 'Malawi',
    });
    if (success && mounted) {
      setState(() {
        _accountCreated = true;
        _step = 2;
      });
      ref.read(subjectsProvider.notifier).loadSubjects(form: _selectedForm);
    } else if (mounted) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? 'Registration failed'),
            backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _enroll() async {
    if (_selectedSubjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one subject'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    await ref.read(authProvider.notifier).enrollSubjects(
      _selectedSubjectIds.toList(),
      form: _selectedForm,
    );
    if (mounted) context.go(AppRoutes.dashboard);
  }

  void _skipEnrollment() {
    ref.read(authProvider.notifier).finishRegistration();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/icon.png', height: 36, fit: BoxFit.contain),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _accountCreated
              ? null
              : _step > 0
                  ? () => setState(() => _step--)
                  : () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _StepIndicator(currentStep: _step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      if (_step == 0) ...[
                        const Text(
                          'Personal Details',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Full Name',
                          hint: 'John Banda',
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: const Icon(Icons.person_rounded,
                              color: AppColors.textMuted, size: 20),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Email Address',
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_rounded,
                              color: AppColors.textMuted, size: 20),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Phone Number',
                          hint: '+265 999 000 000',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_rounded,
                              color: AppColors.textMuted, size: 20),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Password',
                          hint: 'Min. 8 characters',
                          controller: _passwordCtrl,
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock_rounded,
                              color: AppColors.textMuted, size: 20),
                          validator: (v) {
                            if (v == null || v.length < 8)
                              return 'Password must be at least 8 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          controller: _confirmCtrl,
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock_rounded,
                              color: AppColors.textMuted, size: 20),
                          validator: (v) {
                            if (v != _passwordCtrl.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        GradientButton(
                          label: 'Continue',
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _step = 1);
                            }
                          },
                        ),
                      ] else if (_step == 1) ...[
                        const Text(
                          'Your Class & Currency',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 24),
                        _buildDropdown(
                          label: 'Current Form',
                          value: _selectedForm,
                          items: AppConstants.forms,
                          onChanged: (v) => setState(() => _selectedForm = v!),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Preferred Currency',
                          value: _selectedCurrency,
                          items: AppConstants.currencies,
                          onChanged: (v) => setState(() => _selectedCurrency = v!),
                        ),
                        const SizedBox(height: 32),
                        GradientButton(
                          label: 'Continue',
                          onTap: _createAccount,
                          isLoading: authState.isLoading,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Back',
                          isOutlined: true,
                          onTap: () => setState(() => _step = 0),
                        ),
                      ] else ...[
                        _SubjectSelectionStep(
                          selectedForm: _selectedForm,
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
                        const SizedBox(height: 24),
                        GradientButton(
                          label: 'Finish Setup (${_selectedSubjectIds.length} selected)',
                          onTap: _enroll,
                          isLoading: authState.isLoading,
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: _skipEnrollment,
                            child: const Text(
                              'Skip for now',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(color: AppColors.textMuted),
                              children: [
                                TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SubjectSelectionStep extends ConsumerWidget {
  final String selectedForm;
  final Set<int> selectedIds;
  final void Function(int) onToggle;

  const _SubjectSelectionStep({
    required this.selectedForm,
    required this.selectedIds,
    required this.onToggle,
  });

  static String _normalizeForm(String form) {
    final s = form.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');
    final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
    return digits != null ? 'form$digits' : s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subjectsProvider);
    final anyHasForm = state.subjects.any((s) => s.form.isNotEmpty);
    final filtered = anyHasForm
        ? state.subjects.where((s) => _normalizeForm(s.form) == _normalizeForm(selectedForm)).toList()
        : state.subjects;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Subjects for $selectedForm',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 4),
        Text(
          '${selectedIds.length} selected',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (state.isLoading)
          const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary)))
        else if (state.error != null && filtered.isEmpty)
          Column(
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 8),
              Text(
                'Could not load subjects. Please check your connection.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => ref.read(subjectsProvider.notifier).loadPublicSubjects(form: selectedForm),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          )
        else if (filtered.isEmpty && !state.isLoading)
          Column(
            children: [
              const Icon(Icons.school_outlined, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 8),
              Text(
                'No subjects found for $selectedForm.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => ref.read(subjectsProvider.notifier).loadPublicSubjects(form: selectedForm),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final subject = filtered[index];
              final isSelected = selectedIds.contains(subject.id);
              return GestureDetector(
                onTap: () => onToggle(subject.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Details', 'Class', 'Subjects'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isActive = currentStep == i;
          final isDone = currentStep > i;
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isDone
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? AppColors.primary : AppColors.textMuted,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
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
