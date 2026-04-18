import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/core/constants/app_strings.dart';
import 'package:exam_ace/core/router/app_router.dart';
import 'package:exam_ace/features/onboarding/screens/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Check for initial deep link
    final initialDeepLink = ref.read(initialDeepLinkProvider);
    if (initialDeepLink != null) {
      // Deep link present — navigate immediately after frame builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(initialDeepLink);
        }
      });
    } else {
      // Normal launch — show splash then check onboarding status
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone =
            prefs.getBool(kOnboardingCompleteKey) ?? false;
        if (!mounted) return;
        context.go(onboardingDone ? '/sign-in' : '/onboarding');
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_rounded,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.appTitle,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your competitive exam tracker',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
