import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medvault/l10n/app_localizations.dart';
import 'package:medvault/widgets/loading_spinner.dart';

class _AsyncLoadingHarness extends StatefulWidget {
  const _AsyncLoadingHarness();

  @override
  State<_AsyncLoadingHarness> createState() => _AsyncLoadingHarnessState();
}

class _AsyncLoadingHarnessState extends State<_AsyncLoadingHarness> {
  bool _isLoading = false;
  int _completedActions = 0;

  Future<void> _runAsyncAction() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _completedActions++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        blockInteractions: true,
        semanticLabel: l10n.loadingInProgress,
        message: l10n.loadingInProgress,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                key: const Key('fetch_documents_button'),
                onPressed: _runAsyncAction,
                child: const Text('Fetch documents'),
              ),
              const SizedBox(height: 12),
              Text('Completed: $_completedActions'),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Loading spinner integration', () {
    testWidgets('spinner appears during async action and hides afterwards', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const _AsyncLoadingHarness(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byKey(const Key('fetch_documents_button')));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Completed: 1'), findsOneWidget);
    });
  });
}
