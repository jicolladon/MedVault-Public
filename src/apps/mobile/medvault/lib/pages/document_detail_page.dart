import 'dart:typed_data';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/di/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/documents_models.dart';
import '../models/medical_models.dart';
import '../services/documents_service.dart';
import '../services/medical_data_service.dart';
import '../widgets/medvault_page_header.dart';

class DocumentDetailPage extends StatefulWidget {
  DocumentDetailPage({
    super.key,
    required this.documentsService,
    this.existingDocument,
    this.uploadDrafts,
  }) : assert(
         existingDocument != null ||
             (uploadDrafts != null && uploadDrafts.isNotEmpty),
         'Either existingDocument or a non-empty uploadDrafts list must be provided.',
       );

  final DocumentsService documentsService;
  final MedicalDocument? existingDocument;
  final List<DocumentUploadDraft>? uploadDrafts;

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  final _filePageController = PageController();
  final List<String> _tags = [];
  late final MedicalDataService _medicalDataService;

  DateTime? _documentDate;
  MedicalDocumentCategory _selectedCategory = MedicalDocumentCategory.other;
  bool _isSaving = false;
  bool _isExtracting = false;
  bool _isUpdatingFiles = false;
  bool _isImportingExtractedData = false;
  int _selectedFileIndex = 0;
  DocumentExtractionResult? _lastExtractionResult;

  List<DocumentUploadDraft> _draftFiles = const [];
  List<MedicalDocumentFile> _existingFiles = const [];

  bool get _isEditing => widget.existingDocument != null;

  List<_DisplayDocumentFile> get _displayFiles {
    if (_isEditing) {
      return _existingFiles
          .map(
            (file) => _DisplayDocumentFile(
              id: file.id,
              fileName: file.fileName,
              fileExtension: file.fileExtension,
              mimeType: file.mimeType,
              type: file.type,
              fileSizeBytes: file.fileSizeBytes,
              payload: file.encryptedPayload,
            ),
          )
          .toList(growable: false);
    }

    return _draftFiles
        .asMap()
        .entries
        .map(
          (entry) => _DisplayDocumentFile(
            id: 'draft-${entry.key}',
            fileName: entry.value.fileName,
            fileExtension: entry.value.fileExtension,
            mimeType: entry.value.mimeType,
            type: entry.value.type,
            fileSizeBytes: entry.value.fileSizeBytes,
            payload: entry.value.payload,
          ),
        )
        .toList(growable: false);
  }

  _DisplayDocumentFile? get _selectedFile {
    final files = _displayFiles;
    if (files.isEmpty) {
      return null;
    }

    final index = _selectedFileIndex.clamp(0, files.length - 1);
    return files[index];
  }

  int get _totalFileSize {
    return _displayFiles.fold<int>(0, (sum, file) => sum + file.fileSizeBytes);
  }

  bool get _supportsExtraction {
    if (_isEditing) {
      return _existingFiles.any((file) => file.supportsExtraction);
    }

    return _draftFiles.any((file) => file.supportsExtraction);
  }

  @override
  void initState() {
    super.initState();
    _medicalDataService = ServiceLocator.instance.medicalDataService;

    final existing = widget.existingDocument;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _descriptionCtrl.text = existing.description ?? '';
      _documentDate = existing.documentDate;
      _selectedCategory = existing.category;
      _tags.addAll(existing.tags);
      _existingFiles = List<MedicalDocumentFile>.from(existing.files)
        ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
      return;
    }

