import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the **streak** badge (fire + day count) is shown on the home week header.
class HomeStreakBadgeNotifier extends Notifier<bool> {
  static const _prefsKey = 'home_show_streak_badge';

  @override
  bool build() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreFromPrefs());
    return true;
  }

  Future<void> _restoreFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_prefsKey);
      if (v != null) state = v;
    } on PlatformException {
      // Keep default until prefs are available.
    }
  }

  Future<void> setVisible(bool visible) async {
    state = visible;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, visible);
    } on PlatformException {
      // In-memory value still applies for this session.
    }
  }
}

final homeStreakBadgeProvider =
    NotifierProvider<HomeStreakBadgeNotifier, bool>(
  HomeStreakBadgeNotifier.new,
);
