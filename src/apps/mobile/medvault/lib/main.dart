import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/service_locator.dart';
import 'core/env/app_environment.dart';
import 'l10n/app_localizations.dart';
import 'pages/landing_page.dart';
import 'pages/home_page.dart';
import 'services/database.dart';
import 'services/theme_controller.dart';
import 'theme/app_themes.dart';
import 'widgets/loading_spinner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureSqlCipherForApp();
  const rawEnv = String.fromEnvironment('APP_ENV', defaultValue: 'demo');
  final appEnvironment = parseAppEnvironment(rawEnv);
  await ServiceLocator.instance.init(appEnvironment);
  runApp(MyApp(themeController: ServiceLocator.instance.themeController));
}

class MyApp extends StatelessWidget {
  final ThemeController themeController;

  const MyApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppThemes.light,
          darkTheme: AppThemes.dark,
          themeMode: mode,
          home: const AuthGate(),
          routes: {
            '/landing': (_) => const LandingPage(),
            '/home': (_) => const HomePage(),
          },
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ServiceLocator.instance.authService.hasValidSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: LoadingSpinner(
                semanticLabel: AppLocalizations.of(context)?.loadingInProgress,
              ),
            ),
          );
        }
        final isValid = snapshot.data == true;
        return isValid ? const HomePage() : const LandingPage();
      },
    );
  }
}
