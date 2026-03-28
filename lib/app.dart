import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/constants/app_strings.dart';
import 'package:exam_ace/core/router/app_router.dart';
import 'package:exam_ace/core/theme/app_colors.dart';
import 'package:exam_ace/core/theme/app_theme.dart';
import 'package:exam_ace/core/theme/color_preset_provider.dart';
import 'package:exam_ace/core/theme/theme_provider.dart';

class ExamAceApp extends ConsumerWidget {
  const ExamAceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(appColorPresetProvider).palette;

    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(palette),
      darkTheme: AppTheme.dark(palette),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
