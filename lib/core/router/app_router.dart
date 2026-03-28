import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exam_ace/core/router/go_router_refresh_stream.dart';
import 'package:exam_ace/features/auth/providers/auth_provider.dart';
import 'package:exam_ace/features/auth/screens/sign_in_screen.dart';
import 'package:exam_ace/features/auth/screens/sign_up_screen.dart';
import 'package:exam_ace/features/splash/screens/splash_screen.dart';
import 'package:exam_ace/features/dashboard/screens/dashboard_screen.dart';
import 'package:exam_ace/features/calendar/screens/calendar_screen.dart';
import 'package:exam_ace/features/subjects/screens/subject_detail_screen.dart';
import 'package:exam_ace/features/subjects/screens/chapter_detail_screen.dart';
import 'package:exam_ace/features/profile/screens/notifications_screen.dart';
import 'package:exam_ace/features/profile/screens/about_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final refresh = GoRouterRefreshStream(firebaseAuth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = firebaseAuth.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up';
      final isSplash = state.matchedLocation == '/';

      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return '/sign-in';
      if (isLoggedIn && isAuthRoute) return '/main';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
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
