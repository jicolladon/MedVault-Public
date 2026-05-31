import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/documents_models.dart';
import 'api/config_api.dart';
import 'api/documents_api.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'database.dart' as db;

typedef DocumentsCurrentUserProvider = Future<AuthUser?> Function();

class DocumentExtractionUnavailableInDemoException implements Exception {
  const DocumentExtractionUnavailableInDemoException();
}

class DocumentExtractionDisabledBySettingsException implements Exception {
  const DocumentExtractionDisabledBySettingsException();
}

class DocumentExtractionUnavailableOfflineException implements Exception {
  const DocumentExtractionUnavailableOfflineException();
}

class DocumentFileLimitExceededException implements Exception {
  const DocumentFileLimitExceededException({
    required this.maxFiles,
    required this.currentFileCount,
    required this.requestedAdditionalFiles,
  });

  final int maxFiles;
  final int currentFileCount;
  final int requestedAdditionalFiles;

  int get requestedTotalFileCount =>
      currentFileCount + requestedAdditionalFiles;
}

class DocumentsService extends ChangeNotifier {
  static const int maxFilesPerDocument = 10;
  static const int defaultMaxFilesPerDocument = 10;

  DocumentsService({
    required DocumentsCurrentUserProvider currentUserProvider,
    required bool demoMode,
    DocumentsApiClient? apiClient,
    ConfigApi? configApi,
    db.AppDatabase? database,
    ConnectivityService? connectivityService,
  }) : _currentUserProvider = currentUserProvider,
       _demoMode = demoMode,
       _apiClient = apiClient ?? const PendingDocumentsApiClient(),
       _configApi = configApi,
       _db = database ?? db.AppDatabase(),
       _connectivityService = connectivityService;

  final DocumentsCurrentUserProvider _currentUserProvider;
  final bool _demoMode;
  final DocumentsApiClient _apiClient;
  final ConfigApi? _configApi;
  final db.AppDatabase _db;
  final ConnectivityService? _connectivityService;

  String? _currentUserId;
  bool _isLoading = false;
  bool _documentExtractDataEnabled = true;
  int _maxFilesPerDocument = defaultMaxFilesPerDocument;
  List<MedicalDocument> _documents = const [];

  bool get isLoading => _isLoading;

  bool get documentExtractDataEnabled => _documentExtractDataEnabled;
  bool get canUseRemoteFeatures =>
      _demoMode || (_connectivityService?.isOnline ?? true);

  int get currentMaxFilesPerDocument => _maxFilesPerDocument;

