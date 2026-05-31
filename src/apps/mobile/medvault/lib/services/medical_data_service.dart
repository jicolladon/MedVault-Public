import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../models/medical_models.dart';
import 'database.dart' as db;
import 'auth_service.dart';

typedef CurrentUserProvider = Future<AuthUser?> Function();

class MedicalDataService extends ChangeNotifier {
  MedicalDataService({
    required CurrentUserProvider currentUserProvider,
    db.AppDatabase? database,
  }) : _currentUserProvider = currentUserProvider,
       _db = database ?? db.AppDatabase() {
    _loadFromDatabase();
  }

  final CurrentUserProvider _currentUserProvider;
  final db.AppDatabase _db;

  String _bloodType = BloodGroup.unknown.value;
  String get bloodType => _bloodType;

  static const String _labResultTypesSettingsKey = 'lab_result_types';

  List<Allergy> _allergies = [];
  List<Allergy> get allergies => _allergies;

  List<Medication> _medications = [];
  List<Medication> get medications => _medications;

  List<Vaccination> _vaccinations = [];
  List<Vaccination> get vaccinations => _vaccinations;

  List<Diagnosis> _diagnoses = [];
  List<Diagnosis> get diagnoses => _diagnoses;

  List<LabResult> _labResults = [];
  List<LabResult> get labResults => _labResults;

  List<LabResultType> _labResultTypes = [];
  List<LabResultType> get labResultTypes => _labResultTypes;

  Future<void> reload() async {
    await _loadFromDatabase();
  }

  Future<void> clear() async {
    _bloodType = BloodGroup.unknown.value;
    _allergies = [];
    _medications = [];
    _vaccinations = [];
    _diagnoses = [];
    _labResults = [];
    _labResultTypes = [];
    notifyListeners();
  }

