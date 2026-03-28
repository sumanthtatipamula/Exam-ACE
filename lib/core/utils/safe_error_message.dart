import 'package:flutter/foundation.dart';

/// Avoid showing raw exception text in release builds (can leak paths, SDK details).
String userFacingError(
  Object error, {
  required String debugPrefix,
  String releaseMessage = 'Something went wrong. Please try again.',
}) {
  if (kDebugMode) return '$debugPrefix: $error';
  return releaseMessage;
}
