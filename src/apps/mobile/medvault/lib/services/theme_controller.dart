import 'package:flutter/material.dart';
import '../theme/app_theme_preference.dart';
import 'settings_service.dart';

class ThemeController {
  ThemeController({required ThemePreferenceStore settingsService})
    : _settingsService = settingsService;

  final ThemePreferenceStore _settingsService;
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);
  final ValueNotifier<AppThemePreference> preference = ValueNotifier(
    AppThemePreference.light,
  );

  Future<void> load() async {
    final loadedPreference = await _settingsService.getThemePreference();
    _applyThemePreference(loadedPreference);
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    final nextPreference = AppThemePreferenceCodec.fromThemeMode(newMode);
    await setThemePreference(nextPreference);
  }

  Future<void> setThemePreference(AppThemePreference nextPreference) async {
    _applyThemePreference(nextPreference);
    await _settingsService.setThemePreference(nextPreference);
  }

  Future<void> toggleDarkMode(bool enabled) async {
    await setThemePreference(
      enabled ? AppThemePreference.dark : AppThemePreference.light,
    );
  }

  void dispose() {
    mode.dispose();
    preference.dispose();
  }

  void _applyThemePreference(AppThemePreference nextPreference) {
    preference.value = nextPreference;
    mode.value = nextPreference.themeMode;
  }
}