  Future<void> _loadFromDatabase() async {
    final user = await _currentUserProvider();
    if (user == null) return;
    final userId = user.email;

    final bq =
        await (_db.select(_db.bloodTypes)
              ..where((tbl) => tbl.userId.equals(userId))
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (bq != null) {
      _bloodType = bq.type;
    }

    await syncListsFromDb(userId);

    await _loadLabResultTypes();
    await _ensureLabResultTypesCoverResults();

    notifyListeners();
  }

  Future<void> seedDemoData(String userId) async {
    if (_allergies.isEmpty ||
        _medications.isEmpty ||
        _vaccinations.isEmpty ||
        _diagnoses.isEmpty ||
        _labResults.isEmpty) {
      await _seedDemoData(userId);
      await syncListsFromDb(userId);
    }
    _bloodType = 'A+';
    await updateBloodType('A+');
  }

  Future<void> syncListsFromDb(String userId) async {
    final dbAllergies = await (_db.select(
      _db.allergies,
    )..where((t) => t.userId.equals(userId))).get();
    _allergies = dbAllergies
        .map(
          (a) => Allergy(
            id: a.id,
            userId: a.userId,
            substance: a.name,
            reaction: a.reactionType ?? '',
            severity: AllergySeverity.values.firstWhere(
              (e) => e.name == a.severity,
              orElse: () => AllergySeverity.moderate,
            ),
            notes: a.notes,
            createdAt: a.createdAt,
            updatedAt: a.updatedAt,
          ),
        )
        .toList();

    final dbMeds = await (_db.select(
      _db.medications,
    )..where((t) => t.userId.equals(userId))).get();
    _medications = dbMeds
        .map(
          (m) => Medication(
            id: m.id,
            userId: m.userId,
            name: m.name,
            dosage: m.dosage ?? '',
            frequency: m.frequency,
            startDate: m.startDate ?? DateTime.now(),
            status: MedicationStatus.active,
            createdAt: m.createdAt,
            updatedAt: m.updatedAt,
          ),
        )
        .toList();

    final dbVacs = await (_db.select(
      _db.vaccinations,
    )..where((t) => t.userId.equals(userId))).get();
    _vaccinations = dbVacs
        .map(
          (v) => Vaccination(
            id: v.id,
            userId: v.userId,
            vaccineName: v.name,
            dates: [v.dateReceived],
            createdAt: v.createdAt,
            updatedAt: v.updatedAt,
          ),
        )
        .toList();

    final dbDiags = await (_db.select(
      _db.diagnoses,
    )..where((t) => t.userId.equals(userId))).get();
    _diagnoses = dbDiags
        .map(
          (d) => Diagnosis(
            id: d.id,
            userId: d.userId,
            name: d.name,
            status: DiagnosisStatus.active,
            date: d.diagnosedDate,
            duration: 'Unknown',
            createdAt: d.createdAt,
            updatedAt: d.updatedAt,
          ),
        )
        .toList();

    final dbLabs = await (_db.select(
      _db.labResults,
    )..where((t) => t.userId.equals(userId))).get();
    _labResults = dbLabs
        .map(
          (l) => LabResult(
            id: l.id,
            userId: l.userId,
            testName: l.testName,
            testDate: l.testDate,
            category: l.category,
            values: _parseLabValues(l.values),
            createdAt: l.createdAt,
            updatedAt: l.updatedAt,
          ),
        )
        .toList();
    _labResults.sort((left, right) => right.testDate.compareTo(left.testDate));
  }

  Future<void> _seedDemoData(String userId) async {
    final now = DateTime.now();
    final allergyTime = now.subtract(const Duration(hours: 6));
    final medicationTime = now.subtract(const Duration(days: 1));
    final vaccinationTime = now.subtract(const Duration(days: 2));
    if (_allergies.isEmpty) {
      await _db
          .into(_db.allergies)
          .insert(
            db.AllergiesCompanion.insert(
              id: '1',
              userId: userId,
              name: 'Penicillin',
              severity: AllergySeverity.severe.name,
              isCritical: true,
              reactionType: drift.Value('Anaphylaxis'),
              createdAt: allergyTime,
              updatedAt: allergyTime,
            ),
          );
      await _db
          .into(_db.allergies)
          .insert(
            db.AllergiesCompanion.insert(
              id: '2',
              userId: userId,
              name: 'Peanuts',
              severity: AllergySeverity.moderate.name,
              isCritical: false,
              reactionType: drift.Value('Rash'),
              createdAt: allergyTime,
              updatedAt: allergyTime,
            ),
          );
    }

    if (_medications.isEmpty) {
      await _db
          .into(_db.medications)
          .insert(
            db.MedicationsCompanion.insert(
              id: '1',
              userId: userId,
              name: 'Lisinopril',
              frequency: 'Once daily',
              dosage: drift.Value('10mg'),
              startDate: drift.Value(medicationTime),
              createdAt: medicationTime,
              updatedAt: medicationTime,
            ),
          );
      await _db
          .into(_db.medications)
          .insert(
            db.MedicationsCompanion.insert(
              id: '2',
              userId: userId,
              name: 'Metformin',
              frequency: 'Twice daily',
              dosage: drift.Value('500mg'),
              startDate: drift.Value(medicationTime),
              createdAt: medicationTime,
              updatedAt: medicationTime,
            ),
          );
    }

    if (_vaccinations.isEmpty) {
      await _db
          .into(_db.vaccinations)
          .insert(
            db.VaccinationsCompanion.insert(
              id: '1',
              userId: userId,
              name: 'COVID-19 Booster',
              dateReceived: vaccinationTime,
              createdAt: vaccinationTime,
              updatedAt: vaccinationTime,
            ),
          );
      await _db
          .into(_db.vaccinations)
          .insert(
            db.VaccinationsCompanion.insert(
              id: '2',
              userId: userId,
              name: 'Flu Shot',
              dateReceived: vaccinationTime,
              createdAt: vaccinationTime,
              updatedAt: vaccinationTime,
            ),
          );
    }
    if (_labResults.isEmpty) {
      List<Map<String, dynamic>> labSeeds = getLabResultsMockData();
      for (final seed in labSeeds) {
        final seededAt = now.subtract(Duration(days: seed['daysAgo'] as int));
        final rawValues = seed['values'];
        final values = rawValues is List
            ? rawValues
                  .map((entry) => Map<String, dynamic>.from(entry as Map))
                  .toList(growable: false)
            : <Map<String, dynamic>>[
                {
                  'name': seed['testName'],
                  'value': seed['value'],
                  'unit': seed['unit'],
                  'status': seed['status'],
                  if (seed['minRange'] != null) 'minRange': seed['minRange'],
                  if (seed['maxRange'] != null) 'maxRange': seed['maxRange'],
                },
              ];
        await _db
            .into(_db.labResults)
            .insert(
              db.LabResultsCompanion.insert(
                id: seed['id'] as String,
                userId: userId,
                testName: seed['testName'] as String,
                category: seed['category'] as String,
                testDate: seededAt,
                values: jsonEncode(values),
                createdAt: seededAt,
                updatedAt: seededAt,
              ),
            );
      }
    }
  }

  List<Map<String, dynamic>> getLabResultsMockData() {
    final labSeeds = <Map<String, dynamic>>[
      {
        'id': '1',
        'testName': 'Complete Blood Count',
        'category': 'Blood',
        'daysAgo': 2,
        'values': [
          {
            'name': 'Hemoglobin',
            'value': '14.1',
            'unit': 'g/dL',
            'minRange': '13.5',
            'maxRange': '17.5',
            'status': TestResultStatus.normal.name,
          },
        ],
        'value': '14.1',
        'unit': 'g/dL',
        'status': TestResultStatus.normal.name,
      },
      {
        'id': '2',
        'testName': 'Cholesterol Panel',
        'category': 'Blood',
        'daysAgo': 4,
        'values': [
          {
            'name': 'Total Cholesterol',
            'value': '215',
            'unit': 'mg/dL',
            'minRange': null,
            'maxRange': '200',
            'status': TestResultStatus.abnormal.name,
          },
          {
            'name': 'LDL',
            'value': '140',
            'unit': 'mg/dL',
            'minRange': null,
            'maxRange': '100',
            'status': TestResultStatus.abnormal.name,
          },
          {
            'name': 'HDL',
            'value': '45',
            'unit': 'mg/dL',
            'minRange': '40',
            'maxRange': null,
            'status': TestResultStatus.normal.name,
          },
        ],
        'value': '215',
        'unit': 'mg/dL',
        'status': TestResultStatus.abnormal.name,
      },
      {
        'id': '3',
        'testName': 'Thyroid Function',
        'category': 'Hormone',
        'daysAgo': 6,
        'values': [
          {
            'name': 'TSH',
            'value': '1.8',
            'unit': 'uIU/mL',
            'minRange': '0.4',
            'maxRange': '4.0',
            'status': TestResultStatus.normal.name,
          },
        ],
        'value': '1.8',
        'unit': 'uIU/mL',
        'status': TestResultStatus.normal.name,
      },
    ];
    return labSeeds;
  }

  List<LabTestValue> _parseLabValues(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (entry) => LabTestValue.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> updateBloodType(String newType) async {
    _bloodType = newType;
    notifyListeners();
    final user = await _currentUserProvider();
    if (user == null) return;
    final now = DateTime.now();
    final existing =
        await (_db.select(_db.bloodTypes)
              ..where((t) => t.userId.equals(user.email))
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      await _db
          .update(_db.bloodTypes)
          .replace(existing.copyWith(type: newType, updatedAt: now));
    } else {
      await _db
          .into(_db.bloodTypes)
          .insert(
            db.BloodTypesCompanion.insert(
              id: now.millisecondsSinceEpoch.toString(),
              userId: user.email,
              type: newType,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  Future<void> _loadLabResultTypes() async {
    final rawTypes = await _readSettingValue(_labResultTypesSettingsKey);
    if (rawTypes != null && rawTypes.trim().isNotEmpty) {
      _labResultTypes = _decodeLabResultTypes(rawTypes);
    }

    final defaultTypes = _defaultLabResultTypes();
    final defaultNames = defaultTypes
        .map((type) => type.name.trim().toLowerCase())
        .toSet();

    if (_labResultTypes.isEmpty) {
      _labResultTypes = defaultTypes;
      await _saveLabResultTypes();
      return;
    }

    final merged = <LabResultType>[
      ...defaultTypes,
      ..._labResultTypes.where(
        (type) => !defaultNames.contains(type.name.trim().toLowerCase()),
      ),
    ];

    if (!_labResultTypesEqual(merged, _labResultTypes)) {
      _labResultTypes = merged;
      await _saveLabResultTypes();
    }
  }

  bool _labResultTypesEqual(
    List<LabResultType> left,
    List<LabResultType> right,
  ) {
    return jsonEncode(left.map((type) => type.toJson()).toList()) ==
        jsonEncode(right.map((type) => type.toJson()).toList());
  }

  Future<void> _ensureLabResultTypesCoverResults() async {
    final resultTypeNames = _labResults
        .map((result) => result.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet();
    final known = _labResultTypes
        .map((type) => type.name.trim().toLowerCase())
        .toSet();

    var changed = false;
    for (final category in resultTypeNames) {
      if (known.contains(category.toLowerCase())) {
        continue;
      }

      _labResultTypes = [..._labResultTypes, LabResultType(name: category)];
      changed = true;
    }

    if (changed) {
      await _saveLabResultTypes();
    }
  }

  List<LabResultType> _decodeLabResultTypes(String rawTypes) {
    try {
      final decoded = jsonDecode(rawTypes);
      if (decoded is! List) {
        return <LabResultType>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (entry) => LabResultType.fromJson(Map<String, dynamic>.from(entry)),
          )
          .where((type) => type.name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return <LabResultType>[];
    }
  }

  List<LabResultType> _defaultLabResultTypes() {
    return const <LabResultType>[
      LabResultType(
        name: 'Complete Blood Count (CBC)',
        suggestedFields: [
          'Hemoglobin',
          'Hematocrit',
          'White Blood Cells',
          'Platelets',
        ],
        description: 'Checks your blood cells.',
      ),
      LabResultType(
        name: 'Metabolic Panels (BMP or CMP)',
        suggestedFields: ['Glucose', 'Sodium', 'Potassium', 'Creatinine'],
        description: 'Checks organ function and chemistry.',
      ),
      LabResultType(
        name: 'Lipid Panel',
        suggestedFields: ['Total Cholesterol', 'LDL', 'HDL', 'Triglycerides'],
        description: 'Checks your heart health and fats.',
      ),
      LabResultType(
        name: 'Thyroid Panel',
        suggestedFields: ['TSH', 'Free T4'],
        description: 'Checks your metabolism regulator.',
      ),
      LabResultType(
        name: 'Diabetes Monitoring',
        suggestedFields: ['Blood Glucose', 'Fasting Glucose'],
        description: 'Checks long-term sugar.',
      ),
      LabResultType(
        name: 'Hemoglobin A1c',
        suggestedFields: ['Hemoglobin A1c'],
        description: 'Your average blood sugar over the last 3 months.',
      ),
      LabResultType(
        name: 'Urinalysis',
        suggestedFields: ['Protein', 'Glucose', 'Ketones', 'Specific Gravity'],
        description: 'Checks waste management.',
      ),
      LabResultType(
        name: 'Nutrient Levels',
        suggestedFields: ['Vitamin D', 'Vitamin B12', 'Ferritin'],
        description: 'Checks for deficiencies.',
      ),
    ];
  }

  Set<String> _defaultLabResultTypeNames() {
    return _defaultLabResultTypes()
        .map((type) => type.name.trim().toLowerCase())
        .toSet();
  }

  bool isCustomLabResultType(String name) {
    return !_defaultLabResultTypeNames().contains(name.trim().toLowerCase());
  }

  bool canRemoveLabResultType(String name) {
    final normalizedName = name.trim().toLowerCase();
    if (normalizedName.isEmpty || !isCustomLabResultType(name)) {
      return false;
    }

    return !_labResults.any(
      (result) => result.category.trim().toLowerCase() == normalizedName,
    );
  }

  Future<bool> removeLabResultType(String name) async {
    if (!canRemoveLabResultType(name)) {
      return false;
    }

    final normalizedName = name.trim().toLowerCase();
    final beforeLength = _labResultTypes.length;
    _labResultTypes = _labResultTypes
        .where((type) => type.name.trim().toLowerCase() != normalizedName)
        .toList(growable: false);

    if (_labResultTypes.length == beforeLength) {
      return false;
    }

    await _saveLabResultTypes();
    notifyListeners();
    return true;
  }

  Future<String?> _readSettingValue(String key) async {
    final query = _db.select(_db.settings)..where((tbl) => tbl.key.equals(key));
    final setting = await query.getSingleOrNull();
    return setting?.value;
  }

  Future<void> _writeSettingValue(String key, String? value) async {
    await _db
        .into(_db.settings)
        .insert(
          db.SettingsCompanion(
            key: drift.Value(key),
            value: drift.Value(value),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> _saveLabResultTypes() async {
    await _writeSettingValue(
      _labResultTypesSettingsKey,
      jsonEncode(_labResultTypes.map((type) => type.toJson()).toList()),
    );
  }

  TestResultStatus _statusForLabValue(LabTestValue value) {
    final parsedValue = double.tryParse(value.value.replaceAll(',', '.'));
    final minRange = double.tryParse(
      value.minRange?.replaceAll(',', '.') ?? '',
    );
    final maxRange = double.tryParse(
      value.maxRange?.replaceAll(',', '.') ?? '',
    );

    if (parsedValue == null) {
      return value.status;
    }

    if (minRange == null && maxRange == null) {
      return value.status;
    }

    if (minRange != null && parsedValue < minRange) {
      return TestResultStatus.abnormal;
    }

    if (maxRange != null && parsedValue > maxRange) {
      return TestResultStatus.abnormal;
    }

    return TestResultStatus.normal;
  }

  Future<void> addLabResultType(LabResultType type) async {
    final normalizedName = type.name.trim();
    if (normalizedName.isEmpty) {
      return;
    }

    final existingIndex = _labResultTypes.indexWhere(
      (candidate) =>
          candidate.name.trim().toLowerCase() == normalizedName.toLowerCase(),
    );
    if (existingIndex >= 0) {
      final existing = _labResultTypes[existingIndex];
      final updated = existing.copyWith(
        name: normalizedName,
        suggestedFields: type.suggestedFields,
        description: type.description,
      );
      _labResultTypes[existingIndex] = updated;
    } else {
      _labResultTypes = [
        ..._labResultTypes,
        type.copyWith(name: normalizedName),
      ];
    }

    await _saveLabResultTypes();
    notifyListeners();
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  Future<void> addAllergy(Allergy allergy) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final now = DateTime.now();
    final reaction = _normalizeOptionalText(allergy.reaction);
    final id = allergy.id.trim().isEmpty
        ? now.millisecondsSinceEpoch.toString()
        : allergy.id;

    await _db
        .into(_db.allergies)
        .insert(
          db.AllergiesCompanion.insert(
            id: id,
            userId: user.email,
            name: allergy.substance.trim(),
            description: drift.Value(reaction),
            severity: allergy.severity.name,
            reactionType: drift.Value(reaction),
            isCritical: allergy.severity == AllergySeverity.severe,
            notes: drift.Value(_normalizeOptionalText(allergy.notes)),
            documentUrls: drift.Value(
              _normalizeOptionalText(allergy.documentAttachment),
            ),
            createdAt: allergy.createdAt,
            updatedAt: now,
          ),
          mode: drift.InsertMode.insertOrReplace,
        );

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> updateAllergy(Allergy allergy) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final existing = await (_db.select(
      _db.allergies,
    )..where((table) => table.id.equals(allergy.id))).getSingleOrNull();
    if (existing == null) {
      return;
    }

    final reaction = _normalizeOptionalText(allergy.reaction);
    await _db
        .update(_db.allergies)
        .replace(
          existing.copyWith(
            name: allergy.substance.trim(),
            description: drift.Value(reaction),
            severity: allergy.severity.name,
            reactionType: drift.Value(reaction),
            isCritical: allergy.severity == AllergySeverity.severe,
            notes: drift.Value(_normalizeOptionalText(allergy.notes)),
            documentUrls: drift.Value(
              _normalizeOptionalText(allergy.documentAttachment),
            ),
            updatedAt: DateTime.now(),
          ),
        );

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> deleteAllergy(String id) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    await (_db.delete(_db.allergies)..where(
          (table) => table.id.equals(id) & table.userId.equals(user.email),
        ))
        .go();

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> addMedication(Medication medication) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final now = DateTime.now();
    final id = medication.id.trim().isEmpty
        ? now.millisecondsSinceEpoch.toString()
        : medication.id;
    final dosage = _normalizeOptionalText(medication.dosage);

    await _db
        .into(_db.medications)
        .insert(
          db.MedicationsCompanion.insert(
            id: id,
            userId: user.email,
            name: medication.name.trim(),
            frequency: medication.frequency.trim().isEmpty
                ? 'Once daily'
                : medication.frequency.trim(),
            dosage: drift.Value(dosage),
            startDate: drift.Value(medication.startDate),
            endDate: drift.Value(medication.endDate),
            notes: drift.Value(_normalizeOptionalText(medication.notes)),
            documentUrls: drift.Value(
              _normalizeOptionalText(medication.documentAttachment),
            ),
            createdAt: medication.createdAt,
            updatedAt: now,
          ),
          mode: drift.InsertMode.insertOrReplace,
        );

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> updateMedication(Medication medication) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final existing = await (_db.select(
      _db.medications,
    )..where((table) => table.id.equals(medication.id))).getSingleOrNull();
    if (existing == null) {
      return;
    }

    await _db
        .update(_db.medications)
        .replace(
          existing.copyWith(
            name: medication.name.trim(),
            frequency: medication.frequency.trim().isEmpty
                ? existing.frequency
                : medication.frequency.trim(),
            dosage: drift.Value(_normalizeOptionalText(medication.dosage)),
            startDate: drift.Value(medication.startDate),
            endDate: drift.Value(medication.endDate),
            notes: drift.Value(_normalizeOptionalText(medication.notes)),
            documentUrls: drift.Value(
              _normalizeOptionalText(medication.documentAttachment),
            ),
            updatedAt: DateTime.now(),
          ),
        );

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> deleteMedication(String id) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    await (_db.delete(_db.medications)..where(
          (table) => table.id.equals(id) & table.userId.equals(user.email),
        ))
        .go();

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> addVaccination(Vaccination vaccination) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final now = DateTime.now();
    final id = vaccination.id.trim().isEmpty
        ? now.millisecondsSinceEpoch.toString()
        : vaccination.id;
    final receivedDate = vaccination.dates.isEmpty
        ? now
        : vaccination.dates.first;

    await _db
        .into(_db.vaccinations)
        .insert(
          db.VaccinationsCompanion.insert(
            id: id,
            userId: user.email,
            name: vaccination.vaccineName.trim(),
            dateReceived: receivedDate,
            documentUrls: drift.Value(
              _normalizeOptionalText(vaccination.documentAttachment),
            ),
            createdAt: vaccination.createdAt,
            updatedAt: now,
          ),
          mode: drift.InsertMode.insertOrReplace,
        );

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> updateVaccination(Vaccination vaccination) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final existing = await (_db.select(
      _db.vaccinations,
    )..where((table) => table.id.equals(vaccination.id))).getSingleOrNull();
    if (existing == null) {
      return;
    }

    final receivedDate = vaccination.dates.isEmpty
        ? existing.dateReceived
        : vaccination.dates.first;
    await _db
        .update(_db.vaccinations)
        .replace(
          existing.copyWith(
            name: vaccination.vaccineName.trim(),
            dateReceived: receivedDate,
            documentUrls: drift.Value(
              _normalizeOptionalText(vaccination.documentAttachment),
            ),
            updatedAt: DateTime.now(),
          ),
        );

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> deleteVaccination(String id) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    await (_db.delete(_db.vaccinations)..where(
          (table) => table.id.equals(id) & table.userId.equals(user.email),
        ))
        .go();

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> addDiagnosis(Diagnosis diagnosis) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final now = DateTime.now();
    final id = diagnosis.id.trim().isEmpty
        ? now.millisecondsSinceEpoch.toString()
        : diagnosis.id;
    final isResolved = diagnosis.status == DiagnosisStatus.resolved;

    await _db
        .into(_db.diagnoses)
        .insert(
          db.DiagnosesCompanion.insert(
            id: id,
            userId: user.email,
            name: diagnosis.name.trim(),
            status: isResolved ? 'resolved' : 'active',
            diagnosedDate: diagnosis.date,
            resolvedDate: drift.Value(isResolved ? diagnosis.date : null),
            description: drift.Value(
              _normalizeOptionalText(diagnosis.duration),
            ),
            notes: drift.Value(_normalizeOptionalText(diagnosis.notes)),
            documentUrls: drift.Value(
              _normalizeOptionalText(diagnosis.documentAttachment),
            ),
            createdAt: diagnosis.createdAt,
            updatedAt: now,
          ),
          mode: drift.InsertMode.insertOrReplace,
        );

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> updateDiagnosis(Diagnosis diagnosis) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final existing = await (_db.select(
      _db.diagnoses,
    )..where((table) => table.id.equals(diagnosis.id))).getSingleOrNull();
    if (existing == null) {
      return;
    }

    final isResolved = diagnosis.status == DiagnosisStatus.resolved;
    await _db
        .update(_db.diagnoses)
        .replace(
          existing.copyWith(
            name: diagnosis.name.trim(),
            status: isResolved ? 'resolved' : 'active',
            diagnosedDate: diagnosis.date,
            resolvedDate: drift.Value(isResolved ? diagnosis.date : null),
            description: drift.Value(
              _normalizeOptionalText(diagnosis.duration),
            ),
            notes: drift.Value(_normalizeOptionalText(diagnosis.notes)),
            documentUrls: drift.Value(
              _normalizeOptionalText(diagnosis.documentAttachment),
            ),
            updatedAt: DateTime.now(),
          ),
        );

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> deleteDiagnosis(String id) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    await (_db.delete(_db.diagnoses)..where(
          (table) => table.id.equals(id) & table.userId.equals(user.email),
        ))
        .go();

    await syncListsFromDb(user.email);
    notifyListeners();
  }

  Future<void> addLabResult(LabResult result) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final now = DateTime.now();
    final record = LabResult(
      id: result.id.trim().isEmpty
          ? now.millisecondsSinceEpoch.toString()
          : result.id,
      userId: user.email,
      testName: result.testName.trim(),
      category: result.category.trim(),
      testDate: result.testDate,
      values: result.values
          .map((value) => value.copyWith(status: _statusForLabValue(value)))
          .toList(growable: false),
      doctorInterpretation: result.doctorInterpretation,
      notes: result.notes,
      documentUrls: result.documentUrls,
      createdAt: result.createdAt,
      updatedAt: now,
    );

    await _db
        .into(_db.labResults)
        .insert(
          db.LabResultsCompanion.insert(
            id: record.id,
            userId: record.userId,
            testName: record.testName,
            category: record.category,
            testDate: record.testDate,
            values: jsonEncode(
              record.values.map((value) => value.toJson()).toList(),
            ),
            doctorInterpretation: drift.Value(record.doctorInterpretation),
            notes: drift.Value(record.notes),
            documentUrls: drift.Value(record.documentUrls),
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
          ),
        );

    await addLabResultType(
      LabResultType(
        name: record.category,
        suggestedFields: record.values
            .map((value) => value.name)
            .toList(growable: false),
      ),
    );
    await syncListsFromDb(user.email);
    await _ensureLabResultTypesCoverResults();
    notifyListeners();
  }

  Future<void> updateLabResult(LabResult result) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    final existing = await (_db.select(
      _db.labResults,
    )..where((table) => table.id.equals(result.id))).getSingleOrNull();
    if (existing == null) {
      return;
    }

    await _db
        .update(_db.labResults)
        .replace(
          existing.copyWith(
            testName: result.testName,
            category: result.category,
            testDate: result.testDate,
            values: jsonEncode(
              result.values.map((value) => value.toJson()).toList(),
            ),
            doctorInterpretation: drift.Value(result.doctorInterpretation),
            notes: drift.Value(result.notes),
            documentUrls: drift.Value(result.documentUrls),
            updatedAt: DateTime.now(),
          ),
        );

    await syncListsFromDb(user.email);
    await _ensureLabResultTypesCoverResults();
    notifyListeners();
  }

  Future<void> deleteLabResult(String id) async {
    final user = await _currentUserProvider();
    if (user == null) {
      return;
    }

    await (_db.delete(
      _db.labResults,
    )..where((table) => table.id.equals(id))).go();
    await syncListsFromDb(user.email);
    notifyListeners();
  }
}