  List<MedicalDocument> get documents {
    final copy = List<MedicalDocument>.from(_documents);
    copy.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return copy;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final userId = await _resolveCurrentUserId();
    if (userId == null) {
      _currentUserId = null;
      _documents = const [];
      _documentExtractDataEnabled = true;
      _maxFilesPerDocument = defaultMaxFilesPerDocument;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final shouldReload = _currentUserId != userId;
    _currentUserId = userId;

    if (shouldReload) {
      await _loadForUser(userId);
    }

    if (_demoMode) {
      _documentExtractDataEnabled = true;
      _maxFilesPerDocument = defaultMaxFilesPerDocument;
    } else if (_connectivityService?.isOffline == true) {
      _documentExtractDataEnabled = true;
      _maxFilesPerDocument = defaultMaxFilesPerDocument;
    } else {
      await _syncDocumentSettingsFromRemote();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _syncDocumentSettingsFromRemote() async {
    final configApi = _configApi;
    if (configApi == null) {
      _documentExtractDataEnabled = true;
      _maxFilesPerDocument = defaultMaxFilesPerDocument;
      return;
    }

    try {
      final remote = await configApi.getDocumentFeatureSettings();
      _documentExtractDataEnabled = remote?.documentExtractDataEnabled ?? true;
      _maxFilesPerDocument =
          remote?.maxFilesPerDocument ?? defaultMaxFilesPerDocument;
    } on Exception catch (error, stackTrace) {
      debugPrint('Failed to load document settings: $error\n$stackTrace');
      _documentExtractDataEnabled = true;
      _maxFilesPerDocument = defaultMaxFilesPerDocument;
    }
  }

  DocumentUploadDraft createDraft({
    required Uint8List payload,
    required String fileName,
    String? mimeType,
  }) {
    final extension = _normalizeExtension(fileName);
    final resolvedType = _resolveType(fileName: fileName, mimeType: mimeType);

    return DocumentUploadDraft(
      fileName: fileName,
      fileExtension: extension,
      mimeType: mimeType,
      type: resolvedType,
      payload: payload,
    );
  }

  Future<MedicalDocument> createDocument({
    DocumentUploadDraft? draft,
    List<DocumentUploadDraft> drafts = const [],
    required String title,
    String? description,
    DateTime? documentDate,
    MedicalDocumentCategory category = MedicalDocumentCategory.other,
    List<String> tags = const [],
  }) async {
    final normalizedDrafts = _resolveDraftInputs(
      singleDraft: draft,
      drafts: drafts,
    );
    _ensureFileLimit(
      currentFileCount: 0,
      requestedAdditionalFiles: normalizedDrafts.length,
    );
    final userId = await _requireCurrentUserId();
    final now = DateTime.now();

    final files = normalizedDrafts
        .asMap()
        .entries
        .map(
          (entry) => MedicalDocumentFile(
            id: _newId('docfile'),
            documentId: '',
            userId: userId,
            type: entry.value.type,
            fileName: entry.value.fileName,
            fileExtension: entry.value.fileExtension,
            mimeType: entry.value.mimeType,
            fileSizeBytes: entry.value.fileSizeBytes,
            encryptedPayload: entry.value.payload,
            sortOrder: entry.key,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList(growable: false);

    final documentId = _newId('doc');
    final boundFiles = files
        .map((file) => file.copyWith(documentId: documentId))
        .toList(growable: false);

    final firstDraft = normalizedDrafts.first;

    final document = MedicalDocument(
      id: documentId,
      userId: userId,
      title: _normalizeTitle(title, fallbackFileName: firstDraft.fileName),
      description: _normalizeOptionalText(description),
      documentDate: documentDate,
      category: category,
      tags: _normalizeTags(tags),
      files: boundFiles,
      createdAt: now,
      updatedAt: now,
    );

    await _upsertDocument(document);
    await _loadForUser(userId);
    notifyListeners();
    return document;
  }

  Future<MedicalDocument?> findDocumentById(String documentId) async {
    final userId = _currentUserId;
    if (userId == null) {
      return null;
    }

    final row =
        await (_db.select(_db.medicalDocuments)..where(
              (tbl) => tbl.userId.equals(userId) & tbl.id.equals(documentId),
            ))
            .getSingleOrNull();

    if (row == null) {
      return null;
    }

    final fileRows =
        await (_db.select(_db.medicalDocumentFiles)..where(
              (tbl) =>
                  tbl.userId.equals(userId) & tbl.documentId.equals(documentId),
            ))
            .get();

    return _mapRow(row, fileRows);
  }

  Future<void> updateDocumentDetails({
    required String documentId,
    required String title,
    String? description,
    DateTime? documentDate,
    required MedicalDocumentCategory category,
    required List<String> tags,
  }) async {
    final userId = await _requireCurrentUserId();
    final existing = await findDocumentById(documentId);
    if (existing == null) {
      return;
    }

    final updated = existing.copyWith(
      title: _normalizeTitle(
        title,
        fallbackFileName: existing.primaryFile?.fileName ?? 'document',
      ),
      description: _normalizeOptionalText(description),
      clearDescription: _normalizeOptionalText(description) == null,
      documentDate: documentDate,
      clearDocumentDate: documentDate == null,
      category: category,
      tags: _normalizeTags(tags),
      updatedAt: DateTime.now(),
    );

    await _upsertDocument(updated);
    await _loadForUser(userId);
    notifyListeners();
  }

  Future<MedicalDocument?> addFilesToDocument({
    required String documentId,
    required List<DocumentUploadDraft> drafts,
  }) async {
    final userId = await _requireCurrentUserId();
    final normalizedDrafts = _resolveDraftInputs(drafts: drafts);
    final existing = await findDocumentById(documentId);
    if (existing == null) {
      return null;
    }

    _ensureFileLimit(
      currentFileCount: existing.files.length,
      requestedAdditionalFiles: normalizedDrafts.length,
    );

    final now = DateTime.now();
    final startOrder = existing.files.length;
    final appendedFiles = normalizedDrafts
        .asMap()
        .entries
        .map(
          (entry) => MedicalDocumentFile(
            id: _newId('docfile'),
            documentId: existing.id,
            userId: existing.userId,
            type: entry.value.type,
            fileName: entry.value.fileName,
            fileExtension: entry.value.fileExtension,
            mimeType: entry.value.mimeType,
            fileSizeBytes: entry.value.fileSizeBytes,
            encryptedPayload: entry.value.payload,
            sortOrder: startOrder + entry.key,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList(growable: false);

    final updated = existing.copyWith(
      files: [...existing.files, ...appendedFiles],
      updatedAt: now,
    );

    await _upsertDocument(updated);
    await _loadForUser(userId);
    notifyListeners();
    return findDocumentById(documentId);
  }

  Future<MedicalDocument?> removeFileFromDocument({
    required String documentId,
    required String fileId,
  }) async {
    final userId = await _requireCurrentUserId();
    final existing = await findDocumentById(documentId);
    if (existing == null) {
      return null;
    }

    final remaining = existing.files
        .where((file) => file.id != fileId)
        .toList(growable: false);
    if (remaining.length == existing.files.length) {
      return existing;
    }

    if (remaining.isEmpty) {
      throw StateError('A document must include at least one file.');
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      files: _reindexFiles(remaining, updatedAt: now),
      updatedAt: now,
    );

    await _upsertDocument(updated);
    await _loadForUser(userId);
    notifyListeners();
    return findDocumentById(documentId);
  }

  Future<void> deleteDocument(String documentId) async {
    final userId = await _requireCurrentUserId();

    await (_db.delete(_db.medicalDocuments)..where(
          (tbl) => tbl.userId.equals(userId) & tbl.id.equals(documentId),
        ))
        .go();

    await _loadForUser(userId);
    notifyListeners();
  }

  Future<DocumentExtractionResult?> extractDocumentData(
    String documentId, {
    String preferredLanguage = 'en',
  }) async {
    if (_demoMode) {
      throw const DocumentExtractionUnavailableInDemoException();
    }

    if (_connectivityService?.isOffline == true) {
      throw const DocumentExtractionUnavailableOfflineException();
    }

    if (!_documentExtractDataEnabled) {
      throw const DocumentExtractionDisabledBySettingsException();
    }

    final doc = await findDocumentById(documentId);
    if (doc == null) {
      return null;
    }

    if (doc.files.isEmpty) {
      return null;
    }

    return _apiClient.extractDocumentData(
      documentId: doc.id,
      files: doc.files
          .map(
            (file) => DocumentsApiFilePayload(
              fileName: file.fileName,
              mimeType: file.mimeType,
              payload: file.encryptedPayload,
            ),
          )
          .toList(growable: false),
      preferredLanguage: preferredLanguage,
    );
  }

  Future<DocumentExtractionResult?> extractDocumentDataFromDrafts(
    List<DocumentUploadDraft> drafts, {
    String preferredLanguage = 'en',
  }) async {
    if (_demoMode) {
      throw const DocumentExtractionUnavailableInDemoException();
    }

    if (_connectivityService?.isOffline == true) {
      throw const DocumentExtractionUnavailableOfflineException();
    }

    if (!_documentExtractDataEnabled) {
      throw const DocumentExtractionDisabledBySettingsException();
    }

    final normalizedDrafts = _resolveDraftInputs(drafts: drafts);
    if (normalizedDrafts.isEmpty) {
      return null;
    }

    return _apiClient.extractDocumentData(
      documentId: _newId('draft_extract'),
      files: normalizedDrafts
          .map(
            (draft) => DocumentsApiFilePayload(
              fileName: draft.fileName,
              mimeType: draft.mimeType,
              payload: draft.payload,
            ),
          )
          .toList(growable: false),
      preferredLanguage: preferredLanguage,
    );
  }

  Future<File?> exportDocumentFileToTempFile({
    required String documentId,
    required String fileId,
  }) async {
    final doc = await findDocumentById(documentId);
    if (doc == null) {
      return null;
    }

    final selected = doc.files.where((file) => file.id == fileId).toList();
    if (selected.isEmpty) {
      return null;
    }

    final exported = await _exportSingleDocumentFile(
      documentId: doc.id,
      index: selected.first.sortOrder,
      file: selected.first,
    );
    return exported;
  }

  Future<List<File>> exportDocumentToTempFiles(String documentId) async {
    final doc = await findDocumentById(documentId);
    if (doc == null) {
      return const [];
    }

    final output = <File>[];
    for (final file in doc.files) {
      output.add(
        await _exportSingleDocumentFile(
          documentId: doc.id,
          index: file.sortOrder,
          file: file,
        ),
      );
    }

    return output;
  }

  Future<File?> exportDocumentToTempFile(String documentId) async {
    final files = await exportDocumentToTempFiles(documentId);
    if (files.isEmpty) {
      return null;
    }

    return files.first;
  }

  String defaultTitleFromFileName(String fileName) {
    final withoutExtension = p.basenameWithoutExtension(fileName).trim();
    if (withoutExtension.isEmpty) {
      return 'Document';
    }

    return withoutExtension;
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb < 100 ? 1 : 0)} KB';
    }

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 100 ? 1 : 0)} MB';
  }

  Future<File> _exportSingleDocumentFile({
    required String documentId,
    required int index,
    required MedicalDocumentFile file,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(p.join(tempDir.path, 'medvault_documents'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final safeName = _safeFileName(file.fileName);
    final exportPath = p.join(
      dir.path,
      '${documentId.substring(0, min(8, documentId.length))}_${index + 1}_$safeName',
    );

    final output = File(exportPath);
    await output.writeAsBytes(file.encryptedPayload, flush: true);
    return output;
  }

  Future<void> _upsertDocument(MedicalDocument document) async {
    final normalizedFiles = _reindexFiles(document.files);
    if (normalizedFiles.isEmpty) {
      throw StateError('A document must include at least one file.');
    }
    _ensureFileLimit(
      currentFileCount: 0,
      requestedAdditionalFiles: normalizedFiles.length,
    );

    final primary = normalizedFiles.first;

    await _db.transaction(() async {
      await _db
          .into(_db.medicalDocuments)
          .insert(
            _toDocumentCompanion(document: document, primaryFile: primary),
            mode: InsertMode.insertOrReplace,
          );

      await (_db.delete(_db.medicalDocumentFiles)..where(
            (tbl) =>
                tbl.userId.equals(document.userId) &
                tbl.documentId.equals(document.id),
          ))
          .go();

      for (final file in normalizedFiles) {
        await _db
            .into(_db.medicalDocumentFiles)
            .insert(_toFileCompanion(file), mode: InsertMode.insertOrReplace);
      }
    });
  }

  db.MedicalDocumentsCompanion _toDocumentCompanion({
    required MedicalDocument document,
    required MedicalDocumentFile primaryFile,
  }) {
    return db.MedicalDocumentsCompanion.insert(
      id: document.id,
      userId: document.userId,
      title: document.title,
      description: Value(document.description),
      documentDate: Value(document.documentDate),
      category: Value(document.category.name),
      tags: Value(_encodeTags(document.tags)),
      documentType: primaryFile.type.name,
      fileName: primaryFile.fileName,
      fileExtension: Value(primaryFile.fileExtension),
      mimeType: Value(primaryFile.mimeType),
      fileSizeBytes: document.fileSizeBytes,
      encryptedPayload: primaryFile.encryptedPayload,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
    );
  }

  db.MedicalDocumentFilesCompanion _toFileCompanion(MedicalDocumentFile file) {
    return db.MedicalDocumentFilesCompanion.insert(
      id: file.id,
      documentId: file.documentId,
      userId: file.userId,
      documentType: file.type.name,
      fileName: file.fileName,
      fileExtension: Value(file.fileExtension),
      mimeType: Value(file.mimeType),
      fileSizeBytes: file.fileSizeBytes,
      encryptedPayload: file.encryptedPayload,
      sortOrder: Value(file.sortOrder),
      createdAt: file.createdAt,
      updatedAt: file.updatedAt,
    );
  }

  Future<void> _loadForUser(String userId) async {
    final rows = await (_db.select(
      _db.medicalDocuments,
    )..where((tbl) => tbl.userId.equals(userId))).get();

    final fileRows = await (_db.select(
      _db.medicalDocumentFiles,
    )..where((tbl) => tbl.userId.equals(userId))).get();

    final filesByDocumentId = <String, List<db.MedicalDocumentFile>>{};
    for (final row in fileRows) {
      filesByDocumentId.putIfAbsent(
        row.documentId,
        () => <db.MedicalDocumentFile>[],
      );
      filesByDocumentId[row.documentId]!.add(row);
    }

    _documents = rows
        .map((row) => _mapRow(row, filesByDocumentId[row.id] ?? const []))
        .toList(growable: false);
  }

  MedicalDocument _mapRow(
    db.MedicalDocument row,
    List<db.MedicalDocumentFile> fileRows,
  ) {
    final mappedFiles = fileRows.map(_mapFileRow).toList(growable: false)
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));

    final files = mappedFiles.isNotEmpty
        ? mappedFiles
        : [_legacyFileFromDocumentRow(row)];

    return MedicalDocument(
      id: row.id,
      userId: row.userId,
      title: row.title,
      description: row.description,
      documentDate: row.documentDate,
      category: MedicalDocumentCategory.fromValue(row.category),
      tags: _decodeTags(row.tags),
      files: files,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  MedicalDocumentFile _mapFileRow(db.MedicalDocumentFile row) {
    return MedicalDocumentFile(
      id: row.id,
      documentId: row.documentId,
      userId: row.userId,
      type: _documentTypeFromStoredValue(
        value: row.documentType,
        fileName: row.fileName,
        mimeType: row.mimeType,
      ),
      fileName: row.fileName,
      fileExtension: row.fileExtension,
      mimeType: row.mimeType,
      fileSizeBytes: row.fileSizeBytes,
      encryptedPayload: row.encryptedPayload,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  MedicalDocumentFile _legacyFileFromDocumentRow(db.MedicalDocument row) {
    return MedicalDocumentFile(
      id: '${row.id}-legacy-0',
      documentId: row.id,
      userId: row.userId,
      type: _documentTypeFromStoredValue(
        value: row.documentType,
        fileName: row.fileName,
        mimeType: row.mimeType,
      ),
      fileName: row.fileName,
      fileExtension: row.fileExtension,
      mimeType: row.mimeType,
      fileSizeBytes: row.fileSizeBytes,
      encryptedPayload: row.encryptedPayload,
      sortOrder: 0,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<String?> _resolveCurrentUserId() async {
    final user = await _currentUserProvider();
    final userId = user?.email.trim();
    if (userId == null || userId.isEmpty) {
      return null;
    }

    return userId;
  }

  Future<String> _requireCurrentUserId() async {
    final resolved = await _resolveCurrentUserId();
    if (resolved == null) {
      throw StateError('No authenticated user for documents flow.');
    }

    if (_currentUserId != resolved) {
      _currentUserId = resolved;
      await _loadForUser(resolved);
    }

    return resolved;
  }

  List<DocumentUploadDraft> _resolveDraftInputs({
    DocumentUploadDraft? singleDraft,
    List<DocumentUploadDraft> drafts = const [],
  }) {
    final resolved = <DocumentUploadDraft>[];
    if (singleDraft != null) {
      resolved.add(singleDraft);
    }
    resolved.addAll(drafts);
    if (resolved.isEmpty) {
      throw ArgumentError('At least one file draft is required.');
    }

    return resolved;
  }

  void _ensureFileLimit({
    required int currentFileCount,
    required int requestedAdditionalFiles,
  }) {
    final total = currentFileCount + requestedAdditionalFiles;
    if (total <= currentMaxFilesPerDocument) {
      return;
    }

    throw DocumentFileLimitExceededException(
      maxFiles: currentMaxFilesPerDocument,
      currentFileCount: currentFileCount,
      requestedAdditionalFiles: requestedAdditionalFiles,
    );
  }

  List<MedicalDocumentFile> _reindexFiles(
    List<MedicalDocumentFile> files, {
    DateTime? updatedAt,
  }) {
    final now = updatedAt ?? DateTime.now();
    final sorted = List<MedicalDocumentFile>.from(files)
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));

    return sorted
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(sortOrder: entry.key, updatedAt: now),
        )
        .toList(growable: false);
  }

  String _newId(String prefix) {
    final random = Random.secure().nextInt(1 << 20).toRadixString(16);
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  String _normalizeTitle(String value, {required String fallbackFileName}) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    return defaultTitleFromFileName(fallbackFileName);
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String? _normalizeExtension(String fileName) {
    final ext = p
        .extension(fileName)
        .replaceFirst('.', '')
        .trim()
        .toLowerCase();
    if (ext.isEmpty) {
      return null;
    }

    return ext;
  }

  MedicalDocumentType _documentTypeFromStoredValue({
    required String value,
    required String fileName,
    required String? mimeType,
  }) {
    return MedicalDocumentType.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => _resolveType(fileName: fileName, mimeType: mimeType),
    );
  }

  MedicalDocumentType _resolveType({
    required String fileName,
    required String? mimeType,
  }) {
    final extension = _normalizeExtension(fileName);
    if (extension == null) {
      return _resolveTypeFromMime(mimeType);
    }

    switch (extension) {
      case 'pdf':
        return MedicalDocumentType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return MedicalDocumentType.image;
      case 'docx':
        return MedicalDocumentType.docx;
      case 'xlsx':
      case 'xls':
        return MedicalDocumentType.xlsx;
      default:
        return _resolveTypeFromMime(mimeType);
    }
  }

  MedicalDocumentType _resolveTypeFromMime(String? mimeType) {
    final normalized = mimeType?.toLowerCase().trim();
    if (normalized == null || normalized.isEmpty) {
      return MedicalDocumentType.other;
    }

    if (normalized == 'application/pdf') {
      return MedicalDocumentType.pdf;
    }

    if (normalized.startsWith('image/')) {
      return MedicalDocumentType.image;
    }

    if (normalized.contains('wordprocessingml')) {
      return MedicalDocumentType.docx;
    }

    if (normalized.contains('spreadsheetml') || normalized.contains('excel')) {
      return MedicalDocumentType.xlsx;
    }

    return MedicalDocumentType.other;
  }

  String _encodeTags(List<String> tags) {
    return jsonEncode(_normalizeTags(tags));
  }

  List<String> _decodeTags(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) {
        return const [];
      }

      return _normalizeTags(decoded.whereType<String>().toList());
    } catch (_) {
      return const [];
    }
  }

  List<String> _normalizeTags(List<String> tags) {
    final result = <String>[];
    final seen = <String>{};

    for (final tag in tags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        result.add(trimmed);
      }
    }

    return result;
  }

  String _safeFileName(String fileName) {
    final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (sanitized.isEmpty) {
      return 'document.bin';
    }

    return sanitized;
  }
}
