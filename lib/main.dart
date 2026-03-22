import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:exam_ace/firebase_options.dart';
import 'package:exam_ace/core/services/notification_service.dart';
import 'package:exam_ace/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(const ProviderScope(child: ExamAceApp()));
}
