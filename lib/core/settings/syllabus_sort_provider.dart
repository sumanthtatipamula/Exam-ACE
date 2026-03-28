import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/core/settings/syllabus_sort_mode.dart';

class SyllabusSortNotifier extends Notifier<SyllabusSortMode> {
  static const _prefsKey = 'syllabus_sort_mode';

  @override
  SyllabusSortMode build() {
    // After first frame the platform plugin channel is reliably connected
    // (avoids LegacyUserDefaultsApi channel-error on iOS/macOS during hot restart / early init).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreFromPrefs();
    });
    return SyllabusSortMode.creation;
  }

  Future<void> _restoreFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      for (final m in SyllabusSortMode.values) {
        if (m.name == raw) {
          state = m;
          return;
        }
      }
    } on PlatformException {
      // Channel not ready; keep default until next launch or user changes sort.
    }
  }

  Future<void> setMode(SyllabusSortMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } on PlatformException {
      // In-memory sort still applies for this session.
    }
  }
}

final syllabusSortProvider =
    NotifierProvider<SyllabusSortNotifier, SyllabusSortMode>(
  SyllabusSortNotifier.new,
);
