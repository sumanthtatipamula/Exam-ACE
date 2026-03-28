import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_ace/core/settings/startup_prefs.dart';
import 'package:exam_ace/core/theme/app_color_preset.dart';

class AppColorPresetNotifier extends Notifier<AppColorPreset> {
  @override
  AppColorPreset build() {
    return ref.read(startupPrefsProvider).colorPreset;
  }

  Future<void> setPreset(AppColorPreset preset) async {
    state = preset;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.appColorPreset, preset.name);
    } on PlatformException {
      // In-memory preset still applies for this session.
    }
  }
}

final appColorPresetProvider =
    NotifierProvider<AppColorPresetNotifier, AppColorPreset>(
  AppColorPresetNotifier.new,
);
