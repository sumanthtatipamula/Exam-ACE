import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/router/app_router.dart';
import 'package:exam_ace/core/theme/app_theme.dart';
import 'package:exam_ace/core/theme/app_colors.dart';
import 'package:exam_ace/core/theme/theme_provider.dart';
import 'package:exam_ace/core/theme/color_preset_provider.dart';
import 'package:exam_ace/core/services/deep_link_service.dart';

class ExamAceApp extends ConsumerStatefulWidget {
  const ExamAceApp({super.key});

  @override
  ConsumerState<ExamAceApp> createState() => _ExamAceAppState();
}

class _ExamAceAppState extends ConsumerState<ExamAceApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _linkSubscription = DeepLinkService.linkStream.listen((uri) {
      final parsed = DeepLinkService.parseDeepLink(uri);
      if (parsed != null && mounted) {
        final path = parsed['path'] as String;
        final params = parsed['params'] as Map<String, String>;

        // Delay navigation to let Firebase Auth state settle after app resume.
        // Without this, GoRouter's refreshListenable (auth state) can race
        // with the go() call and override the deep link navigation.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          final router = ref.read(routerProvider);

          if (path == '/reset-password' && params['token'] != null) {
            router.go('/reset-password?token=${Uri.encodeComponent(params['token']!)}');
          } else if (path == '/verify-email' && params['token'] != null) {
            router.go('/verify-email?token=${Uri.encodeComponent(params['token']!)}');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colorPreset = ref.watch(appColorPresetProvider);

    return MaterialApp.router(
      title: 'Exam Ace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(colorPreset.palette),
      darkTheme: AppTheme.dark(colorPreset.palette),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
