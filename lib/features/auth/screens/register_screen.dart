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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  String _selectedForm = 'Form 1';
  String _selectedCurrency = 'USD';
  int _step = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).register({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'password_confirmation': _confirmCtrl.text,
      'form': _selectedForm,
      'currency': _selectedCurrency,
      'school_name': _schoolCtrl.text.trim(),
    });
    if (!success && mounted) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? 'Registration failed'),
            backgroundColor: AppColors.error),
      );
    }
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
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _StepIndicator(currentStep: _step),
                const SizedBox(height: 32),
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
                ] else ...[
                  const Text(
                    'School Details',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'School Name (optional)',
                    hint: 'St. Michael Secondary School',
                    controller: _schoolCtrl,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(Icons.business_rounded,
                        color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(height: 16),
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
                    label: 'Create Account',
                    onTap: _register,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Back',
                    isOutlined: true,
                    onTap: () => setState(() => _step = 0),
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

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Dot(active: currentStep == 0, done: currentStep > 0, label: '1'),
        Expanded(
            child: Divider(
                color: currentStep > 0
                    ? AppColors.primary
                    : AppColors.divider,
                thickness: 2)),
        _Dot(active: currentStep == 1, done: false, label: '2'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final bool done;
  final String label;

  const _Dot({required this.active, required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active || done ? AppColors.primary : AppColors.surfaceVariant,
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(label,
                style: TextStyle(
                    color: active ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
      ),
    );
  }
}
