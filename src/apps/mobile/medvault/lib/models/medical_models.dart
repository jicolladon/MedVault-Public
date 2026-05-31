library;

T _enumValue<T extends Enum>(Iterable<T> values, String? value, T fallback) {
  return values.firstWhere(
    (candidate) => candidate.name == value,
    orElse: () => fallback,
  );
}

DateTime _parseDate(dynamic value, DateTime fallback) {
  if (value == null) {
    return fallback;
  }

  return DateTime.parse(value.toString());
}

List<DateTime> _parseDateList(dynamic value) {
  if (value is List) {
    return value
        .map((date) => DateTime.parse(date.toString()))
        .toList(growable: false);
  }

  if (value == null) {
    return const <DateTime>[];
  }

  return <DateTime>[DateTime.parse(value.toString())];
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

String? _stringFromLegacyJson(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _optionalString(json[key]);
    if (value != null) {
      return value;
    }
  }

  return null;
}

DateTime _firstDateFromJson(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) {
      return DateTime.parse(value.toString());
    }
  }

  return DateTime.now();
}

String _legacyAllergySeverityToName(String? value) {
  switch (value) {
    case 'low':
      return AllergySeverity.mild.name;
    case 'medium':
      return AllergySeverity.moderate.name;
    case 'high':
    case 'critical':
      return AllergySeverity.severe.name;
    default:
      return value ?? AllergySeverity.moderate.name;
  }
}

AllergySeverity _parseAllergySeverity(Map<String, dynamic> json) {
  return _enumValue(
    AllergySeverity.values,
    _legacyAllergySeverityToName(_optionalString(json['severity'])),
    AllergySeverity.moderate,
  );
}

AllergyStatus _parseAllergyStatus(Map<String, dynamic> json) {
  final status = _optionalString(json['status']);
  if (status == 'resolved') {
    return AllergyStatus.resolved;
  }

  return AllergyStatus.active;
}

MedicationStatus _parseMedicationStatus(Map<String, dynamic> json) {
  return _enumValue(
    MedicationStatus.values,
    _optionalString(json['status']),
    MedicationStatus.active,
  );
}

DiagnosisStatus _parseDiagnosisStatus(Map<String, dynamic> json) {
  final status = _optionalString(json['status']);
  if (status == 'resolved') {
    return DiagnosisStatus.resolved;
  }

  return DiagnosisStatus.active;
}

List<String> _dateListToJson(List<DateTime> dates) {
  return dates.map((date) => date.toIso8601String()).toList(growable: false);
}


enum AllergySeverity { mild, moderate, severe }

enum AllergyStatus { active, resolved }

enum MedicationStatus { active, completed, suspended }

enum DiagnosisStatus { active, resolved }

enum TestResultStatus { normal, abnormal, pending }

enum BloodGroup {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  abPositive('AB+'),
  abNegative('AB-'),
  oPositive('O+'),
  oNegative('O-'),
  unknown('Unknown');

  final String value;
  const BloodGroup(this.value);

  static List<String> get valuesList => values.map((e) => e.value).toList();
}


