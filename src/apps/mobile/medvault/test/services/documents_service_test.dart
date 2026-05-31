import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault/models/documents_models.dart';
import 'package:medvault/services/api/documents_api.dart';
import 'package:medvault/services/auth_service.dart';
import 'package:medvault/services/database.dart';
import 'package:medvault/services/documents_service.dart';

class _FakeDocumentsApiClient implements DocumentsApiClient {
  DocumentExtractionResult? response;
  int callCount = 0;
  List<DocumentsApiFilePayload> lastFiles = const [];
  String? lastPreferredLanguage;

  @override
  Future<DocumentExtractionResult?> extractDocumentData({
    required String documentId,
    required List<DocumentsApiFilePayload> files,
    required String preferredLanguage,
  }) async {
    callCount += 1;
    lastFiles = files;
    lastPreferredLanguage = preferredLanguage;
    return response;
  }
}

void main() {
  group('DocumentsService', () {
    late AppDatabase database;
    late _FakeDocumentsApiClient apiClient;

    Future<AuthUser?> currentUser() async {
      return const AuthUser(email: 'demo.user@medvault.local');
    }

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      apiClient = _FakeDocumentsApiClient();
    });

    tearDown(() async {
      await database.close();
    });

    test('create, update and delete document lifecycle', () async {
      final service = DocumentsService(
        currentUserProvider: currentUser,
        demoMode: true,
        apiClient: apiClient,
        database: database,
      );

      final draft = service.createDraft(
        payload: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'blood-work.pdf',
        mimeType: 'application/pdf',
      );

      final created = await service.createDocument(
        drafts: [draft],
        title: 'Blood Work',
        description: 'Annual checkup',
        category: MedicalDocumentCategory.labResults,
        tags: const ['blood test', 'annual'],
      );

      expect(service.documents.length, 1);
      expect(service.documents.first.id, created.id);
      expect(service.documents.first.type, MedicalDocumentType.pdf);
      expect(service.documents.first.files.length, 1);
      expect(
        service.documents.first.category,
        MedicalDocumentCategory.labResults,
      );
      expect(service.documents.first.tags, const ['blood test', 'annual']);

      await service.updateDocumentDetails(
        documentId: created.id,
        title: 'Blood Work 2026',
        description: 'Updated details',
        documentDate: DateTime(2026, 4, 10),
        category: MedicalDocumentCategory.medicalReport,
        tags: const ['annual', 'review'],
      );

      final updated = service.documents.first;
      expect(updated.title, 'Blood Work 2026');
      expect(updated.description, 'Updated details');
      expect(updated.documentDate, DateTime(2026, 4, 10));
      expect(updated.category, MedicalDocumentCategory.medicalReport);
      expect(updated.tags, const ['annual', 'review']);

      await service.deleteDocument(created.id);
      expect(service.documents, isEmpty);
    });

    test('adds and removes files from the same document', () async {
      final service = DocumentsService(
        currentUserProvider: currentUser,
        demoMode: true,
        apiClient: apiClient,
        database: database,
      );

      final initialDraft = service.createDraft(
        payload: Uint8List.fromList([1, 2, 3]),
        fileName: 'lab-result-1.jpg',
        mimeType: 'image/jpeg',
      );
      final created = await service.createDocument(
        drafts: [initialDraft],
        title: 'Lab Result',
      );

      final secondDraft = service.createDraft(
        payload: Uint8List.fromList([7, 8, 9, 10]),
        fileName: 'lab-result-2.jpg',
        mimeType: 'image/jpeg',
      );
      final thirdDraft = service.createDraft(
        payload: Uint8List.fromList([4, 5, 6]),
        fileName: 'lab-result-3.pdf',
        mimeType: 'application/pdf',
      );

      final withMoreFiles = await service.addFilesToDocument(
        documentId: created.id,
        drafts: [secondDraft, thirdDraft],
      );

      expect(withMoreFiles, isNotNull);
      expect(withMoreFiles!.files.length, 3);
      expect(service.documents.first.files.length, 3);

      final removed = await service.removeFileFromDocument(
        documentId: created.id,
        fileId: withMoreFiles.files[1].id,
      );

      expect(removed, isNotNull);
      expect(removed!.files.length, 2);
      expect(service.documents.first.files.length, 2);
    });

    test('createDocument rejects more than 10 files', () async {
      final service = DocumentsService(
        currentUserProvider: currentUser,
        demoMode: true,
        apiClient: apiClient,
        database: database,
      );

      final drafts = List.generate(
        DocumentsService.maxFilesPerDocument + 1,
        (index) => service.createDraft(
          payload: Uint8List.fromList([index + 1]),
          fileName: 'file-$index.pdf',
          mimeType: 'application/pdf',
        ),
      );

      await expectLater(
        () => service.createDocument(drafts: drafts, title: 'Too many files'),
        throwsA(
          isA<DocumentFileLimitExceededException>()
              .having((e) => e.maxFiles, 'maxFiles', 10)
              .having(
                (e) => e.requestedTotalFileCount,
                'requestedTotalFileCount',
                DocumentsService.maxFilesPerDocument + 1,
              ),
        ),
      );
    });

    test('addFilesToDocument rejects updates over the file limit', () async {
      final service = DocumentsService(
        currentUserProvider: currentUser,
        demoMode: true,
        apiClient: apiClient,
        database: database,
      );

      final initialDraft = service.createDraft(
        payload: Uint8List.fromList([1, 2, 3]),
        fileName: 'baseline.pdf',
        mimeType: 'application/pdf',
      );
      final created = await service.createDocument(
        drafts: [initialDraft],
        title: 'Baseline document',
      );

      final overLimitDrafts = List.generate(
        DocumentsService.maxFilesPerDocument,
        (index) => service.createDraft(
          payload: Uint8List.fromList([index + 5]),
          fileName: 'append-$index.jpg',
          mimeType: 'image/jpeg',
        ),
      );

      await expectLater(
        () => service.addFilesToDocument(
          documentId: created.id,
          drafts: overLimitDrafts,
        ),
        throwsA(
          isA<DocumentFileLimitExceededException>()
              .having((e) => e.currentFileCount, 'currentFileCount', 1)
              .having(
                (e) => e.requestedAdditionalFiles,
                'requestedAdditionalFiles',
                DocumentsService.maxFilesPerDocument,
              ),
        ),
      );
    });

    test('createDraft resolves known document types from extension', () {
      final service = DocumentsService(
        currentUserProvider: currentUser,
        demoMode: true,
        apiClient: apiClient,
        database: database,
      );

      expect(
        service
            .createDraft(
              payload: Uint8List(1),
              fileName: 'photo.jpeg',
              mimeType: 'image/jpeg',
            )
            .type,
        MedicalDocumentType.image,
      );

      expect(
        service
            .createDraft(
              payload: Uint8List(1),
              fileName: 'report.docx',
              mimeType:
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            )
            .type,
        MedicalDocumentType.docx,
      );

      expect(
        service
            .createDraft(
              payload: Uint8List(1),
              fileName: 'sheet.xlsx',
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            )
            .type,
        MedicalDocumentType.xlsx,
      );
    });

    test('extractDocumentData throws in demo mode', () async {
      final service = DocumentsService(
        currentUserProvider: currentUser,
        demoMode: true,
        apiClient: apiClient,
        database: database,
      );

      final draft = service.createDraft(
        payload: Uint8List.fromList([1, 2]),
        fileName: 'lab.pdf',
        mimeType: 'application/pdf',
      );
      final created = await service.createDocument(
        drafts: [draft],
        title: 'Lab',
      );

      await expectLater(
        () => service.extractDocumentData(created.id),
        throwsA(isA<DocumentExtractionUnavailableInDemoException>()),
      );
      expect(apiClient.callCount, 0);
    });

    test(
      'extractDocumentData delegates to api client in non-demo mode',
      () async {
        apiClient.response = const DocumentExtractionResult(
          isMedical: true,
          documentType: 'Lab Report',
          date: null,
          issuerName: 'North Hospital',
          metadata: MedicalExtractionMetadata(
            medications: [],
            labResults: [],
            allergies: [],
            diagnoses: [],
            vaccinations: [],
          ),
          summary: 'Parsed summary',
          confidence: 0.8,
          requiresUserConfirmation: true,
        );

        final service = DocumentsService(
          currentUserProvider: currentUser,
          demoMode: false,
          apiClient: apiClient,
          database: database,
        );

        final draft = service.createDraft(
          payload: Uint8List.fromList([10, 20, 30]),
          fileName: 'summary.pdf',
          mimeType: 'application/pdf',
        );
        final created = await service.createDocument(
          drafts: [draft],
          title: 'Summary',
        );

        final extracted = await service.extractDocumentData(
          created.id,
          preferredLanguage: 'es',
        );
        expect(extracted, isNotNull);
        expect(extracted?.documentType, 'Lab Report');
        expect(apiClient.callCount, 1);
        expect(apiClient.lastFiles.length, 1);
        expect(apiClient.lastPreferredLanguage, 'es');
      },
    );
  });
}
