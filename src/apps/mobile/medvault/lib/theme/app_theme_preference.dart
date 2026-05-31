import 'package:flutter/material.dart';

enum AppThemePreference { light, dark, system }

extension AppThemePreferenceCodec on AppThemePreference {
  String get storageValue {
    return switch (this) {
      AppThemePreference.light => 'light',
      AppThemePreference.dark => 'dark',
      AppThemePreference.system => 'system',
    };
  }

  ThemeMode get themeMode {
    return switch (this) {
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.system => ThemeMode.system,
    };
  }

  static AppThemePreference fromStorage(
    String? raw, {
    AppThemePreference fallback = AppThemePreference.light,
  }) {
    return switch (raw) {
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      'system' => AppThemePreference.system,
      _ => fallback,
    };
  }

  static AppThemePreference fromThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => AppThemePreference.light,
      ThemeMode.dark => AppThemePreference.dark,
      ThemeMode.system => AppThemePreference.system,
    };
  }
}
