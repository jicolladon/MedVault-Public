import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/services/database.dart';
import 'package:medvault/services/settings_service.dart';
import 'package:medvault/theme/app_theme_preference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    late AppDatabase database;
    late SettingsService service;

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      service = SettingsService(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'persists and loads theme preference from local settings table',
      () async {
        await service.setThemePreference(AppThemePreference.dark);

        final row =
            await (database.select(database.settings)..where(
                  (tbl) => tbl.key.equals(SettingsService.themePreferenceKey),
                ))
                .getSingleOrNull();

        expect(row, isNot(equals(null)));
        expect(row?.value, AppThemePreference.dark.storageValue);
        expect(await service.getThemePreference(), AppThemePreference.dark);
        expect(await service.getDarkModeEnabled(), isTrue);
      },
    );

    test(
      'falls back to legacy dark_mode flag when theme preference is absent',
      () async {
        await service.setBool(SettingsService.darkModeKey, true);

        final preference = await service.getThemePreference();

        expect(preference, AppThemePreference.dark);
        expect(await service.getDarkModeEnabled(), isTrue);
      },
    );

    test('deleteAllData removes all persisted local rows', () async {
      final now = DateTime(2026, 4, 17);
      final payload = Uint8List.fromList(<int>[1, 2, 3]);

      await database
          .into(database.settings)
          .insert(
            SettingsCompanion(
              key: const Value('theme'),
              value: const Value('dark'),
            ),
          );

      await database
          .into(database.contacts)
          .insert(
            ContactsCompanion.insert(
              id: 'contact-1',
              name: 'Jane Doe',
              email: 'jane@example.com',
              phone: '+1-555-1111',
            ),
          );

      await database
          .into(database.bloodTypes)
          .insert(
            BloodTypesCompanion.insert(
              id: 'blood-1',
              userId: 'user@example.com',
              type: 'O+',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.allergies)
          .insert(
            AllergiesCompanion.insert(
              id: 'allergy-1',
              userId: 'user@example.com',
              name: 'Peanuts',
              severity: 'high',
              isCritical: true,
              createdAt: now,
              updatedAt: now,
              description: const Value('Severe allergy'),
              reactionType: const Value('Anaphylaxis'),
              notes: const Value('Carry epinephrine'),
              documentUrls: const Value('[]'),
            ),
          );

      await database
          .into(database.medicalDocuments)
          .insert(
            MedicalDocumentsCompanion.insert(
              id: 'doc-1',
              userId: 'user@example.com',
              title: 'Lab Report',
              documentType: 'pdf',
              fileName: 'lab-report.pdf',
              fileSizeBytes: 3,
              encryptedPayload: payload,
              createdAt: now,
              updatedAt: now,
              fileExtension: const Value('pdf'),
              mimeType: const Value('application/pdf'),
            ),
          );

      await database
          .into(database.medicalDocumentFiles)
          .insert(
            MedicalDocumentFilesCompanion.insert(
              id: 'doc-file-1',
              documentId: 'doc-1',
              userId: 'user@example.com',
              documentType: 'pdf',
              fileName: 'lab-report.pdf',
              fileSizeBytes: 3,
              encryptedPayload: payload,
              createdAt: now,
              updatedAt: now,
              fileExtension: const Value('pdf'),
              mimeType: const Value('application/pdf'),
            ),
          );

      await service.deleteAllData();

      expect(await database.select(database.settings).get(), isEmpty);
      expect(await database.select(database.contacts).get(), isEmpty);
      expect(await database.select(database.bloodTypes).get(), isEmpty);
      expect(await database.select(database.allergies).get(), isEmpty);
      expect(await database.select(database.medicalDocuments).get(), isEmpty);
      expect(
        await database.select(database.medicalDocumentFiles).get(),
        isEmpty,
      );
      expect(await database.select(database.medications).get(), isEmpty);
      expect(await database.select(database.vaccinations).get(), isEmpty);
      expect(await database.select(database.diagnoses).get(), isEmpty);
      expect(await database.select(database.labResults).get(), isEmpty);
      expect(
        await database.select(database.emergencyContactEntries).get(),
        isEmpty,
      );
    });
  });
}