    _draftFiles = List<DocumentUploadDraft>.from(
      widget.uploadDrafts ?? const [],
    );
    final firstDraft = _draftFiles.isNotEmpty ? _draftFiles.first : null;
    if (firstDraft != null) {
      _titleCtrl.text = widget.documentsService.defaultTitleFromFileName(
        firstDraft.fileName,
      );
    }
  }

  bool _hasImportableExtractionData(DocumentExtractionResult result) {
    final metadata = result.metadata;
    return metadata.medications.isNotEmpty ||
        metadata.labResults.isNotEmpty ||
        metadata.allergies.isNotEmpty ||
        metadata.diagnoses.isNotEmpty ||
        metadata.vaccinations.isNotEmpty;
  }

  Future<void> _reviewAndImportExtractedData() async {
    if (_isImportingExtractedData) {
      return;
    }

    final result = _lastExtractionResult;
    if (result == null || !_hasImportableExtractionData(result)) {
      return;
    }

    final selection = await showModalBottomSheet<_ExtractionImportSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ExtractionImportBottomSheet(result: result),
    );

    if (selection == null) {
      return;
    }

    if (selection.selectedCount == 0) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items were selected to import.')),
      );
      return;
    }

    setState(() => _isImportingExtractedData = true);

    try {
      final importedCount = await _importSelectedExtractedItems(
        result,
        selection,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            importedCount > 0
                ? 'Imported $importedCount item${importedCount == 1 ? '' : 's'} to your medical records.'
                : 'No valid items were imported.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to import extracted medical data: $error\n$stackTrace',
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to import extracted data.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isImportingExtractedData = false);
      }
    }
  }

  Future<int> _importSelectedExtractedItems(
    DocumentExtractionResult result,
    _ExtractionImportSelection selection,
  ) async {
    final metadata = result.metadata;
    final now = DateTime.now();
    var importedCount = 0;

    for (final index in selection.medicationIndexes) {
      if (index < 0 || index >= metadata.medications.length) {
        continue;
      }

      final medication = metadata.medications[index];
      final name = medication.name.trim();
      if (name.isEmpty) {
        continue;
      }

      await _medicalDataService.addMedication(
        Medication(
          id: '',
          userId: '',
          name: name,
          dosage: medication.dosage,
          frequency: medication.frequency.isEmpty
              ? 'Once daily'
              : medication.frequency,
          startDate: medication.startDate ?? result.date ?? now,
          endDate: medication.endDate,
          notes: medication.notes.isEmpty ? null : medication.notes,
          createdAt: now,
          updatedAt: now,
        ),
      );
      importedCount++;
    }

    for (final index in selection.allergyIndexes) {
      if (index < 0 || index >= metadata.allergies.length) {
        continue;
      }

      final allergy = metadata.allergies[index];
      final substance = allergy.allergen.trim();
      if (substance.isEmpty) {
        continue;
      }

      await _medicalDataService.addAllergy(
        Allergy(
          id: '',
          userId: '',
          substance: substance,
          reaction: allergy.reaction,
          severity: _mapExtractedAllergySeverity(allergy.severity),
          notes: allergy.notes.isEmpty ? null : allergy.notes,
          createdAt: now,
          updatedAt: now,
        ),
      );
      importedCount++;
    }

    for (final index in selection.diagnosisIndexes) {
      if (index < 0 || index >= metadata.diagnoses.length) {
        continue;
      }

      final diagnosis = metadata.diagnoses[index];
      final name = diagnosis.name.trim().isNotEmpty
          ? diagnosis.name.trim()
          : diagnosis.code.trim();
      if (name.isEmpty) {
        continue;
      }

      await _medicalDataService.addDiagnosis(
        Diagnosis(
          id: '',
          userId: '',
          name: name,
          status: DiagnosisStatus.active,
          date: diagnosis.diagnosisDate ?? result.date ?? now,
          duration: diagnosis.duration.isEmpty ? null : diagnosis.duration,
          notes: diagnosis.notes.isEmpty ? null : diagnosis.notes,
          createdAt: now,
          updatedAt: now,
        ),
      );
      importedCount++;
    }

    for (final index in selection.vaccinationIndexes) {
      if (index < 0 || index >= metadata.vaccinations.length) {
        continue;
      }

      final vaccination = metadata.vaccinations[index];
      final vaccineName = vaccination.name.trim();
      if (vaccineName.isEmpty) {
        continue;
      }

      final dates = vaccination.dates.isNotEmpty
          ? vaccination.dates
          : <DateTime>[vaccination.date ?? result.date ?? now];
      await _medicalDataService.addVaccination(
        Vaccination(
          id: '',
          userId: '',
          vaccineName: vaccineName,
          dates: dates,
          createdAt: now,
          updatedAt: now,
        ),
      );
      importedCount++;
    }

    for (final index in selection.labResultIndexes) {
      if (index < 0 || index >= metadata.labResults.length) {
        continue;
      }

      final labResult = metadata.labResults[index];
      final testName = labResult.testName.trim();
      if (testName.isEmpty) {
        continue;
      }

      final values = labResult.normalizedValues
          .where((value) => value.name.trim().isNotEmpty)
          .map(
            (value) => LabTestValue(
              name: value.name,
              value: value.value,
              unit: value.unit,
              minRange: value.minRange.isEmpty ? null : value.minRange,
              maxRange: value.maxRange.isEmpty ? null : value.maxRange,
              status: TestResultStatus.pending,
            ),
          )
          .toList(growable: false);

      await _medicalDataService.addLabResult(
        LabResult(
          id: '',
          userId: '',
          testName: testName,
          category: labResult.category.isEmpty ? 'General' : labResult.category,
          testDate: labResult.testDate ?? result.date ?? now,
          values: values,
          notes: labResult.notes.isEmpty ? null : labResult.notes,
          createdAt: now,
          updatedAt: now,
        ),
      );
      importedCount++;
    }

    return importedCount;
  }

  AllergySeverity _mapExtractedAllergySeverity(String severity) {
    switch (severity.trim().toLowerCase()) {
      case 'mild':
      case 'low':
        return AllergySeverity.mild;
      case 'severe':
      case 'high':
      case 'critical':
        return AllergySeverity.severe;
      default:
        return AllergySeverity.moderate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagsCtrl.dispose();
    _filePageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _documentDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _documentDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    final localizations = AppLocalizations.of(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_displayFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsAtLeastOneFileRequired ??
                'At least one file is required',
          ),
        ),
      );
      return;
    }

    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final tags = _buildTagsForSave();

    setState(() => _isSaving = true);

    try {
      final existing = widget.existingDocument;
      if (existing != null) {
        await widget.documentsService.updateDocumentDetails(
          documentId: existing.id,
          title: title,
          description: description,
          documentDate: _documentDate,
          category: _selectedCategory,
          tags: tags,
        );
      } else {
        await widget.documentsService.createDocument(
          drafts: _draftFiles,
          title: title,
          description: description,
          documentDate: _documentDate,
          category: _selectedCategory,
          tags: tags,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on DocumentFileLimitExceededException {
      if (!mounted) {
        return;
      }

      _showFileLimitSnackBar(availableSlots: _remainingFileSlots);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsSaveFailed ?? 'Failed to save document',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _extractData() async {
    final localizations = AppLocalizations.of(context);
    if (!widget.documentsService.documentExtractDataEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsExtractionDisabledInSettings ??
                'Document extraction is disabled in your settings.',
          ),
        ),
      );
      return;
    }

    if (!_supportsExtraction) {
      return;
    }

    setState(() => _isExtracting = true);

    try {
      final preferredLanguage = Localizations.localeOf(context).languageCode;
      final existing = widget.existingDocument;
      final result = existing != null
          ? await widget.documentsService.extractDocumentData(
              existing.id,
              preferredLanguage: preferredLanguage,
            )
          : await widget.documentsService.extractDocumentDataFromDrafts(
              _draftFiles,
              preferredLanguage: preferredLanguage,
            );

      if (!mounted) {
        return;
      }

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.documentsExtractionNotReady ??
                  'Document extraction is not connected yet',
            ),
          ),
        );
        return;
      }

      setState(() {
        final suggestedTitle = result.suggestedTitle;
        if (suggestedTitle.trim().isNotEmpty) {
          _titleCtrl.text = suggestedTitle.trim();
        }

        if (result.summary.trim().isNotEmpty) {
          _descriptionCtrl.text = result.summary.trim();
        }

        if (result.date != null) {
          _documentDate = DateTime(
            result.date!.year,
            result.date!.month,
            result.date!.day,
          );
        }

        if (result.documentType.trim().isNotEmpty) {
          _selectedCategory = _categoryFromDocumentType(result.documentType);
        }

        _mergeExtractedTags(result.tags);

        _lastExtractionResult = result;
      });
    } on DocumentExtractionUnavailableInDemoException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsExtractionUnavailableInDemo ??
                'Extract Data is not available in demo mode yet',
          ),
        ),
      );
    } on DocumentExtractionDisabledBySettingsException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsExtractionDisabledInSettings ??
                'Document extraction is disabled in your settings.',
          ),
        ),
      );
    } on DocumentExtractionUnavailableOfflineException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document extraction requires internet. You are currently offline.',
          ),
        ),
      );
    } on Exception catch (error, stackTrace) {
      debugPrint('Failed to extract document data: $error\n$stackTrace');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsExtractionFailed ??
                'Failed to extract document data',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExtracting = false);
      }
    }
  }

  Future<void> _addFiles() async {
    if (_isSaving || _isUpdatingFiles) {
      return;
    }

    if (_remainingFileSlots <= 0) {
      _showFileLimitSnackBar(availableSlots: 0);
      return;
    }

    final source = await _selectSource();
    if (source == null) {
      return;
    }

    final picked = await _pickDraftsFromSource(source);
    if (picked == null || picked.isEmpty || !mounted) {
      return;
    }

    if (picked.length > _remainingFileSlots) {
      _showFileLimitSnackBar(availableSlots: _remainingFileSlots);
      return;
    }

    final localizations = AppLocalizations.of(context);

    setState(() => _isUpdatingFiles = true);

    try {
      if (_isEditing) {
        final existing = widget.existingDocument;
        if (existing == null) {
          return;
        }

        final updated = await widget.documentsService.addFilesToDocument(
          documentId: existing.id,
          drafts: picked,
        );
        if (!mounted) {
          return;
        }

        setState(() {
          _existingFiles = List<MedicalDocumentFile>.from(
            updated?.files ?? _existingFiles,
          )..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
          _selectedFileIndex = _existingFiles.length - 1;
        });
      } else {
        setState(() {
          _draftFiles = [..._draftFiles, ...picked];
          _selectedFileIndex = _draftFiles.length - 1;
        });
      }

      _jumpToSelectedFile();
    } on DocumentFileLimitExceededException {
      if (!mounted) {
        return;
      }

      _showFileLimitSnackBar(availableSlots: _remainingFileSlots);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsUploadFailed ?? 'Failed to upload file',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFiles = false);
      }
    }
  }

  Future<void> _removeSelectedFile() async {
    if (_isSaving || _isUpdatingFiles) {
      return;
    }

    final localizations = AppLocalizations.of(context);
    final files = _displayFiles;
    if (files.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsAtLeastOneFileRequired ??
                'At least one file is required',
          ),
        ),
      );
      return;
    }

    setState(() => _isUpdatingFiles = true);

    try {
      if (_isEditing) {
        final existing = widget.existingDocument;
        final selected = _selectedFile;
        if (existing == null || selected == null) {
          return;
        }

        final updated = await widget.documentsService.removeFileFromDocument(
          documentId: existing.id,
          fileId: selected.id,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _existingFiles = List<MedicalDocumentFile>.from(
            updated?.files ?? _existingFiles,
          )..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
          _selectedFileIndex = _selectedFileIndex.clamp(
            0,
            _existingFiles.length - 1,
          );
        });
      } else {
        final draftIndex = _selectedFileIndex.clamp(0, _draftFiles.length - 1);
        setState(() {
          _draftFiles = _draftFiles
              .asMap()
              .entries
              .where((entry) => entry.key != draftIndex)
              .map((entry) => entry.value)
              .toList(growable: false);
          _selectedFileIndex = _selectedFileIndex.clamp(
            0,
            _draftFiles.length - 1,
          );
        });
      }

      _jumpToSelectedFile();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.documentsUploadFailed ?? 'Failed to update files',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFiles = false);
      }
    }
  }

  Future<_DocumentSource?> _selectSource() async {
    final t = AppLocalizations.of(context);
    return showModalBottomSheet<_DocumentSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                t?.documentsSelectSourceTitle ?? 'Select document source',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t?.camera ?? 'Camera'),
              onTap: () => Navigator.of(context).pop(_DocumentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t?.documentsFromGallery ?? 'Gallery'),
              onTap: () => Navigator.of(context).pop(_DocumentSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(t?.selectFromFiles ?? 'Select from files'),
              onTap: () => Navigator.of(context).pop(_DocumentSource.files),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<DocumentUploadDraft>?> _pickDraftsFromSource(
    _DocumentSource source,
  ) async {
    final t = AppLocalizations.of(context);

    try {
      switch (source) {
        case _DocumentSource.camera:
          final image = await _imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: 90,
          );
          if (image == null) {
            return null;
          }

          final bytes = await image.readAsBytes();
          return [
            widget.documentsService.createDraft(
              payload: bytes,
              fileName: image.name.isNotEmpty
                  ? image.name
                  : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
              mimeType: 'image/jpeg',
            ),
          ];
        case _DocumentSource.gallery:
          final image = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 90,
          );
          if (image == null) {
            return null;
          }

          final bytes = await image.readAsBytes();
          return [
            widget.documentsService.createDraft(
              payload: bytes,
              fileName: image.name.isNotEmpty
                  ? image.name
                  : 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
              mimeType: 'image/jpeg',
            ),
          ];
        case _DocumentSource.files:
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: const [
              'pdf',
              'jpg',
              'jpeg',
              'png',
              'docx',
              'xlsx',
            ],
            withData: true,
            allowMultiple: true,
          );

          if (result == null || result.files.isEmpty) {
            return null;
          }

          final drafts = <DocumentUploadDraft>[];
          for (final selected in result.files) {
            final bytes = selected.bytes;
            if (bytes == null) {
              continue;
            }

            drafts.add(
              widget.documentsService.createDraft(
                payload: bytes,
                fileName: selected.name,
                mimeType: _inferMimeType(selected.name),
              ),
            );
          }

          if (drafts.isEmpty) {
            if (!mounted) {
              return null;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t?.documentsUploadFailed ?? 'Failed to load selected file',
                ),
              ),
            );
            return null;
          }

          return drafts;
      }
    } catch (_) {
      if (!mounted) {
        return null;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t?.documentsUploadFailed ?? 'Failed to upload file'),
        ),
      );
      return null;
    }
  }

  String? _inferMimeType(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return null;
    }

    switch (parts.last.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return null;
    }
  }

  void _jumpToSelectedFile() {
    final files = _displayFiles;
    if (files.isEmpty || !_filePageController.hasClients) {
      return;
    }

    final target = _selectedFileIndex.clamp(0, files.length - 1);
    _filePageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<File?> _exportDraftFileToTemp(_DisplayDocumentFile file) async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(p.join(tempDir.path, 'medvault_documents_drafts'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final safeFileName = file.fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    final fallbackName = safeFileName.isEmpty
        ? 'draft_${DateTime.now().millisecondsSinceEpoch}.bin'
        : safeFileName;
    final outputPath = p.join(
      dir.path,
      'draft_${DateTime.now().millisecondsSinceEpoch}_$fallbackName',
    );

    final output = File(outputPath);
    await output.writeAsBytes(file.payload, flush: true);
    return output;
  }

  Future<void> _openSelectedFileWithSystem() async {
    final t = AppLocalizations.of(context);
    final selected = _selectedFile;
    if (selected == null) {
      return;
    }

    try {
      File? file;
      if (_isEditing) {
        final existing = widget.existingDocument;
        if (existing == null) {
          return;
        }

        file = await widget.documentsService.exportDocumentFileToTempFile(
          documentId: existing.id,
          fileId: selected.id,
        );
      } else {
        file = await _exportDraftFileToTemp(selected);
      }

      if (file == null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t?.documentsOpenFailed ?? 'Failed to open document'),
          ),
        );
        return;
      }

      final result = await OpenFilex.open(file.path);
      if (!mounted) {
        return;
      }

      if (result.type == ResultType.done) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t?.documentsOpenFailed ?? 'Failed to open document'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t?.documentsOpenFailed ?? 'Failed to open document'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateText = _documentDate == null
        ? (t?.documentsNoDateSelected ?? 'No date selected')
        : DateFormat.yMMMd(t?.localeName).format(_documentDate!);
    final selectedFile = _selectedFile;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: _isEditing
                ? (t?.documentsEditDetailsTitle ?? 'Edit document details')
                : (t?.documentsAddDetailsTitle ?? 'Document details'),
            leading: IconButton(
              tooltip: t?.onboardingBack,
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FilesInfoCard(
                        files: _displayFiles,
                        selectedIndex: _selectedFileIndex,
                        onSelected: (index) {
                          setState(() => _selectedFileIndex = index);
                          _jumpToSelectedFile();
                        },
                        pageController: _filePageController,
                        onPageChanged: (index) {
                          setState(() => _selectedFileIndex = index);
                        },
                        filesSummary:
                            '${_filesCountLabel(t, _displayFiles.length)} • '
                            '${widget.documentsService.formatFileSize(_totalFileSize)}',
                        addFilesLabel: t?.documentsAddFileButton ?? 'Add files',
                        removeFileLabel:
                            t?.documentsRemoveSelectedFileButton ??
                            'Remove selected file',
                        onAddFiles: (_isSaving || _isUpdatingFiles)
                            ? null
                            : _addFiles,
                        onRemoveFile: (_isSaving || _isUpdatingFiles)
                            ? null
                            : _removeSelectedFile,
                      ),
                      const SizedBox(height: 16),
                      if (selectedFile != null)
                        _SelectedFileDetails(
                          file: selectedFile,
                          typeLabel: _typeLabel(t, selectedFile.type),
                          sizeLabel: widget.documentsService.formatFileSize(
                            selectedFile.fileSizeBytes,
                          ),
                        ),
                      if (selectedFile != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (_isSaving || _isUpdatingFiles)
                                ? null
                                : _openSelectedFileWithSystem,
                            icon: const Icon(Icons.open_in_new_outlined),
                            label: Text(
                              t?.documentsOpenWithApp ?? 'Open with app',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _titleCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: t?.name ?? 'Name',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return t?.fieldRequired(t.name) ??
                                'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: t?.description ?? 'Description',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<MedicalDocumentCategory>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: t?.documentsCategoryLabel ?? 'Category',
                          border: const OutlineInputBorder(),
                        ),
                        items: MedicalDocumentCategory.values
                            .map(
                              (category) =>
                                  DropdownMenuItem<MedicalDocumentCategory>(
                                    value: category,
                                    child: Text(_categoryLabel(t, category)),
                                  ),
                            )
                            .toList(growable: false),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() => _selectedCategory = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagsCtrl,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _addTagFromInput(),
                        decoration: InputDecoration(
                          labelText: t?.documentsTagsLabel ?? 'Tags',
                          hintText:
                              t?.documentsTagsHint ?? 'Type a tag and tap +',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: _isSaving ? null : _addTagFromInput,
                            icon: const Icon(Icons.add),
                          ),
                        ),
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags
                              .map(
                                (tag) => InputChip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                  backgroundColor: theme.colorScheme.surface,
                                  labelStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  onDeleted: _isSaving
                                      ? null
                                      : () => _removeTag(tag),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          '${t?.date ?? 'Date'}: $dateText',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              (_isSaving ||
                                  _isExtracting ||
                                  !widget
                                      .documentsService
                                      .documentExtractDataEnabled ||
                                  !widget
                                      .documentsService
                                      .canUseRemoteFeatures ||
                                  !_supportsExtraction)
                              ? null
                              : _extractData,
                          icon: _isExtracting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_outlined),
                          label: Text(
                            t?.documentsExtractDataButton ?? 'Extract Data',
                          ),
                        ),
                      ),
                      if (!widget.documentsService.documentExtractDataEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Document extraction is disabled in your settings.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (!widget.documentsService.canUseRemoteFeatures)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Document extraction requires internet access.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (_lastExtractionResult != null) ...[
                        const SizedBox(height: 12),
                        _ExtractionReviewCard(
                          result: _lastExtractionResult!,
                          canImport: _hasImportableExtractionData(
                            _lastExtractionResult!,
                          ),
                          isImporting: _isImportingExtractedData,
                          onImport: _isImportingExtractedData
                              ? null
                              : _reviewAndImportExtractedData,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving || _isUpdatingFiles
                              ? null
                              : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(t?.save ?? 'Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AppLocalizations? t, MedicalDocumentType type) {
    switch (type) {
      case MedicalDocumentType.pdf:
        return t?.documentsTypePdf ?? 'PDF';
      case MedicalDocumentType.image:
        return t?.documentsTypeImage ?? 'Image';
      case MedicalDocumentType.docx:
        return t?.documentsTypeDocx ?? 'DOCX';
      case MedicalDocumentType.xlsx:
        return t?.documentsTypeXlsx ?? 'XLSX';
      case MedicalDocumentType.other:
        return t?.documentsTypeOther ?? 'Other';
    }
  }

  String _categoryLabel(AppLocalizations? t, MedicalDocumentCategory category) {
    switch (category) {
      case MedicalDocumentCategory.labResults:
        return t?.documentsCategoryLabResults ?? 'Lab Results';
      case MedicalDocumentCategory.medicalReport:
        return t?.documentsCategoryMedicalReport ?? 'Medical Report';
      case MedicalDocumentCategory.medicationReport:
        return t?.documentsCategoryMedicationReport ?? 'Medication Report';
      case MedicalDocumentCategory.vaccinations:
        return t?.documentsCategoryVaccinations ?? 'Vaccinations';
      case MedicalDocumentCategory.other:
        return t?.documentsCategoryOther ?? 'Other';
    }
  }

  MedicalDocumentCategory _categoryFromDocumentType(String documentType) {
    final normalized = documentType.trim().toLowerCase();
    if (normalized.contains('lab')) {
      return MedicalDocumentCategory.labResults;
    }
    if (normalized.contains('prescription') ||
        normalized.contains('medication')) {
      return MedicalDocumentCategory.medicationReport;
    }
    if (normalized.contains('vaccine') || normalized.contains('vaccin')) {
      return MedicalDocumentCategory.vaccinations;
    }
    if (normalized.contains('report')) {
      return MedicalDocumentCategory.medicalReport;
    }

    return MedicalDocumentCategory.other;
  }

  void _addTagFromInput() {
    final normalized = _normalizeTag(_tagsCtrl.text);
    if (normalized == null) {
      return;
    }

    final exists = _tags.any(
      (tag) => tag.toLowerCase() == normalized.toLowerCase(),
    );
    if (exists) {
      setState(() {
        _tagsCtrl.clear();
      });
      return;
    }

    setState(() {
      _tags.add(normalized);
      _tagsCtrl.clear();
    });
  }

  void _removeTag(String tagToRemove) {
    setState(() {
      _tags.removeWhere(
        (tag) => tag.toLowerCase() == tagToRemove.toLowerCase(),
      );
    });
  }

  List<String> _buildTagsForSave() {
    final tags = List<String>.from(_tags);
    final pendingTag = _normalizeTag(_tagsCtrl.text);
    if (pendingTag == null) {
      return tags;
    }

    final exists = tags.any(
      (tag) => tag.toLowerCase() == pendingTag.toLowerCase(),
    );
    if (!exists) {
      tags.add(pendingTag);
    }

    return tags;
  }

  void _mergeExtractedTags(List<String> extractedTags) {
    for (final tag in extractedTags) {
      final normalized = _normalizeTag(tag);
      if (normalized == null) {
        continue;
      }

      final exists = _tags.any(
        (existing) => existing.toLowerCase() == normalized.toLowerCase(),
      );
      if (!exists) {
        _tags.add(normalized);
      }
    }
  }

  String? _normalizeTag(String rawTag) {
    final normalized = rawTag.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  int get _remainingFileSlots {
    return widget.documentsService.currentMaxFilesPerDocument -
        _displayFiles.length;
  }

  void _showFileLimitSnackBar({required int availableSlots}) {
    final t = AppLocalizations.of(context);
    final maxFiles = widget.documentsService.currentMaxFilesPerDocument;

    final message = availableSlots <= 0
        ? (t?.documentsMaxFilesReached(maxFiles) ??
              'This document already has the maximum of $maxFiles files.')
        : (t?.documentsMaxFilesRemaining(availableSlots, maxFiles) ??
              'You can only add $availableSlots more files. Maximum: $maxFiles per document.');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _filesCountLabel(AppLocalizations? t, int count) {
  return t?.documentsFilesCount(count) ?? '$count files';
}

enum _DocumentSource { camera, gallery, files }

class _DisplayDocumentFile {
  const _DisplayDocumentFile({
    required this.id,
    required this.fileName,
    required this.fileExtension,
    required this.mimeType,
    required this.type,
    required this.fileSizeBytes,
    required this.payload,
  });

  final String id;
  final String fileName;
  final String? fileExtension;
  final String? mimeType;
  final MedicalDocumentType type;
  final int fileSizeBytes;
  final Uint8List payload;
}

class _FilesInfoCard extends StatelessWidget {
  const _FilesInfoCard({
    required this.files,
    required this.selectedIndex,
    required this.onSelected,
    required this.pageController,
    required this.onPageChanged,
    required this.filesSummary,
    required this.addFilesLabel,
    required this.removeFileLabel,
    required this.onAddFiles,
    required this.onRemoveFile,
  });

  final List<_DisplayDocumentFile> files;
  final int selectedIndex;
  final void Function(int index) onSelected;
  final PageController pageController;
  final void Function(int index) onPageChanged;
  final String filesSummary;
  final String addFilesLabel;
  final String removeFileLabel;
  final VoidCallback? onAddFiles;
  final VoidCallback? onRemoveFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filesSummary,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: files.isEmpty
                ? const Center(
                    child: Icon(Icons.insert_drive_file_outlined, size: 48),
                  )
                : PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return _FilePreview(file: file);
                    },
                  ),
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final isSelected = selectedIndex == index;
                  return ChoiceChip(
                    label: Text(file.fileName, overflow: TextOverflow.ellipsis),
                    selected: isSelected,
                    onSelected: (_) => onSelected(index),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: files.length,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddFiles,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(addFilesLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemoveFile,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: Text(removeFileLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.file});

  final _DisplayDocumentFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (file.type == MedicalDocumentType.image && file.payload.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(file.payload, fit: BoxFit.cover),
      );
    }

    final icon = switch (file.type) {
      MedicalDocumentType.pdf => Icons.picture_as_pdf_outlined,
      MedicalDocumentType.docx => Icons.article_outlined,
      MedicalDocumentType.xlsx => Icons.table_chart_outlined,
      MedicalDocumentType.image => Icons.image_outlined,
      MedicalDocumentType.other => Icons.description_outlined,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: 8),
          Text(
            file.fileName,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedFileDetails extends StatelessWidget {
  const _SelectedFileDetails({
    required this.file,
    required this.typeLabel,
    required this.sizeLabel,
  });

  final _DisplayDocumentFile file;
  final String typeLabel;
  final String sizeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            file.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$typeLabel • $sizeLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if ((file.mimeType ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              file.mimeType!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExtractionReviewCard extends StatelessWidget {
  const _ExtractionReviewCard({
    required this.result,
    required this.canImport,
    required this.isImporting,
    required this.onImport,
  });

  final DocumentExtractionResult result;
  final bool canImport;
  final bool isImporting;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidenceLabel = '${(result.confidence * 100).toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extraction Review',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Document type: ${result.documentType.isEmpty ? 'Unknown' : result.documentType}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'Issuer: ${result.issuerName.isEmpty ? 'Unknown' : result.issuerName}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'Medical: ${result.isMedical ? 'Yes' : 'No'} • Confidence: $confidenceLabel',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            result.summary.isEmpty ? 'No summary extracted.' : result.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Medications: ${result.metadata.medications.length} • '
            'Lab Results: ${result.metadata.labResults.length} • '
            'Allergies: ${result.metadata.allergies.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (canImport) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onImport,
                icon: isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_add_check_outlined),
                label: Text(
                  isImporting
                      ? 'Importing...'
                      : 'Review and Add to Medical Records',
                ),
              ),
            ),
          ],
          if (result.requiresUserConfirmation) ...[
            const SizedBox(height: 6),
            Text(
              'Review and edit fields above, then confirm with Save.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExtractionImportSelection {
  const _ExtractionImportSelection({
    required this.medicationIndexes,
    required this.labResultIndexes,
    required this.allergyIndexes,
    required this.diagnosisIndexes,
    required this.vaccinationIndexes,
  });

  final Set<int> medicationIndexes;
  final Set<int> labResultIndexes;
  final Set<int> allergyIndexes;
  final Set<int> diagnosisIndexes;
  final Set<int> vaccinationIndexes;

  int get selectedCount =>
      medicationIndexes.length +
      labResultIndexes.length +
      allergyIndexes.length +
      diagnosisIndexes.length +
      vaccinationIndexes.length;
}

class _ExtractionImportBottomSheet extends StatefulWidget {
  const _ExtractionImportBottomSheet({required this.result});

  final DocumentExtractionResult result;

  @override
  State<_ExtractionImportBottomSheet> createState() =>
      _ExtractionImportBottomSheetState();
}

class _ExtractionImportBottomSheetState
    extends State<_ExtractionImportBottomSheet> {
  late Set<int> _selectedMedications;
  late Set<int> _selectedLabResults;
  late Set<int> _selectedAllergies;
  late Set<int> _selectedDiagnoses;
  late Set<int> _selectedVaccinations;

  @override
  void initState() {
    super.initState();
    final metadata = widget.result.metadata;
    _selectedMedications = _allIndexes(metadata.medications.length);
    _selectedLabResults = _allIndexes(metadata.labResults.length);
    _selectedAllergies = _allIndexes(metadata.allergies.length);
    _selectedDiagnoses = _allIndexes(metadata.diagnoses.length);
    _selectedVaccinations = _allIndexes(metadata.vaccinations.length);
  }

  Set<int> _allIndexes(int length) {
    return Set<int>.from(List<int>.generate(length, (index) => index));
  }

  int get _selectedCount =>
      _selectedMedications.length +
      _selectedLabResults.length +
      _selectedAllergies.length +
      _selectedDiagnoses.length +
      _selectedVaccinations.length;

  void _toggleSelection(Set<int> selection, int index, bool enabled) {
    setState(() {
      if (enabled) {
        selection.add(index);
      } else {
        selection.remove(index);
      }
    });
  }

  void _clearAllSelections() {
    setState(() {
      _selectedMedications.clear();
      _selectedLabResults.clear();
      _selectedAllergies.clear();
      _selectedDiagnoses.clear();
      _selectedVaccinations.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.result.metadata;
    final theme = Theme.of(context);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Extracted Medical Data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select what you want to add to your Medical Info and Lab Results.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildSection(
                      title: 'Medications',
                      items: metadata.medications,
                      selected: _selectedMedications,
                      itemLabelBuilder: _medicationLabel,
                    ),
                    _buildSection(
                      title: 'Lab Results',
                      items: metadata.labResults,
                      selected: _selectedLabResults,
                      itemLabelBuilder: _labResultLabel,
                      itemDetailsBuilder: _labResultDetails,
                    ),
                    _buildSection(
                      title: 'Allergies',
                      items: metadata.allergies,
                      selected: _selectedAllergies,
                      itemLabelBuilder: _allergyLabel,
                    ),
                    _buildSection(
                      title: 'Diagnoses',
                      items: metadata.diagnoses,
                      selected: _selectedDiagnoses,
                      itemLabelBuilder: _diagnosisLabel,
                    ),
                    _buildSection(
                      title: 'Vaccinations',
                      items: metadata.vaccinations,
                      selected: _selectedVaccinations,
                      itemLabelBuilder: _vaccinationLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAllSelections,
                      child: const Text('Clear Selection'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          _ExtractionImportSelection(
                            medicationIndexes: _selectedMedications,
                            labResultIndexes: _selectedLabResults,
                            allergyIndexes: _selectedAllergies,
                            diagnosisIndexes: _selectedDiagnoses,
                            vaccinationIndexes: _selectedVaccinations,
                          ),
                        );
                      },
                      child: Text('Import Selected ($_selectedCount)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection<T>({
    required String title,
    required List<T> items,
    required Set<int> selected,
    required String Function(T item) itemLabelBuilder,
    Widget? Function(T item)? itemDetailsBuilder,
  }) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${items.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < items.length; index++)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: selected.contains(index),
                    onChanged: (value) =>
                        _toggleSelection(selected, index, value == true),
                    title: Text(itemLabelBuilder(items[index])),
                  ),
                  if (itemDetailsBuilder != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 42, bottom: 8),
                      child: itemDetailsBuilder(items[index]),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _labResultDetails(LabResultExtractionInfo labResult) {
    final theme = Theme.of(context);
    final values = labResult.normalizedValues;
    final details = <String>[];

    if (labResult.category.trim().isNotEmpty) {
      details.add('Category: ${labResult.category.trim()}');
    }
    if (labResult.testDate != null) {
      details.add('Date: ${DateFormat.yMMMd().format(labResult.testDate!)}');
    }
    if (labResult.notes.trim().isNotEmpty) {
      details.add('Notes: ${labResult.notes.trim()}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final detail in details)
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (values.isNotEmpty) ...[
          Text(
            'Values:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final value in values)
            Text(
              _labValueLine(value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }

  String _labValueLine(LabResultValueExtractionInfo value) {
    final valueParts = <String>[
      '${value.name}: ${value.value}',
      if (value.unit.trim().isNotEmpty) value.unit.trim(),
    ];

    final min = value.minRange.trim();
    final max = value.maxRange.trim();
    final range = (min.isNotEmpty || max.isNotEmpty)
        ? 'Range: $min - $max'
        : null;

    return range == null
        ? valueParts.join(' ')
        : '${valueParts.join(' ')} ($range)';
  }

  String _medicationLabel(MedicationExtractionInfo medication) {
    if (medication.dosage.isEmpty) {
      return medication.name;
    }

    return '${medication.name} (${medication.dosage})';
  }

  String _labResultLabel(LabResultExtractionInfo labResult) {
    final valuesCount = labResult.normalizedValues.length;
    if (valuesCount <= 0) {
      return labResult.testName;
    }

    return '${labResult.testName} ($valuesCount value${valuesCount == 1 ? '' : 's'})';
  }

  String _allergyLabel(AllergyExtractionInfo allergy) {
    if (allergy.reaction.isEmpty) {
      return allergy.allergen;
    }

    return '${allergy.allergen} - ${allergy.reaction}';
  }

  String _diagnosisLabel(DiagnosisExtractionInfo diagnosis) {
    if (diagnosis.code.isEmpty) {
      return diagnosis.name;
    }

    return '${diagnosis.name} (${diagnosis.code})';
  }

  String _vaccinationLabel(VaccinationExtractionInfo vaccination) {
    final count = vaccination.dates.length;
    if (count <= 1) {
      return vaccination.name;
    }

    return '${vaccination.name} ($count doses)';
  }
}
