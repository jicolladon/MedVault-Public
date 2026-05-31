import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medvault/services/settings_service.dart';
import 'package:medvault/services/theme_controller.dart';
import 'package:medvault/theme/app_theme_preference.dart';
import 'package:medvault/theme/app_themes.dart';

class _InMemoryThemePreferenceStore implements ThemePreferenceStore {
  AppThemePreference _value = AppThemePreference.light;

  @override
  Future<AppThemePreference> getThemePreference({
    AppThemePreference defaultValue = AppThemePreference.light,
  }) async {
    return _value;
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    _value = preference;
  }
}

class _ThemeTestApp extends StatelessWidget {
  const _ThemeTestApp({required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          theme: AppThemes.light,
          darkTheme: AppThemes.dark,
          themeMode: mode,
          home: _ThemePage(
            title: 'Page A',
            enableNavigation: true,
            onToggleTheme: () async {
              await themeController.toggleDarkMode(mode != ThemeMode.dark);
            },
          ),
        );
      },
    );
  }
}

class _ThemePage extends StatelessWidget {
  const _ThemePage({
    required this.title,
    this.enableNavigation = false,
    this.onToggleTheme,
  });

  final String title;
  final bool enableNavigation;
  final VoidCallback? onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onToggleTheme != null)
            IconButton(
              key: const Key('theme_toggle'),
              onPressed: onToggleTheme,
              icon: const Icon(Icons.dark_mode),
            ),
          if (enableNavigation)
            IconButton(
              key: const Key('to_page_b'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _ThemePage(title: 'Page B'),
                  ),
                );
              },
              icon: const Icon(Icons.navigate_next),
            ),
        ],
      ),
      body: Center(child: Text('Brightness: $brightness')),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dark mode integration flow', () {
    testWidgets('applies dark mode consistently across pages', (tester) async {
      final store = _InMemoryThemePreferenceStore();
      final controller = ThemeController(settingsService: store);
      await controller.load();

      await tester.pumpWidget(_ThemeTestApp(themeController: controller));
      await tester.pumpAndSettle();

      expect(find.text('Page A'), findsOneWidget);
      expect(find.text('Brightness: Brightness.light'), findsOneWidget);

      await tester.tap(find.byKey(const Key('theme_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Brightness: Brightness.dark'), findsOneWidget);
      expect(await store.getThemePreference(), AppThemePreference.dark);

      await tester.tap(find.byKey(const Key('to_page_b')));
      await tester.pumpAndSettle();

      expect(find.text('Page B'), findsOneWidget);
      expect(find.text('Brightness: Brightness.dark'), findsOneWidget);

      controller.dispose();
    });
  });
}
