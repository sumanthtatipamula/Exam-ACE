import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/router/app_router.dart';
import 'package:exam_ace/core/theme/app_theme.dart';
import 'package:exam_ace/core/theme/app_colors.dart';
import 'package:exam_ace/core/theme/theme_provider.dart';
import 'package:exam_ace/core/theme/color_preset_provider.dart';

class ExamAceApp extends ConsumerWidget {
  const ExamAceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
