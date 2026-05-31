import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/scheduler.dart';

import '../core/di/service_locator.dart';
import '../core/theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../models/documents_models.dart';
import '../services/documents_service.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/medvault_page_header.dart';
import 'document_detail_page.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchCtrl = TextEditingController();

  late final DocumentsService _documentsService;
  String _searchQuery = '';
  bool _rebuildScheduled = false;

  List<MedicalDocument> get _filteredDocuments {
    final query = _searchQuery.trim().toLowerCase();
    final t = AppLocalizations.of(context);
    if (query.isEmpty) {
      return _documentsService.documents;
    }

    return _documentsService.documents
        .where((doc) {
          final title = doc.title.toLowerCase();
          final description = (doc.description ?? '').toLowerCase();
          final fileNames = doc.files
              .map((file) => file.fileName.toLowerCase())
              .join(' ');
          final category = doc.category.name.toLowerCase();
          final localizedCategory = _docCategoryLabel(
            t,
            doc.category,
          ).toLowerCase();
          final tags = doc.tags.join(' ').toLowerCase();
          return title.contains(query) ||
              description.contains(query) ||
              fileNames.contains(query) ||
              category.contains(query) ||
              localizedCategory.contains(query) ||
              tags.contains(query);
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _documentsService = ServiceLocator.instance.documentsService;
    _documentsService.addListener(_onServiceChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    await _documentsService.initialize();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _documentsService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) {
      return;
    }

    final phase = WidgetsBinding.instance.schedulerPhase;
    final isBuilding =
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.persistentCallbacks;

    if (!isBuilding) {
      setState(() {});
      return;
    }

    if (_rebuildScheduled) {
      return;
    }

    _rebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  Future<void> _openCreateFlow() async {
    final t = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_DocumentSource>(
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

    if (source == null) {
      return;
    }

    final drafts = await _pickDraftsFromSource(source);
    if (drafts == null || drafts.isEmpty || !mounted) {
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          documentsService: _documentsService,
          uploadDrafts: drafts,
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t?.documentCreatedSuccessfully ?? 'Document created successfully',
          ),
        ),
      );
    }
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
            _documentsService.createDraft(
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
            _documentsService.createDraft(
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
              _documentsService.createDraft(
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

          if (drafts.length > _documentsService.currentMaxFilesPerDocument) {
            if (!mounted) {
              return null;
            }

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_maxFilesLimitMessage(t))));
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

  String _maxFilesLimitMessage(AppLocalizations? t) {
    final maxFiles = _documentsService.currentMaxFilesPerDocument;
    return t?.documentsMaxFilesSelectionLimit(maxFiles) ??
        'You can select up to $maxFiles files per document.';
  }

  Future<void> _openEditPage(MedicalDocument document) async {
    final t = AppLocalizations.of(context);
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          documentsService: _documentsService,
          existingDocument: document,
        ),
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t?.documentsUpdatedSuccessfully ?? 'Document updated successfully',
          ),
        ),
      );
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

  Future<void> _shareDocument(MedicalDocument document) async {
    final t = AppLocalizations.of(context);
    final files = await _documentsService.exportDocumentToTempFiles(
      document.id,
    );
    if (files.isEmpty) {
      return;
    }

    try {
      await Share.shareXFiles(
        files.map((file) => XFile(file.path)).toList(growable: false),
        text: document.title,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t?.documentsShareFailed ?? 'Failed to share document'),
        ),
      );
    }
  }

  Future<void> _openWithSystem(MedicalDocument document) async {
    final t = AppLocalizations.of(context);
    final file = await _documentsService.exportDocumentToTempFile(document.id);
    if (file == null) {
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
  }

  Future<void> _deleteDocument(MedicalDocument document) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t?.documentsDeleteDialogTitle ?? 'Delete document?'),
        content: Text(
          t?.documentsDeleteDialogMessage(document.title) ??
              'Are you sure you want to delete ${document.title}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(t?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _documentsService.deleteDocument(document.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t?.documentsDeletedSuccessfully ?? 'Document deleted successfully',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final docs = _filteredDocuments;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: t?.documents ?? 'Documents',
            trailing: IconButton(
              tooltip: t?.addNewDocument ?? 'Add New Document',
              onPressed: _openCreateFlow,
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          Expanded(
            child: LoadingOverlay(
              isLoading: _documentsService.isLoading && docs.isNotEmpty,
              semanticLabel: t?.loadingInProgress,
              child: ListView(
                controller: widget.scrollController,
                padding: AppSpacing.pagePadding,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText:
                          t?.documentsSearchPlaceholder ?? 'Search documents',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_documentsService.isLoading && docs.isEmpty)
                    Center(
                      child: LoadingSpinner(
                        semanticLabel: t?.loadingInProgress,
                      ),
                    )
                  else if (docs.isEmpty)
                    _EmptyDocumentsState(onAddPressed: _openCreateFlow)
                  else
                    ...docs.map((doc) {
                      final color = _docTypeColor(doc.type);
                      final categoryColor = _docCategoryColor(doc.category);
                      final description = (doc.description ?? '').trim();
                      final detailsLine =
                          '${_docTypeLabel(t, doc.type)} • ${_documentsService.formatFileSize(doc.fileSizeBytes)} • ${_filesCountLabel(t, doc.files.length)}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            14,
                            10,
                            8,
                            10,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(_docTypeIcon(doc.type), color: color),
                          ),
                          title: Text(
                            doc.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _CategoryTagPill(
                                    label: _docCategoryLabel(t, doc.category),
                                    color: categoryColor,
                                  ),
                                  Text(
                                    detailsLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              if (doc.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: doc.tags
                                        .map((tag) => _SmallTagPill(label: tag))
                                        .toList(growable: false),
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<_DocumentAction>(
                            onSelected: (action) {
                              switch (action) {
                                case _DocumentAction.edit:
                                  _openEditPage(doc);
                                  break;
                                case _DocumentAction.share:
                                  _shareDocument(doc);
                                  break;
                                case _DocumentAction.open:
                                  _openWithSystem(doc);
                                  break;
                                case _DocumentAction.delete:
                                  _deleteDocument(doc);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<_DocumentAction>(
                                value: _DocumentAction.edit,
                                child: Text(t?.edit ?? 'Edit'),
                              ),
                              PopupMenuItem<_DocumentAction>(
                                value: _DocumentAction.share,
                                child: Text(t?.share ?? 'Share'),
                              ),
                              PopupMenuItem<_DocumentAction>(
                                value: _DocumentAction.open,
                                child: Text(
                                  t?.documentsOpenWithApp ?? 'Open with app',
                                ),
                              ),
                              PopupMenuItem<_DocumentAction>(
                                value: _DocumentAction.delete,
                                child: Text(t?.delete ?? 'Delete'),
                              ),
                            ],
                          ),
                          onTap: () => _openEditPage(doc),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _filesCountLabel(AppLocalizations? t, int count) {
  return t?.documentsFilesCount(count) ?? '$count files';
}

enum _DocumentSource { camera, gallery, files }

enum _DocumentAction { edit, share, open, delete }

class _EmptyDocumentsState extends StatelessWidget {
  const _EmptyDocumentsState({required this.onAddPressed});

  final Future<void> Function() onAddPressed;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.description_outlined, size: 36),
          const SizedBox(height: 10),
          Text(
            t?.documentsEmptyTitle ?? 'No documents yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t?.documentsEmptySubtitle ??
                'Upload your first medical document to get started.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              onAddPressed();
            },
            icon: const Icon(Icons.add),
            label: Text(t?.addNewDocument ?? 'Add New Document'),
          ),
        ],
      ),
    );
  }
}

IconData _docTypeIcon(MedicalDocumentType type) {
  switch (type) {
    case MedicalDocumentType.pdf:
      return Icons.picture_as_pdf_outlined;
    case MedicalDocumentType.image:
      return Icons.image_outlined;
    case MedicalDocumentType.docx:
      return Icons.article_outlined;
    case MedicalDocumentType.xlsx:
      return Icons.table_chart_outlined;
    case MedicalDocumentType.other:
      return Icons.description_outlined;
  }
}

Color _docTypeColor(MedicalDocumentType type) {
  switch (type) {
    case MedicalDocumentType.pdf:
      return const Color(0xFFDC2626);
    case MedicalDocumentType.image:
      return const Color(0xFF2563EB);
    case MedicalDocumentType.docx:
      return const Color(0xFF059669);
    case MedicalDocumentType.xlsx:
      return const Color(0xFF0F766E);
    case MedicalDocumentType.other:
      return const Color(0xFF6B7280);
  }
}

Color _docCategoryColor(MedicalDocumentCategory category) {
  switch (category) {
    case MedicalDocumentCategory.labResults:
      return const Color(0xFF0F766E);
    case MedicalDocumentCategory.medicalReport:
      return const Color(0xFF2563EB);
    case MedicalDocumentCategory.medicationReport:
      return const Color(0xFF9333EA);
    case MedicalDocumentCategory.vaccinations:
      return const Color(0xFFEA580C);
    case MedicalDocumentCategory.other:
      return const Color(0xFF6B7280);
  }
}

String _docTypeLabel(AppLocalizations? t, MedicalDocumentType type) {
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

String _docCategoryLabel(
  AppLocalizations? t,
  MedicalDocumentCategory category,
) {
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

class _CategoryTagPill extends StatelessWidget {
  const _CategoryTagPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SmallTagPill extends StatelessWidget {
  const _SmallTagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
