import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';

class _Page {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;

  const _Page({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

const _pages = [
  _Page(
    title: 'Master Your MANEB Exams',
    subtitle:
        'Complete Form 1–4 curriculum aligned with MANEB standards. Study smarter with interactive lessons and practice tests.',
    icon: Icons.school_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _Page(
    title: 'All 19 MSCE Subjects',
    subtitle:
        'Mathematics, Sciences, Languages, Commerce and more. Full coverage of every subject you need to excel.',
    icon: Icons.book_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF059669)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _Page(
    title: 'Practice & Improve',
    subtitle:
        'Topic quizzes, mock exams, instant feedback and detailed explanations. Track your progress with beautiful charts.',
    icon: Icons.quiz_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _Page(
    title: 'Study From Anywhere',
    subtitle:
        'Access your courses from Malawi or abroad. Pay in MWK, USD, ZAR, GBP and more. Join thousands of students.',
    icon: Icons.public_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    await StorageService.setBool(AppConstants.onboardingKey, true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    TextButton(
                      onPressed: _done,
                      child: const Text('Skip',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              gradient: page.gradient,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Image.asset(
                                'assets/images/icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                              .animate()
                              .scale(
                                  duration: 600.ms,
                                  curve: Curves.elasticOut)
                              .fadeIn(),
                          const SizedBox(height: 48),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.3, end: 0),
                          const SizedBox(height: 16),
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.3, end: 0),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        dotColor: AppColors.textMuted,
                        activeDotColor: AppColors.primary,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_currentPage == _pages.length - 1)
                      GradientButton(
                        label: 'Get Started',
                        onTap: _done,
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Login',
                              isOutlined: true,
                              onTap: () => context.go(AppRoutes.login),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              label: 'Next',
                              onTap: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
