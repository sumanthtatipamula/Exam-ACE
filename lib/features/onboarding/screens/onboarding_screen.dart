import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/core/constants/app_strings.dart';

/// SharedPreferences key to track whether the user has completed onboarding.
const String kOnboardingCompleteKey = 'ea_onboarding_complete';

/// Provider that reads the onboarding-complete flag from SharedPreferences.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kOnboardingCompleteKey) ?? false;
});

/// Marks onboarding as complete in SharedPreferences.
Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingCompleteKey, true);
}

/// Resets onboarding so it shows again (used by "Replay Tutorial" in settings).
Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingCompleteKey, false);
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      icon: Icons.school_rounded,
      title: 'Welcome to ${AppStrings.appTitle}',
      description:
          'Your all-in-one companion for competitive exam preparation. '
          'Track your syllabus, schedule tasks, and monitor progress — all in one place.',
    ),
    _OnboardingPageData(
      icon: Icons.menu_book_rounded,
      title: 'Organize Your Syllabus',
      description:
          'Add subjects, chapters, and topics. Mark them as complete as you study. '
          'The app tracks your overall progress so you always know where you stand.',
    ),
    _OnboardingPageData(
      icon: Icons.playlist_add_check_rounded,
      title: 'Daily Tasks & Streaks',
      description:
          'Create daily study tasks and check them off as you go. '
          'Build streaks to stay consistent and see your weekly progress at a glance.',
    ),
    _OnboardingPageData(
      icon: Icons.note_alt_rounded,
      title: 'Mock Tests & Exam Scores',
      description:
          'Log mock test results and real exam scores to track improvement over time. '
          'Identify weak areas and focus your revision where it matters most.',
    ),
    _OnboardingPageData(
      icon: Icons.calendar_month_rounded,
      title: 'Calendar & History',
      description:
          'View your study history on a calendar. See which days you were active, '
          'review past tasks, and plan ahead for exams.',
    ),
    _OnboardingPageData(
      icon: Icons.notifications_active_rounded,
      title: 'Stay on Track',
      description:
          'Set morning and evening reminders so you never miss a study session. '
          'Customize notification times to fit your schedule.',
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkip() => _completeOnboarding();

  Future<void> _completeOnboarding() async {
    await markOnboardingComplete();
    if (mounted) context.go('/sign-in');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPage(data: page);
                },
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _currentPage ? 28 : 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _onNext,
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 56,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
