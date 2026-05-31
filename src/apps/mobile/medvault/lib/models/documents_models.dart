import 'dart:typed_data';

enum MedicalDocumentType { pdf, image, docx, xlsx, other }

enum MedicalDocumentCategory {
  labResults,
  medicalReport,
  medicationReport,
  vaccinations,
  other;

  static MedicalDocumentCategory fromValue(String? value) {
    return MedicalDocumentCategory.values.firstWhere(
      (item) => item.name == value,
      orElse: () => MedicalDocumentCategory.other,
    );
  }
}

class MedicalDocumentFile {
  final String id;
  final String documentId;
  final String userId;
  final MedicalDocumentType type;
  final String fileName;
  final String? fileExtension;
  final String? mimeType;
  final int fileSizeBytes;
  final Uint8List encryptedPayload;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalDocumentFile({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.type,
    required this.fileName,
    required this.fileExtension,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.encryptedPayload,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get supportsExtraction {
    return type == MedicalDocumentType.pdf || type == MedicalDocumentType.image;
  }

  MedicalDocumentFile copyWith({
    String? id,
    String? documentId,
    String? userId,
    MedicalDocumentType? type,
    String? fileName,
    String? fileExtension,
    bool clearFileExtension = false,
    String? mimeType,
    bool clearMimeType = false,
    int? fileSizeBytes,
    Uint8List? encryptedPayload,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalDocumentFile(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      fileExtension: clearFileExtension
          ? null
          : (fileExtension ?? this.fileExtension),
      mimeType: clearMimeType ? null : (mimeType ?? this.mimeType),
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MedicalDocument {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? documentDate;
  final MedicalDocumentCategory category;
  final List<String> tags;
  final List<MedicalDocumentFile> files;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalDocument({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.documentDate,
    required this.category,
    required this.tags,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
  });

  MedicalDocumentFile? get primaryFile {
    if (files.isEmpty) {
      return null;
    }

    return files.first;
  }

  MedicalDocumentType get type {
    return primaryFile?.type ?? MedicalDocumentType.other;
  }

  String get fileName {
    return primaryFile?.fileName ?? '';
  }

  String? get fileExtension {
    return primaryFile?.fileExtension;
  }

  String? get mimeType {
    return primaryFile?.mimeType;
  }

  int get fileSizeBytes {
    return files.fold<int>(0, (total, file) => total + file.fileSizeBytes);
  }

  Uint8List get encryptedPayload {
    return primaryFile?.encryptedPayload ?? Uint8List(0);
  }

  bool get hasMultipleFiles => files.length > 1;

  MedicalDocument copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? documentDate,
    bool clearDocumentDate = false,
    MedicalDocumentCategory? category,
    List<String>? tags,
    List<MedicalDocumentFile>? files,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      documentDate: clearDocumentDate
          ? null
          : (documentDate ?? this.documentDate),
      category: category ?? this.category,
      tags: tags ?? this.tags,
      files: files ?? this.files,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DocumentUploadDraft {
  final String fileName;
  final String? fileExtension;
  final String? mimeType;
  final MedicalDocumentType type;
  final Uint8List payload;

  const DocumentUploadDraft({
    required this.fileName,
    required this.fileExtension,
    required this.mimeType,
    required this.type,
    required this.payload,
  });

  int get fileSizeBytes => payload.length;

  bool get supportsExtraction {
    return type == MedicalDocumentType.pdf || type == MedicalDocumentType.image;
  }
}

class DocumentExtractionResult {
  final bool isMedical;
  final String documentType;
  final DateTime? date;
  final String issuerName;
  final List<String> tags;
  final MedicalExtractionMetadata metadata;
  final String summary;
  final double confidence;
  final bool requiresUserConfirmation;

  const DocumentExtractionResult({
    required this.isMedical,
    required this.documentType,
    required this.date,
    required this.issuerName,
    this.tags = const [],
    required this.metadata,
    required this.summary,
    required this.confidence,
    required this.requiresUserConfirmation,
  });

  factory DocumentExtractionResult.fromJson(Map<String, dynamic> json) {
    return DocumentExtractionResult(
      isMedical: json['isMedical'] == true,
      documentType: (json['documentType'] as String? ?? '').trim(),
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      issuerName: (json['issuerName'] as String? ?? '').trim(),
      tags: _parseTags(json['tags']),
      metadata: MedicalExtractionMetadata.fromJson(
        Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      ),
      summary: (json['summary'] as String? ?? '').trim(),
      confidence: _parseConfidence(json['confidence']),
      requiresUserConfirmation: json['requiresUserConfirmation'] != false,
    );
  }

  String get suggestedTitle {
    final parts = <String>[];
    if (documentType.trim().isNotEmpty) {
      parts.add(documentType.trim());
    }
    if (issuerName.trim().isNotEmpty) {
      parts.add(issuerName.trim());
    }
    if (date != null) {
      parts.add(
        '${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
      );
    }
    if (parts.isEmpty) {
      return '';
    }

    return parts.join(' - ');
  }

  static double _parseConfidence(Object? raw) {
    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      return 0;
    }
    if (parsed < 0) {
      return 0;
    }
    if (parsed > 1) {
      return 1;
    }
    return parsed;
  }

  static List<String> _parseTags(Object? raw) {
    if (raw is! List) {
      return const [];
    }

    final normalized = <String>[];
    final seen = <String>{};
    for (final value in raw) {
      final tag = value.toString().trim();
      if (tag.isEmpty) {
        continue;
      }

      final key = tag.toLowerCase();
      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      normalized.add(tag);
    }

    return normalized;
  }
}

class MedicalExtractionMetadata {
  final List<MedicationExtractionInfo> medications;
  final List<LabResultExtractionInfo> labResults;
  final List<AllergyExtractionInfo> allergies;
  final List<DiagnosisExtractionInfo> diagnoses;
  final List<VaccinationExtractionInfo> vaccinations;

  const MedicalExtractionMetadata({
    required this.medications,
    required this.labResults,
    required this.allergies,
    required this.diagnoses,
    required this.vaccinations,
  });

  factory MedicalExtractionMetadata.fromJson(Map<String, dynamic> json) {
    return MedicalExtractionMetadata(
      medications: _mapList(
        json['medications'],
        (item) => MedicationExtractionInfo.fromJson(item),
      ),
      labResults: _mapList(
        json['labResults'],
        (item) => LabResultExtractionInfo.fromJson(item),
      ),
      allergies: _mapList(
        json['allergies'],
        (item) => AllergyExtractionInfo.fromJson(item),
      ),
      diagnoses: _mapList(
        json['diagnoses'],
        (item) => DiagnosisExtractionInfo.fromJson(item),
      ),
      vaccinations: _mapList(
        json['vaccinations'],
        (item) => VaccinationExtractionInfo.fromJson(item),
      ),
    );
  }

  static List<T> _mapList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

class MedicationExtractionInfo {
  final String name;
  final String dosage;
  final String frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String notes;

  const MedicationExtractionInfo({
    required this.name,
    required this.dosage,
    this.frequency = '',
    this.startDate,
    this.endDate,
    this.notes = '',
  });

  factory MedicationExtractionInfo.fromJson(Map<String, dynamic> json) {
    return MedicationExtractionInfo(
      name: (json['name'] as String? ?? '').trim(),
      dosage: (json['dosage'] as String? ?? '').trim(),
      frequency: (json['frequency'] as String? ?? '').trim(),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      notes: (json['notes'] as String? ?? '').trim(),
    );
  }
}

class LabResultValueExtractionInfo {
  final String name;
  final String value;
  final String unit;
  final String minRange;
  final String maxRange;

  const LabResultValueExtractionInfo({
    required this.name,
    required this.value,
    required this.unit,
    required this.minRange,
    required this.maxRange,
  });

  factory LabResultValueExtractionInfo.fromJson(Map<String, dynamic> json) {
    return LabResultValueExtractionInfo(
      name: (json['name'] as String? ?? '').trim(),
      value: (json['value'] as String? ?? '').trim(),
      unit: (json['unit'] as String? ?? '').trim(),
      minRange: (json['minRange'] as String? ?? '').trim(),
      maxRange: (json['maxRange'] as String? ?? '').trim(),
    );
  }
}

class LabResultExtractionInfo {
  final String testName;
  final String value;
  final String unit;
  final String minRange;
  final String maxRange;
  final String notes;
  final DateTime? testDate;
  final String category;
  final List<LabResultValueExtractionInfo> testValues;

  const LabResultExtractionInfo({
    required this.testName,
    required this.value,
    required this.unit,
    required this.minRange,
    required this.maxRange,
    this.notes = '',
    this.testDate,
    this.category = '',
    this.testValues = const [],
  });

  List<LabResultValueExtractionInfo> get normalizedValues {
    if (testValues.isNotEmpty) {
      return testValues;
    }

    if (value.isEmpty) {
      return const [];
    }

    return [
      LabResultValueExtractionInfo(
        name: testName,
        value: value,
        unit: unit,
        minRange: minRange,
        maxRange: maxRange,
      ),
    ];
  }

  factory LabResultExtractionInfo.fromJson(Map<String, dynamic> json) {
    var minRange = (json['minRange'] as String? ?? '').trim();
    var maxRange = (json['maxRange'] as String? ?? '').trim();

    if (minRange.isEmpty && maxRange.isEmpty) {
      final referenceRange = (json['referenceRange'] as String? ?? '').trim();
      if (referenceRange.contains('-')) {
        final parts = referenceRange.split('-');
        if (parts.length >= 2) {
          minRange = parts.first.trim();
          maxRange = parts.last.trim();
        }
      } else if (referenceRange.toLowerCase().contains(' to ')) {
        final parts = referenceRange.split(RegExp(r'\s+to\s+'));
        if (parts.length >= 2) {
          minRange = parts.first.trim();
          maxRange = parts.last.trim();
        }
      }
    }

    return LabResultExtractionInfo(
      testName: (json['testName'] as String? ?? '').trim(),
      value: (json['value'] as String? ?? '').trim(),
      unit: (json['unit'] as String? ?? '').trim(),
      minRange: minRange,
      maxRange: maxRange,
      notes: (json['notes'] as String? ?? '').trim(),
      testDate: DateTime.tryParse(json['testDate']?.toString() ?? ''),
      category: (json['category'] as String? ?? '').trim(),
      testValues: _parseValues(json['testValues']),
    );
  }

  static List<LabResultValueExtractionInfo> _parseValues(Object? raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map(
          (entry) => LabResultValueExtractionInfo.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);
  }
}

class AllergyExtractionInfo {
  final String allergen;
  final String reaction;
  final String severity;
  final String notes;

  const AllergyExtractionInfo({
    required this.allergen,
    required this.reaction,
    this.severity = '',
    this.notes = '',
  });

  factory AllergyExtractionInfo.fromJson(Map<String, dynamic> json) {
    return AllergyExtractionInfo(
      allergen: (json['allergen'] as String? ?? '').trim(),
      reaction: (json['reaction'] as String? ?? '').trim(),
      severity: (json['severity'] as String? ?? '').trim(),
      notes: (json['notes'] as String? ?? '').trim(),
    );
  }
}

class DiagnosisExtractionInfo {
  final String name;
  final String code;
  final String notes;
  final DateTime? diagnosisDate;
  final String duration;

  const DiagnosisExtractionInfo({
    required this.name,
    required this.code,
    this.notes = '',
    this.diagnosisDate,
    this.duration = '',
  });

  factory DiagnosisExtractionInfo.fromJson(Map<String, dynamic> json) {
    return DiagnosisExtractionInfo(
      name: (json['name'] as String? ?? '').trim(),
      code: (json['code'] as String? ?? '').trim(),
      notes: (json['notes'] as String? ?? '').trim(),
      diagnosisDate: DateTime.tryParse(json['diagnosisDate']?.toString() ?? ''),
      duration: (json['duration'] as String? ?? '').trim(),
    );
  }
}

class VaccinationExtractionInfo {
  final String name;
  final DateTime? date;
  final List<DateTime> dates;

  const VaccinationExtractionInfo({
    required this.name,
    required this.date,
    this.dates = const [],
  });

  factory VaccinationExtractionInfo.fromJson(Map<String, dynamic> json) {
    final dates = _parseDates(json['dates']);
    return VaccinationExtractionInfo(
      name: (json['vaccineName'] as String? ?? json['name'] as String? ?? '')
          .trim(),
      date: dates.isNotEmpty
          ? dates.first
          : DateTime.tryParse(json['date']?.toString() ?? ''),
      dates: dates,
    );
  }

  static List<DateTime> _parseDates(Object? raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .map((value) => DateTime.tryParse(value.toString()))
        .whereType<DateTime>()
        .toList(growable: false);
  }
}
