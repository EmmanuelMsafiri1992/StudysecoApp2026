import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/subjects/screens/subjects_screen.dart';
import '../../features/subjects/screens/subject_detail_screen.dart';
import '../../features/subjects/screens/lesson_screen.dart';
import '../../features/quizzes/screens/quizzes_screen.dart';
import '../../features/quizzes/screens/quiz_screen.dart';
import '../../features/quizzes/screens/quiz_result_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/enrollment/screens/enrollment_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/post_detail_screen.dart';
import '../../features/community/screens/create_post_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/achievements/screens/achievements_screen.dart';
import '../../features/library/screens/library_screen.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final _authChangeNotifierProvider = Provider<_AuthChangeNotifier>(
  (ref) => _AuthChangeNotifier(ref),
);

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String subjects = '/subjects';
  static const String subjectDetail = '/subjects/:slug';
  static const String lesson = '/subjects/:slug/lessons/:lessonId';
  static const String quizzes = '/quizzes';
  static const String quiz = '/quizzes/:quizId';
  static const String quizResult = '/quizzes/:quizId/result';
  static const String payment = '/payment';
  static const String enrollment = '/enrollment';
  static const String community = '/community';
  static const String postDetail = '/community/:postId';
  static const String createPost = '/community/new';
  static const String profile = '/profile';
  static const String library = '/library';
  static const String achievements = '/achievements';
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_authChangeNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.onboarding ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.subjects,
            builder: (context, state) => const SubjectsScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (context, state) {
                  final slug = state.pathParameters['slug']!;
                  return SubjectDetailScreen(slug: slug);
                },
                routes: [
                  GoRoute(
                    path: 'lessons/:lessonId',
                    builder: (context, state) {
                      final slug = state.pathParameters['slug']!;
                      final lessonId = int.parse(state.pathParameters['lessonId']!);
                      final topicId = int.tryParse(state.uri.queryParameters['topicId'] ?? '') ?? 0;
                      return LessonScreen(subjectSlug: slug, lessonId: lessonId, topicId: topicId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.quizzes,
            builder: (context, state) => const QuizzesScreen(),
          ),
          GoRoute(
            path: AppRoutes.community,
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.library,
            builder: (context, state) => const LibraryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.quiz,
        builder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);
          return QuizScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.quizResult,
        builder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);
          return QuizResultScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.enrollment,
        builder: (context, state) => const EnrollmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.postDetail,
        builder: (context, state) {
          final postId = int.parse(state.pathParameters['postId']!);
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: AppRoutes.createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
    ],
  );
});

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<String> _routes = [
    AppRoutes.dashboard,
    AppRoutes.subjects,
    AppRoutes.library,
    AppRoutes.quizzes,
    AppRoutes.community,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(
            top: BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _navigate(context, 0),
                ),
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Subjects',
                  isActive: _currentIndex == 1,
                  onTap: () => _navigate(context, 1),
                ),
                _NavItem(
                  icon: Icons.library_books_outlined,
                  label: 'Library',
                  isActive: _currentIndex == 2,
                  onTap: () => _navigate(context, 2),
                ),
                _NavItem(
                  icon: Icons.assignment_outlined,
                  label: 'Quizzes',
                  isActive: _currentIndex == 3,
                  onTap: () => _navigate(context, 3),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  label: 'Community',
                  isActive: _currentIndex == 4,
                  onTap: () => _navigate(context, 4),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isActive: _currentIndex == 5,
                  onTap: () => _navigate(context, 5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
