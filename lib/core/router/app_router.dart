import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/core/router/go_router_refresh_stream.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/features/auth/screens/sign_in_screen.dart';
import 'package:exam_ace/features/auth/screens/sign_up_screen.dart';
import 'package:exam_ace/features/auth/screens/reset_password_screen.dart';
import 'package:exam_ace/features/auth/screens/verify_email_screen.dart';
import 'package:exam_ace/features/auth/screens/email_verification_pending_screen.dart';
import 'package:exam_ace/features/splash/screens/splash_screen.dart';
import 'package:exam_ace/features/onboarding/screens/onboarding_screen.dart';
import 'package:exam_ace/features/dashboard/screens/dashboard_screen.dart';
import 'package:exam_ace/features/calendar/screens/calendar_screen.dart';
import 'package:exam_ace/features/subjects/screens/subject_detail_screen.dart';
import 'package:exam_ace/features/subjects/screens/chapter_detail_screen.dart';
import 'package:exam_ace/features/profile/screens/notifications_screen.dart';
import 'package:exam_ace/features/profile/screens/about_screen.dart';

// Provider for initial deep link location
final initialDeepLinkProvider = StateProvider<String?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final refresh = GoRouterRefreshStream(firebaseAuth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) {
      print('Router error: ${state.error}');
      return Scaffold(
        body: Center(
          child: Text('Navigation error: ${state.error}'),
        ),
      );
    },
    redirect: (context, state) {
      final user = firebaseAuth.currentUser;
      final isLoggedIn = user != null;
      final isEmailVerified = user?.emailVerified ?? false;
      final path = state.matchedLocation;
      
      // Logged-in verified user on auth pages → send to main
      if (isLoggedIn && isEmailVerified) {
        if (path == '/' || path == '/sign-in' || path == '/sign-up') {
          return '/main';
        }
      }

      // Always allow these routes without any auth checks
      if (path == '/' || 
          path == '/onboarding' ||
          path == '/sign-in' || 
          path == '/sign-up' ||
          path.startsWith('/reset-password') || 
          path.startsWith('/verify-email') ||
          path.startsWith('/email-verification-pending')) {
        return null;
      }
      
      // Protected routes (main, calendar, etc.)
      // Not logged in - redirect to sign-in
      if (!isLoggedIn) {
        return '/sign-in';
      }
      
      // Logged in but email not verified - sign out and redirect
      if (!isEmailVerified) {
        firebaseAuth.signOut();
        return '/sign-in';
      }
      
      // User is logged in and verified - allow access
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: 'signUp',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'resetPassword',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verifyEmail',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return VerifyEmailScreen(token: token);
        },
      ),
      GoRoute(
        path: '/email-verification-pending',
        name: 'emailVerificationPending',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationPendingScreen(email: email);
        },
      ),
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/subject/:id',
        name: 'subjectDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SubjectDetailScreen(subjectId: id);
        },
      ),
      GoRoute(
        path: '/subject/:id/chapter/:chapterId',
        name: 'chapterDetail',
        builder: (context, state) {
          final subjectId = state.pathParameters['id']!;
          final chapterId = state.pathParameters['chapterId']!;
          return ChapterDetailScreen(
              subjectId: subjectId, chapterId: chapterId);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) {
          final section = state.uri.queryParameters['section'];
          return AboutScreen(
            scrollToWeekScoreSection: section == 'week-score',
          );
        },
      ),
    ],
  );
});
