import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/services/settings_service.dart';
import 'package:medvault/services/theme_controller.dart';
import 'package:medvault/theme/app_theme_preference.dart';

class _InMemoryThemePreferenceStore implements ThemePreferenceStore {
  _InMemoryThemePreferenceStore({
    this.initialPreference = AppThemePreference.light,
  }) : _storedPreference = initialPreference;

  final AppThemePreference initialPreference;
  AppThemePreference _storedPreference;

  @override
  Future<AppThemePreference> getThemePreference({
    AppThemePreference defaultValue = AppThemePreference.light,
  }) async {
    return _storedPreference;
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    _storedPreference = preference;
  }
}

void main() {
  group('ThemeController', () {
    test('load applies persisted dark preference', () async {
      final store = _InMemoryThemePreferenceStore(
        initialPreference: AppThemePreference.dark,
      );
      final controller = ThemeController(settingsService: store);

      await controller.load();

      expect(controller.mode.value, ThemeMode.dark);
      expect(controller.preference.value, AppThemePreference.dark);

      controller.dispose();
    });

    test('toggleDarkMode updates notifier state and persistence', () async {
      final store = _InMemoryThemePreferenceStore();
      final controller = ThemeController(settingsService: store);

      await controller.toggleDarkMode(true);

      expect(controller.mode.value, ThemeMode.dark);
      expect(controller.preference.value, AppThemePreference.dark);
      expect(await store.getThemePreference(), AppThemePreference.dark);

      await controller.toggleDarkMode(false);

      expect(controller.mode.value, ThemeMode.light);
      expect(controller.preference.value, AppThemePreference.light);
      expect(await store.getThemePreference(), AppThemePreference.light);

      controller.dispose();
    });

    test('setThemeMode maps ThemeMode.system to system preference', () async {
      final store = _InMemoryThemePreferenceStore();
      final controller = ThemeController(settingsService: store);

      await controller.setThemeMode(ThemeMode.system);

      expect(controller.mode.value, ThemeMode.system);
      expect(controller.preference.value, AppThemePreference.system);
      expect(await store.getThemePreference(), AppThemePreference.system);

      controller.dispose();
    });
  });
}
