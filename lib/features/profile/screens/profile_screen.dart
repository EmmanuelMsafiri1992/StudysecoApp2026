import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user != null && _nameCtrl.text.isEmpty) {
      _nameCtrl.text = user.name;
      _schoolCtrl.text = user.schoolName ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user?.hasActiveSubscription == true
                          ? AppColors.secondary.withOpacity(0.2)
                          : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.hasActiveSubscription == true
                          ? '✓ Active Subscription'
                          : '✕ No Subscription',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: user?.hasActiveSubscription == true
                            ? AppColors.secondary
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_isEditing) ...[
                    AppTextField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'School Name',
                      controller: _schoolCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'Save Changes',
                      onTap: () async {
                        await ref.read(authProvider.notifier).updateProfile({
                          'name': _nameCtrl.text.trim(),
                          'school_name': _schoolCtrl.text.trim(),
                        });
                        setState(() => _isEditing = false);
                      },
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _InfoCard(
                    icon: Icons.class_rounded,
                    label: 'Current Form',
                    value: user?.form ?? '-',
                  ),
                  _InfoCard(
                    icon: Icons.location_on_rounded,
                    label: 'Country',
                    value: user?.country ?? '-',
                  ),
                  _InfoCard(
                    icon: Icons.currency_exchange_rounded,
                    label: 'Currency',
                    value: user?.currency ?? '-',
                  ),
                  if (user?.hasActiveSubscription == true &&
                      user?.subscriptionExpiresAt != null)
                    _InfoCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Subscription Expires',
                      value:
                          '${user!.subscriptionExpiresAt!.day}/${user.subscriptionExpiresAt!.month}/${user.subscriptionExpiresAt!.year}',
                    ),
                  const SizedBox(height: 16),
                  const _SectionDivider(label: 'Account'),
                  _MenuTile(
                    icon: Icons.emoji_events_rounded,
                    label: 'Achievements',
                    color: AppColors.accent,
                    onTap: () => context.push(AppRoutes.achievements),
                  ),
                  _MenuTile(
                    icon: Icons.credit_card_rounded,
                    label: 'Payment History',
                    color: AppColors.secondary,
                    onTap: () => context.push(AppRoutes.payment),
                  ),
                  _MenuTile(
                    icon: Icons.school_rounded,
                    label: 'Enrollment',
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.enrollment),
                  ),
                  const SizedBox(height: 8),
                  const _SectionDivider(label: 'More'),
                  _MenuTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    color: const Color(0xFF06B6D4),
                    onTap: () {},
                  ),
                  _MenuTile(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Privacy Policy',
                    color: AppColors.textMuted,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Sign Out',
                    isOutlined: true,
                    color: AppColors.error,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text('Sign Out'),
                          content: const Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel')),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) {
                                  context.go(AppRoutes.login);
                                }
                              },
                              child: const Text('Sign Out',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ).animate().fadeIn(),
                  const SizedBox(height: 32),
                  const Text(
                    'StudySeco v1.0.0',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
