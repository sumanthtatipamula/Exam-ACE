import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/constants/app_strings.dart';
import 'package:exam_ace/core/router/app_router.dart';
import 'package:exam_ace/core/theme/app_theme.dart';
import 'package:exam_ace/core/theme/theme_provider.dart';

class ExamAceApp extends ConsumerWidget {
  const ExamAceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
