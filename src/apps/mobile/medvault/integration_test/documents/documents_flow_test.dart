import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medvault/core/di/service_locator.dart';

import '../helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Documents flow integration tests', () {
    testWidgets('shows multi-file documents in list and detail views', (
      tester,
    ) async {
      await pumpApp(tester);

      final documentsService = ServiceLocator.instance.documentsService;
      await documentsService.initialize();

      final first = documentsService.createDraft(
        payload: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'scan-1.pdf',
        mimeType: 'application/pdf',
      );
      final second = documentsService.createDraft(
        payload: Uint8List.fromList([5, 6, 7, 8]),
        fileName: 'scan-2.pdf',
        mimeType: 'application/pdf',
      );

      await documentsService.createDocument(
        drafts: [first, second],
        title: 'MRI Report',
      );

      final documentsTab = find.text('Documents');
      expect(documentsTab, findsWidgets);
      await tester.tap(documentsTab.last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('MRI Report'), findsOneWidget);
      expect(find.textContaining('2 files'), findsOneWidget);

      await tester.tap(find.text('MRI Report'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('scan-1.pdf'), findsWidgets);
      expect(find.text('scan-2.pdf'), findsOneWidget);
    });
  });
}
