import 'package:flutter_test/flutter_test.dart';

import 'package:medvault/main.dart';
import 'package:medvault/core/di/service_locator.dart';
import 'package:medvault/core/env/app_environment.dart';

Future<void> pumpApp(WidgetTester tester) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  try {
    if (ServiceLocator.instance.environment != AppEnvironment.demo) {
      await ServiceLocator.instance.init(AppEnvironment.demo);
    }
  } catch (_) {
    await ServiceLocator.instance.init(AppEnvironment.demo);
  }

  await ServiceLocator.instance.settingsService.setDemoModeInit(true);
  await ServiceLocator.instance.settingsService.setAceFirstTime(false);
  await ServiceLocator.instance.settingsService.setUseBiometric(false);
  await ServiceLocator.instance.authService.signInWithGoogleAndBackend();
  await ServiceLocator.instance.authService.markOnboardingComplete();

  await tester.pumpWidget(
    MyApp(themeController: ServiceLocator.instance.themeController),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 1));
}
