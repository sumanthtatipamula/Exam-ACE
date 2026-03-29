import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/firebase_options.dart';
import 'package:exam_ace/core/services/notification_service.dart';
import 'package:exam_ace/core/services/deep_link_service.dart';
import 'package:exam_ace/core/settings/startup_prefs.dart';
import 'package:exam_ace/core/router/app_router.dart';
import 'package:exam_ace/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final StartupPrefs startupPrefs;
  try {
    startupPrefs = await StartupPrefs.load();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('StartupPrefs.load failed; using defaults. $e\n$st');
    }
    startupPrefs = StartupPrefs.defaults();
  }
  try {
    await SharedPreferences.getInstance();
  } catch (_) {/* SyllabusSortNotifier and others also guard reads */}
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  
  // Get initial deep link
  final initialUri = await DeepLinkService.getInitialLink();
  String? initialLocation;
  
  if (initialUri != null) {
    final parsed = DeepLinkService.parseDeepLink(initialUri);
    if (parsed != null) {
      final path = parsed['path'] as String;
      final params = parsed['params'] as Map<String, String>;
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      initialLocation = queryString.isNotEmpty ? '$path?$queryString' : path;
    }
  }
  
  runApp(
    ProviderScope(
      overrides: [
        startupPrefsProvider.overrideWith((ref) => startupPrefs),
        if (initialLocation != null)
          initialDeepLinkProvider.overrideWith((ref) => initialLocation),
      ],
      child: const ExamAceApp(),
    ),
  );
}
