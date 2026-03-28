import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/firebase_options.dart';
import 'package:exam_ace/core/services/notification_service.dart';
import 'package:exam_ace/core/settings/startup_prefs.dart';
import 'package:exam_ace/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final StartupPrefs startupPrefs;
  try {
    startupPrefs = await StartupPrefs.load();
  } catch (_) {
    startupPrefs = StartupPrefs.defaults();
  }
  try {
    await SharedPreferences.getInstance();
  } catch (_) {/* SyllabusSortNotifier and others also guard reads */}
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(
    ProviderScope(
      overrides: [
        startupPrefsProvider.overrideWithValue(startupPrefs),
      ],
      child: const ExamAceApp(),
    ),
  );
}