class BloodType {
  final String id;
  final String userId;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  BloodType({
    required this.id,
    required this.userId,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BloodType.fromJson(Map<String, dynamic> json) {
    return BloodType(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}


class Allergy {
  final String id;
  final String userId;
  final String substance;
  final String reaction;
  final AllergySeverity severity;
  final AllergyStatus status;
  final String? notes;
  final String? documentAttachment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Allergy({
    required this.id,
    required this.userId,
    required this.substance,
    required this.reaction,
    this.severity = AllergySeverity.moderate,
    this.status = AllergyStatus.active,
    this.notes,
    this.documentAttachment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      id: json['id'],
      userId: json['userId'],
      substance: _stringFromLegacyJson(json, ['substance', 'name']) ?? '',
      reaction: _stringFromLegacyJson(json, ['reaction', 'description']) ?? '',
      severity: _parseAllergySeverity(json),
      status: _parseAllergyStatus(json),
      notes: _optionalString(json['notes']),
      documentAttachment: _stringFromLegacyJson(json, [
        'documentAttachment',
        'documentUrls',
      ]),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'substance': substance,
    'reaction': reaction,
    'severity': severity.name,
    'status': status.name,
    'notes': notes,
    'documentAttachment': documentAttachment,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}


class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final MedicationStatus status;
  final String? documentAttachment;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.status = MedicationStatus.active,
    this.documentAttachment,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      userId: json['userId'],
      name: _stringFromLegacyJson(json, ['name', 'medicationName']) ?? '',
      dosage: _optionalString(json['dosage']) ?? '',
      frequency: _stringFromLegacyJson(json, ['frequency']) ?? 'Once daily',
      startDate: _parseDate(json['startDate'], DateTime.now()),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: _parseMedicationStatus(json),
      documentAttachment: _stringFromLegacyJson(json, [
        'documentAttachment',
        'documentUrls',
      ]),
      notes: _optionalString(json['notes']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'status': status.name,
    'documentAttachment': documentAttachment,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}


class Vaccination {
  final String id;
  final String userId;
  final String vaccineName;
  final List<DateTime> dates;
  final String? documentAttachment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vaccination({
    required this.id,
    required this.userId,
    required this.vaccineName,
    required this.dates,
    this.documentAttachment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    final parsedDates = _parseDateList(json['dates']);
    return Vaccination(
      id: json['id'],
      userId: json['userId'],
      vaccineName: _stringFromLegacyJson(json, ['vaccineName', 'name']) ?? '',
      dates: parsedDates.isNotEmpty
          ? parsedDates
          : <DateTime>[
              _firstDateFromJson(json, [
                'date',
                'dateReceived',
                'administeredDate',
              ]),
            ],
      documentAttachment: _stringFromLegacyJson(json, [
        'documentAttachment',
        'documentUrls',
      ]),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'vaccineName': vaccineName,
    'dates': _dateListToJson(dates),
    'documentAttachment': documentAttachment,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}


class Diagnosis {
  final String id;
  final String userId;
  final String name;
  final DiagnosisStatus status;
  final DateTime date;
  final String? duration;
  final String? notes;
  final String? documentAttachment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Diagnosis({
    required this.id,
    required this.userId,
    required this.name,
    this.status = DiagnosisStatus.active,
    required this.date,
    this.duration,
    this.notes,
    this.documentAttachment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id'],
      userId: json['userId'],
      name: _stringFromLegacyJson(json, ['name', 'conditionName']) ?? '',
      status: _parseDiagnosisStatus(json),
      date: _firstDateFromJson(json, ['date', 'diagnosedDate']),
      duration: _optionalString(json['duration']),
      notes:
          _optionalString(json['notes']) ??
          _optionalString(json['description']),
      documentAttachment: _stringFromLegacyJson(json, [
        'documentAttachment',
        'documentUrls',
      ]),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'status': status.name,
    'date': date.toIso8601String(),
    'duration': duration,
    'notes': notes,
    'documentAttachment': documentAttachment,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}


class LabTestValue {
  final String name;
  final String value;
  final String unit;
  final String? minRange;
  final String? maxRange;
  final TestResultStatus status;

  LabTestValue({
    required this.name,
    required this.value,
    required this.unit,
    this.minRange,
    this.maxRange,
    required this.status,
  });

  factory LabTestValue.fromJson(Map<String, dynamic> json) {
    return LabTestValue(
      name: json['name'],
      value: json['value'],
      unit: json['unit'],
      minRange: json['minRange'],
      maxRange: json['maxRange'],
      status: TestResultStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TestResultStatus.pending,
      ),
    );
  }

  LabTestValue copyWith({
    String? name,
    String? value,
    String? unit,
    String? minRange,
    String? maxRange,
    TestResultStatus? status,
  }) {
    return LabTestValue(
      name: name ?? this.name,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      minRange: minRange ?? this.minRange,
      maxRange: maxRange ?? this.maxRange,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'unit': unit,
    'minRange': minRange,
    'maxRange': maxRange,
    'status': status.name,
  };
}

class LabResultType {
  final String name;
  final List<String> suggestedFields;
  final String? description;

  const LabResultType({
    required this.name,
    this.suggestedFields = const [],
    this.description,
  });

  factory LabResultType.fromJson(Map<String, dynamic> json) {
    final rawFields = json['suggestedFields'];
    final parsedFields = rawFields is List
        ? rawFields
              .whereType<Object>()
              .map((field) => field.toString().trim())
              .where((field) => field.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return LabResultType(
      name: json['name']?.toString() ?? '',
      suggestedFields: parsedFields,
      description: json['description']?.toString(),
    );
  }

  LabResultType copyWith({
    String? name,
    List<String>? suggestedFields,
    String? description,
  }) {
    return LabResultType(
      name: name ?? this.name,
      suggestedFields: suggestedFields ?? this.suggestedFields,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'suggestedFields': suggestedFields,
    'description': description,
  };
}

class LabResult {
  final String id;
  final String userId;
  final String testName;
  final String category;
  final DateTime testDate;
  final List<LabTestValue> values;
  final String? doctorInterpretation;
  final String? notes;
  final String? documentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  LabResult({
    required this.id,
    required this.userId,
    required this.testName,
    required this.category,
    required this.testDate,
    required this.values,
    this.doctorInterpretation,
    this.notes,
    this.documentUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LabResult.fromJson(Map<String, dynamic> json) {
    return LabResult(
      id: json['id'],
      userId: json['userId'],
      testName: json['testName'],
      category: json['category'],
      testDate: DateTime.parse(json['testDate']),
      values: (json['values'] as List<dynamic>)
          .map((v) => LabTestValue.fromJson(v as Map<String, dynamic>))
          .toList(),
      doctorInterpretation: json['doctorInterpretation'],
      notes: json['notes'],
      documentUrls: json['documentUrls'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'testName': testName,
    'category': category,
    'testDate': testDate.toIso8601String(),
    'values': values.map((v) => v.toJson()).toList(),
    'doctorInterpretation': doctorInterpretation,
    'notes': notes,
    'documentUrls': documentUrls,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
