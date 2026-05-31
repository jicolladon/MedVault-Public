import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/l10n/app_localizations.dart';
import 'package:medvault/widgets/loading_spinner.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('Loading widgets', () {
    testWidgets('LoadingSpinner exposes localized semantic label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithApp(const LoadingSpinner()));

      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(spinner.semanticsLabel, 'Loading, please wait');
    });

    testWidgets('LoadingSpinner applies custom style values', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          const LoadingSpinner(
            size: 40,
            strokeWidth: 5,
            color: Colors.deepOrange,
          ),
        ),
      );

      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.strokeWidth, 5);
      expect(spinner.color, Colors.deepOrange);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(LoadingSpinner),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 40);
      expect(sizedBox.height, 40);
    });

    testWidgets('LoadingOverlay shows and hides spinner with loading state', (
      tester,
    ) async {
      var isLoading = false;

      await tester.pumpWidget(
        _wrapWithApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = !isLoading;
                      });
                    },
                    child: const Text('toggle'),
                  ),
                  Expanded(
                    child: LoadingOverlay(
                      isLoading: isLoading,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('toggle'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('toggle'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('LoadingOverlay interaction behavior is configurable', (
      tester,
    ) async {
      var taps = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          LoadingOverlay(
            isLoading: true,
            child: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('tap me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pump();
      expect(taps, 1);

      taps = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          LoadingOverlay(
            isLoading: true,
            blockInteractions: true,
            child: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('tap me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
    });
  });
}
