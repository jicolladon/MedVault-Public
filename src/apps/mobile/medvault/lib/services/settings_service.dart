import 'package:drift/drift.dart';

import '../models/app_settings.dart';
import '../theme/app_theme_preference.dart';
import 'database.dart';

abstract interface class ThemePreferenceStore {
  Future<void> setThemePreference(AppThemePreference preference);

  Future<AppThemePreference> getThemePreference({
    AppThemePreference defaultValue = AppThemePreference.light,
  });
}

class SettingsService implements ThemePreferenceStore {
  SettingsService({AppDatabase? database}) : _db = database ?? AppDatabase();

  static const String darkModeKey = 'dark_mode';
  static const String themePreferenceKey = 'theme_preference';
  static const String useBiometricKey = 'use_biometric';
  static const String aceFirstTimeKey = 'ace_first_time';

  final AppDatabase _db;

  Future<void> setString(String key, String? value) async {
    await _upsertSetting(key, value);
  }

  Future<String?> getString(String key) async {
    final setting = await _getSetting(key);
    return setting?.value;
  }

  Future<void> setBool(String key, bool value) async {
    await _upsertSetting(key, value ? '1' : '0');
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final setting = await _getSetting(key);
    if (setting == null || setting.value == null) {
      return defaultValue;
    }
    return setting.value == '1';
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    await _db.transaction(() async {
      await _upsertSetting(themePreferenceKey, preference.storageValue);
      await _upsertSetting(
        darkModeKey,
        preference == AppThemePreference.dark ? '1' : '0',
      );
    });
  }

  @override
  Future<AppThemePreference> getThemePreference({
    AppThemePreference defaultValue = AppThemePreference.light,
  }) async {
    final rawPreference = await getString(themePreferenceKey);
    if (rawPreference != null && rawPreference.trim().isNotEmpty) {
      return AppThemePreferenceCodec.fromStorage(
        rawPreference,
        fallback: defaultValue,
      );
    }

    final legacyIsDark = await getBool(
      darkModeKey,
      defaultValue: defaultValue == AppThemePreference.dark,
    );
    return legacyIsDark ? AppThemePreference.dark : AppThemePreference.light;
  }

  Future<void> setDarkModeEnabled(bool value) async {
    await setThemePreference(
      value ? AppThemePreference.dark : AppThemePreference.light,
    );
  }

  Future<bool> getDarkModeEnabled({bool defaultValue = false}) async {
    final preference = await getThemePreference(
      defaultValue: defaultValue
          ? AppThemePreference.dark
          : AppThemePreference.light,
    );
    return preference == AppThemePreference.dark;
  }

  Future<void> setUseBiometric(bool value) async {
    await setBool(useBiometricKey, value);
  }

  Future<bool> getUseBiometric({bool defaultValue = true}) async {
    return getBool(useBiometricKey, defaultValue: defaultValue);
  }

  Future<void> setAceFirstTime(bool value) async {
    await setBool(aceFirstTimeKey, value);
  }

  Future<bool> getAceFirstTime({bool defaultValue = true}) async {
    return getBool(aceFirstTimeKey, defaultValue: defaultValue);
  }

  Future<bool> isDemoModeInit() async {
    return getBool('demo_mode_init', defaultValue: false);
  }

  Future<void> setDemoModeInit(bool value) async {
    await setBool('demo_mode_init', value);
  }

  Future<void> resetSettings() async {
    await _db.transaction(() async {
      await _db.delete(_db.settings).go();
    });
  }

  Future<void> deleteAllData() async {
    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.deleteAll(_db.medicalDocumentFiles);
        batch.deleteAll(_db.medicalDocuments);
        batch.deleteAll(_db.labResults);
        batch.deleteAll(_db.diagnoses);
        batch.deleteAll(_db.vaccinations);
        batch.deleteAll(_db.medications);
        batch.deleteAll(_db.allergies);
        batch.deleteAll(_db.bloodTypes);
        batch.deleteAll(_db.emergencyContactEntries);
        batch.deleteAll(_db.contacts);
        batch.deleteAll(_db.settings);
      });
    });
  }

  Future<AppSettings> getAppSettings() async {
    final useBiometric = await getUseBiometric();
    final isAceFirstTime = await getAceFirstTime();
    final themePreference = await getThemePreference();

    return AppSettings(
      useBiometric: useBiometric,
      isAceFirstTime: isAceFirstTime,
      darkModeEnabled: themePreference == AppThemePreference.dark,
    );
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    await _db.transaction(() async {
      await _upsertSetting(useBiometricKey, settings.useBiometric ? '1' : '0');
      await _upsertSetting(
        aceFirstTimeKey,
        settings.isAceFirstTime ? '1' : '0',
      );
      await _upsertSetting(
        themePreferenceKey,
        settings.darkModeEnabled
            ? AppThemePreference.dark.storageValue
            : AppThemePreference.light.storageValue,
      );
      await _upsertSetting(darkModeKey, settings.darkModeEnabled ? '1' : '0');
    });
  }

  Future<Setting?> _getSetting(String key) async {
    final query = _db.select(_db.settings)..where((tbl) => tbl.key.equals(key));
    return query.getSingleOrNull();
  }

  Future<void> _upsertSetting(String key, String? value) async {
    await _db
        .into(_db.settings)
        .insert(
          SettingsCompanion(key: Value(key), value: Value(value)),
          mode: InsertMode.insertOrReplace,
        );
  }
}
