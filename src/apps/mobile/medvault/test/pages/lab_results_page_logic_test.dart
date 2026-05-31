import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/models/medical_models.dart';
import 'package:medvault/pages/medical/lab_results_page.dart';

void main() {
  group('Lab results list detail visibility', () {
    LabResult buildResult({
      required List<LabTestValue> values,
      String? interpretation,
      String? notes,
    }) {
      final now = DateTime(2026, 1, 1);
      return LabResult(
        id: '1',
        userId: 'user-1',
        testName: 'Panel',
        category: 'Blood',
        testDate: now,
        values: values,
        doctorInterpretation: interpretation,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('shows details for single-value result', () {
      final result = buildResult(
        values: [
          LabTestValue(
            name: 'LDL',
            value: '140',
            unit: 'mg/dL',
            status: TestResultStatus.abnormal,
          ),
        ],
      );

      expect(shouldShowLabResultDetails(result), isTrue);
    });

    test('shows details when interpretation exists without values', () {
      final result = buildResult(
        values: const [],
        interpretation: 'Follow up in 3 months',
      );

      expect(shouldShowLabResultDetails(result), isTrue);
    });

    test('hides details only when no values and no notes', () {
      final result = buildResult(values: const []);

      expect(shouldShowLabResultDetails(result), isFalse);
    });
  });
}
