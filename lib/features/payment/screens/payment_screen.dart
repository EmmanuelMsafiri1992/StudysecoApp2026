import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/payment_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../../../shared/widgets/app_button.dart';
import 'paystack_webview_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      ref.read(paymentFlowProvider.notifier).selectCurrency(
            user?.currency ?? 'MWK',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentFlowProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.step > 0) {
          ref.read(paymentFlowProvider.notifier).goBack();
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: state.step > 0
              ? () => ref.read(paymentFlowProvider.notifier).goBack()
              : () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          _StepBar(step: state.step),
          Expanded(
            child: state.isSuccess
                ? _SuccessView()
                : [
                    _Step1Duration(state: state),
                    _Step2Method(state: state),
                    _Step3Confirm(state: state),
                  ][state.step.clamp(0, 2)],
          ),
        ],
      ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int step;
  const _StepBar({required this.step});

  @override
  Widget build(BuildContext context) {
    const steps = ['Duration', 'Method', 'Confirm'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: steps.asMap().entries.map((entry) {
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
                    const SizedBox(height: 2),
                    Text(label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                  ],
                ),
                if (i < steps.length - 1) const Expanded(child: SizedBox()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Step1Duration extends ConsumerWidget {
  final PaymentFlowState state;
  const _Step1Duration({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider(state.currency));
    final user = ref.watch(authProvider).user;
    final symbol = AppConstants.currencySymbols[state.currency] ?? state.currency;
    final subjectCount = user?.enrolledSubjectIds.length ?? 0;
    final rateDisplay = subjectCount > 0
        ? '$symbol${_monthlyRate(state.currency).toStringAsFixed(0)}/subject/month'
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Access Duration',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ).animate().fadeIn(),
          const SizedBox(height: 8),
          _EnrollmentSummaryBanner(),
          if (user?.form != null && user!.form!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.class_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Class: ${user.form}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (subjectCount > 0) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '$subjectCount subject${subjectCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (rateDisplay.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pricing: $rateDisplay  ·  Total = rate × months × subjects',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _CurrencySelector(selected: state.currency),
          const SizedBox(height: 16),
          plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) {
              final durations = subjectCount > 0
                  ? AccessDurationModel.getDefaultsForSubjects(state.currency, subjectCount)
                  : AccessDurationModel.getDefaults(state.currency);
              return Column(children: durations.map((d) => _DurationCard(
                duration: d,
                isSelected: state.selectedDuration?.months == d.months,
                onTap: () => ref.read(paymentFlowProvider.notifier).selectDuration(d),
                subjectCount: subjectCount,
              ).animate().fadeIn(delay: (durations.indexOf(d) * 100).ms)).toList());
            },
            data: (durations) => Column(
              children: durations.map((duration) => _DurationCard(
                duration: duration,
                isSelected: state.selectedDuration?.months == duration.months,
                onTap: () => ref.read(paymentFlowProvider.notifier).selectDuration(duration),
                subjectCount: subjectCount,
              ).animate().fadeIn(delay: (durations.indexOf(duration) * 100).ms)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  double _monthlyRate(String currency) {
    switch (currency.toUpperCase()) {
      case 'MWK': return 12500;
      case 'USD': return 8;
      case 'ZAR': return 150;
      case 'GBP': return 6;
      case 'EUR': return 7;
      default: return 8;
    }
  }
}

class _CurrencySelector extends ConsumerWidget {
  final String selected;
  const _CurrencySelector({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Text('Currency: ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<String>(
            value: selected,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: AppColors.surface,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            items: AppConstants.currencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(paymentFlowProvider.notifier).selectCurrency(v);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _DurationCard extends StatelessWidget {
  final AccessDurationModel duration;
  final bool isSelected;
  final VoidCallback onTap;
  final int subjectCount;

  const _DurationCard({
    required this.duration,
    required this.isSelected,
    required this.onTap,
    this.subjectCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = AppConstants.currencySymbols[duration.currency] ?? duration.currency;
    final subtitle = subjectCount > 0
        ? '$subjectCount subject${subjectCount == 1 ? '' : 's'} · ${duration.months} months'
        : '${duration.months} months · all content';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        duration.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (duration.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: duration.badge == 'Popular'
                                ? AppColors.primaryGradient
                                : AppColors.secondaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            duration.badge!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '$symbol${duration.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step2Method extends ConsumerWidget {
  final PaymentFlowState state;
  const _Step2Method({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ).animate().fadeIn(),
          const SizedBox(height: 4),
          Text(
            'Total: ${AppConstants.currencySymbols[state.currency] ?? state.currency}${state.selectedDuration?.price.toStringAsFixed(0) ?? '0'}',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          methodsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) =>
                const Text('Failed to load methods'),
            data: (methods) {
              final international =
                  methods.where((m) => m.isInternational).toList();
              final local =
                  methods.where((m) => !m.isInternational).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (international.isNotEmpty) ...[
                    const _SectionHeader(
                        label: 'International / Online',
                        icon: Icons.public_rounded),
                    ...international.map(
                      (m) => _MethodCard(
                        method: m,
                        isSelected:
                            state.selectedMethod?.id == m.id,
                        onTap: () => ref
                            .read(paymentFlowProvider.notifier)
                            .selectMethod(m),
                      ).animate().fadeIn(
                          delay: (international.indexOf(m) * 80).ms),
                    ),
                  ],
                  if (local.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _SectionHeader(
                        label: 'Local / Mobile Money',
                        icon: Icons.phone_android_rounded),
                    ...local.map(
                      (m) => _MethodCard(
                        method: m,
                        isSelected:
                            state.selectedMethod?.id == m.id,
                        onTap: () => ref
                            .read(paymentFlowProvider.notifier)
                            .selectMethod(m),
                      ).animate().fadeIn(
                          delay: (local.indexOf(m) * 80).ms),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final PaymentMethodModel method;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                method.isPaystack
                    ? Icons.credit_card_rounded
                    : method.type == 'bank_transfer'
                        ? Icons.account_balance_rounded
                        : Icons.phone_android_rounded,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (method.description != null)
                    Text(
                      method.description!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            if (method.isPaystack)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Instant',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3Confirm extends ConsumerStatefulWidget {
  final PaymentFlowState state;
  const _Step3Confirm({required this.state});

  @override
  ConsumerState<_Step3Confirm> createState() => _Step3ConfirmState();
}

class _Step3ConfirmState extends ConsumerState<_Step3Confirm> {
  final _refCtrl = TextEditingController();
  File? _proofFile;

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _proofFile = File(file.path));
  }

  Future<void> _pay() async {
    final state = widget.state;
    final method = state.selectedMethod!;
    final user = ref.read(authProvider).user;

    if (method.isPaystack) {
      final init = await ref
          .read(paymentFlowProvider.notifier)
          .initializePaystack(user?.email ?? '');
      if (!mounted) return;
      if (init == null) {
        final err = ref.read(paymentFlowProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err ?? 'Failed to initialize payment. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaystackWebViewScreen(
            authorizationUrl: init.authorizationUrl,
            reference: init.reference,
          ),
        ),
      );
      if (success == true && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _PendingApprovalDialog(),
        );
      }
    } else {
      final pendingSubjects = ref.read(pendingEnrollmentSubjectsProvider);
      final success = await ref.read(paymentFlowProvider.notifier).submitManualPayment(
            proofPath: _proofFile?.path,
            transactionRef: _refCtrl.text.trim().isEmpty
                ? null
                : _refCtrl.text.trim(),
            subjectIds: pendingSubjects.isNotEmpty ? pendingSubjects : null,
            gradeLevel: user?.form,
          );
      if (!mounted) return;
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _PendingApprovalDialog(),
        );
      } else {
        final err = ref.read(paymentFlowProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err ?? 'Failed to submit payment. Please try again.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final method = state.selectedMethod!;
    final symbol =
        AppConstants.currencySymbols[state.currency] ?? state.currency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Payment',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ).animate().fadeIn(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SummaryRow(
                    label: 'Duration',
                    value: state.selectedDuration!.label),
                const Divider(color: Colors.white24, height: 20),
                _SummaryRow(
                    label: 'Method', value: method.name),
                const Divider(color: Colors.white24, height: 20),
                _SummaryRow(
                  label: 'Amount',
                  value:
                      '$symbol${state.selectedDuration!.price.toStringAsFixed(0)} ${state.currency}',
                  isHighlight: true,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          if (!method.isPaystack) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Instructions',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  if (method.type == 'bank_transfer' || (!method.isPaystack && method.type != 'mobile_money'))
                    _BankDetailsWidget()
                  else if (method.name.toLowerCase().contains('mukuru'))
                    _MukuruDetailsWidget()
                  else
                    Text(
                      method.accountDetails ??
                          'Send payment to the account details below, then upload proof.',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaction Reference (optional)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _refCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g., TXN123456',
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.tag_rounded,
                        color: AppColors.textMuted, size: 20),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickProof,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _proofFile != null
                      ? AppColors.secondary.withOpacity(0.1)
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _proofFile != null
                        ? AppColors.secondary
                        : AppColors.border,
                    style: _proofFile == null
                        ? BorderStyle.solid
                        : BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _proofFile != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_rounded,
                      color: _proofFile != null
                          ? AppColors.secondary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _proofFile != null
                          ? 'Proof uploaded ✓'
                          : 'Upload Proof of Payment',
                      style: TextStyle(
                          color: _proofFile != null
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: method.isPaystack
                ? 'Pay with Paystack'
                : 'Submit Payment',
            onTap: _pay,
            isLoading: state.isLoading,
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_rounded,
                    size: 12, color: AppColors.textMuted),
                SizedBox(width: 4),
                Text('All payments are secure and encrypted',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isHighlight ? 18 : 14,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EnrollmentSummaryBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final subjectCount = user?.enrolledSubjectIds.length ?? 0;
    final hasActive = user?.hasActiveSubscription ?? false;
    final expiresAt = user?.subscriptionExpiresAt;
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasActive && !isExpired
            ? AppColors.secondary.withOpacity(0.1)
            : AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActive && !isExpired
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
                hasActive && !isExpired
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                size: 16,
                color: hasActive && !isExpired
                    ? AppColors.secondary
                    : AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                hasActive && !isExpired
                    ? 'Subscription Active'
                    : isExpired
                        ? 'Subscription Expired'
                        : 'No Active Subscription',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasActive && !isExpired
                      ? AppColors.secondary
                      : AppColors.error,
                ),
              ),
            ],
          ),
          if (subjectCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$subjectCount subject${subjectCount == 1 ? '' : 's'} enrolled · price calculated per subject',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (expiresAt != null) ...[
            const SizedBox(height: 2),
            Text(
              isExpired
                  ? 'Expired: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}'
                  : 'Expires: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
              style: TextStyle(
                fontSize: 11,
                color: isExpired ? AppColors.error : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _BankDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _BankDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Standard Bank — MWK Transfer',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        SizedBox(height: 8),
        _BankDetailRow(label: 'Account Name', value: 'Emphx Innovative Solutions Limited'),
        _BankDetailRow(label: 'Account Number', value: '9100008695854'),
        _BankDetailRow(label: 'Currency', value: 'MWK'),
        _BankDetailRow(label: 'Branch', value: 'Lilongwe'),
        _BankDetailRow(label: 'Branch Code', value: '101016'),
        _BankDetailRow(label: 'Swift Code', value: 'SBICMWMX'),
        SizedBox(height: 10),
        Text(
          'After transferring, upload proof of payment below.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }
}

class _MukuruDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Bank Zero — Mukuru',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        SizedBox(height: 8),
        _BankDetailRow(label: 'Bank', value: 'Bank Zero - Mukuru'),
        _BankDetailRow(label: 'Account Number', value: '70012910209'),
        _BankDetailRow(label: 'Branch Code', value: '435000'),
        SizedBox(height: 10),
        Text(
          'After sending, upload proof of payment below.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }
}

class _PendingApprovalDialog extends ConsumerWidget {
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
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: AppColors.accent, size: 36),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          const Text(
            'Payment Submitted!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your payment is awaiting approval. You will receive access once it has been confirmed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Back to Dashboard',
            onTap: () {
              Navigator.pop(context);
              ref.read(paymentFlowProvider.notifier).reset();
              context.go('/dashboard');
            },
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              gradient: AppColors.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 50),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          const Text(
            'Your subscription is now active. Enjoy learning!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 40),
          GradientButton(
            label: 'Start Learning',
            onTap: () {
              ref.read(paymentFlowProvider.notifier).reset();
              context.go('/dashboard');
            },
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
