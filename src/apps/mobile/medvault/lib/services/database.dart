import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

part 'database.g.dart';

const String _dbFileName = 'medvault.db';
const String _dbEncryptionKeyStorageKey = 'medvault_db_encryption_key';

Future<void> configureSqlCipherForApp() async {
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
}

/// Contacts table definition
class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get photoBase64 => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Settings table definition
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Blood Type table definition
class BloodTypes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Allergies table definition
class Allergies extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get severity => text()(); // low, medium, high, critical
  TextColumn get reactionType => text().nullable()();
  BoolColumn get isCritical => boolean()();
  TextColumn get notes => text().nullable()();
  TextColumn get documentUrls => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Medications table definition
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get dosage => text().nullable()();
  TextColumn get frequency => text()(); // Daily, Weekly, etc.
  TextColumn get prescribedBy => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get sideEffects => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get documentUrls => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Vaccinations table definition
class Vaccinations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  DateTimeColumn get dateReceived => dateTime()();
  TextColumn get provider => text().nullable()();
  TextColumn get batchNumber => text().nullable()();
  DateTimeColumn get nextDueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get documentUrls => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Diagnoses table definition
class Diagnoses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get status => text()(); // active, chronic, resolved, expired
  DateTimeColumn get diagnosedDate => dateTime()();
  DateTimeColumn get resolvedDate => dateTime().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get treatmentPlan => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get documentUrls => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Lab Results table definition
class LabResults extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get testName => text()();
  TextColumn get category => text()();
  DateTimeColumn get testDate => dateTime()();
  TextColumn get values => text()(); // JSON array of test values
  TextColumn get doctorInterpretation => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get documentUrls => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Emergency contacts table definition
class EmergencyContactEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get relationship => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Medical documents table definition.
class MedicalDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get documentDate => dateTime().nullable()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get tags => text().nullable()();
  TextColumn get documentType => text()();
  TextColumn get fileName => text()();
  TextColumn get fileExtension => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get fileSizeBytes => integer()();
  BlobColumn get encryptedPayload => blob()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Medical document files table definition.
class MedicalDocumentFiles extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(MedicalDocuments, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()();
  TextColumn get documentType => text()();
  TextColumn get fileName => text()();
  TextColumn get fileExtension => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get fileSizeBytes => integer()();
  BlobColumn get encryptedPayload => blob()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Main database class
@DriftDatabase(
  tables: [
    Contacts,
    Settings,
    BloodTypes,
    Allergies,
    Medications,
    Vaccinations,
    Diagnoses,
    LabResults,
    EmergencyContactEntries,
    MedicalDocuments,
    MedicalDocumentFiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 5) {
        await _createTableIfMissing(
          tableName: 'contacts',
          createTable: () => m.createTable(contacts),
        );
        await _createTableIfMissing(
          tableName: 'settings',
          createTable: () => m.createTable(settings),
        );
        await _createTableIfMissing(
          tableName: 'blood_types',
          createTable: () => m.createTable(bloodTypes),
        );
        await _createTableIfMissing(
          tableName: 'allergies',
          createTable: () => m.createTable(allergies),
        );
        await _createTableIfMissing(
          tableName: 'medications',
          createTable: () => m.createTable(medications),
        );
        await _createTableIfMissing(
          tableName: 'vaccinations',
          createTable: () => m.createTable(vaccinations),
        );
        await _createTableIfMissing(
          tableName: 'diagnoses',
          createTable: () => m.createTable(diagnoses),
        );
        await _createTableIfMissing(
          tableName: 'lab_results',
          createTable: () => m.createTable(labResults),
        );
        await _createTableIfMissing(
          tableName: 'emergency_contact_entries',
          createTable: () => m.createTable(emergencyContactEntries),
        );
      }

      if (from < 6) {
        await _createTableIfMissing(
          tableName: 'medical_documents',
          createTable: () => m.createTable(medicalDocuments),
        );
      }

      if (from < 7) {
        await _addColumnIfMissing(
          tableName: 'medical_documents',
          columnName: 'category',
          columnDefinition: "category TEXT NOT NULL DEFAULT 'other'",
        );
        await _addColumnIfMissing(
          tableName: 'medical_documents',
          columnName: 'tags',
          columnDefinition: 'tags TEXT',
        );
      }

      if (from < 8) {
        await _createTableIfMissing(
          tableName: 'medical_document_files',
          createTable: () => m.createTable(medicalDocumentFiles),
        );
        await _backfillLegacyMedicalDocumentFiles();
      }
    },
  );

  Future<void> _backfillLegacyMedicalDocumentFiles() async {
    final documents = await select(medicalDocuments).get();

    for (final document in documents) {
      final existingFile = await (select(
        medicalDocumentFiles,
      )..where((tbl) => tbl.documentId.equals(document.id))).getSingleOrNull();

      if (existingFile != null) {
        continue;
      }

      await into(medicalDocumentFiles).insert(
        MedicalDocumentFilesCompanion.insert(
          id: '${document.id}-legacy-0',
          documentId: document.id,
          userId: document.userId,
          documentType: document.documentType,
          fileName: document.fileName,
          fileExtension: Value(document.fileExtension),
          mimeType: Value(document.mimeType),
          fileSizeBytes: document.fileSizeBytes,
          encryptedPayload: document.encryptedPayload,
          sortOrder: const Value(0),
          createdAt: document.createdAt,
          updatedAt: document.updatedAt,
        ),
      );
    }
  }

  Future<void> _createTableIfMissing({
    required String tableName,
    required Future<void> Function() createTable,
  }) async {
    final existing = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(tableName)],
    ).getSingleOrNull();

    if (existing == null) {
      await createTable();
    }
  }

  Future<void> _addColumnIfMissing({
    required String tableName,
    required String columnName,
    required String columnDefinition,
  }) async {
    final columns = await customSelect('PRAGMA table_info($tableName)').get();
    final exists = columns.any((row) => row.data['name'] == columnName);
    if (exists) {
      return;
    }

    await customStatement(
      'ALTER TABLE $tableName ADD COLUMN $columnDefinition',
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, _dbFileName));
    final secureStorage = const FlutterSecureStorage();
    final encryptionKey = await _getOrCreateEncryptionKey(secureStorage);
    final escapedKey = _escapeSqlString(encryptionKey);

    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        database.execute("PRAGMA key = '$escapedKey';");
        database.execute('PRAGMA foreign_keys = ON;');
        database.execute('PRAGMA journal_mode = WAL;');
      },
    );
  });
}

String _escapeSqlString(String value) {
  return value.replaceAll("'", "''");
}

Future<String> _getOrCreateEncryptionKey(
  FlutterSecureStorage secureStorage,
) async {
  final existing = await secureStorage.read(key: _dbEncryptionKeyStorageKey);
  if (existing != null && existing.isNotEmpty) {
    return existing;
  }

  final random = Random.secure();
  final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
  final generated = base64UrlEncode(keyBytes);

  await secureStorage.write(key: _dbEncryptionKeyStorageKey, value: generated);
  return generated;
}
