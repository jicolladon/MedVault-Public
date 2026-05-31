import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB localization completeness', () {
    late Map<String, dynamic> en;
    late Map<String, dynamic> es;
    late Map<String, dynamic> ca;

    setUpAll(() {
      final enFile = File('lib/l10n/app_en.arb');
      final esFile = File('lib/l10n/app_es.arb');
      final caFile = File('lib/l10n/app_ca.arb');

      en = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      es = jsonDecode(esFile.readAsStringSync()) as Map<String, dynamic>;
      ca = jsonDecode(caFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('Spanish ARB contains all translatable keys from English ARB', () {
      final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
      final esKeys = es.keys.where((key) => !key.startsWith('@')).toSet();

      final missing = enKeys.difference(esKeys).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason: 'Missing keys in app_es.arb: ${missing.join(', ')}',
      );
    });

    test('Spanish ARB overrides known fallback-prone labels', () {
      expect(es['relationshipRequired'], isNot('Relationship is required'));
      expect(es['labResults'], isNot('Lab Results'));
      expect(es['sharingPermissionsLabel'], equals('Permisos'));
    });

    test('Catalan ARB contains all translatable keys from English ARB', () {
      final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
      final caKeys = ca.keys.where((key) => !key.startsWith('@')).toSet();

      final missing = enKeys.difference(caKeys).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason: 'Missing keys in app_ca.arb: ${missing.join(', ')}',
      );
    });

    test('Catalan ARB overrides known fallback-prone labels', () {
      expect(ca['relationshipRequired'], isNot('Relationship is required'));
      expect(ca['labResults'], isNot('Lab Results'));
      expect(ca['sharingPermissionsLabel'], isNot('Permissions'));
    });
  });
}
