import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/documents_models.dart';
import '../../services/documents_service.dart';
import '../../widgets/medvault_page_header.dart';
import '../document_detail_page.dart';
import 'lab_results_manual_add_page.dart';

class LabResultsAddSelectionPage extends StatelessWidget {
  const LabResultsAddSelectionPage({super.key});

  Future<void> _openManualEntry(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LabResultsManualAddPage()));
  }

  void _showExtractionDisabled(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.documentsExtractionDisabledInSettings)),
    );
  }

  Future<void> _openUploadAndExtract(BuildContext context) async {
    final documentsService = ServiceLocator.instance.documentsService;
    if (!documentsService.documentExtractDataEnabled) {
      _showExtractionDisabled(context);
      return;
    }

    final source = await _selectSource(context);
    if (source == null || !context.mounted) {
      return;
    }

    final drafts = await _pickDraftsFromSource(
      context: context,
      source: source,
      documentsService: documentsService,
    );
    if (drafts == null || drafts.isEmpty || !context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          documentsService: documentsService,
          uploadDrafts: drafts,
        ),
      ),
    );
  }

  Future<_LabDocumentSource?> _selectSource(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    return showModalBottomSheet<_LabDocumentSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                t.documentsSelectSourceTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.camera),
              onTap: () => Navigator.of(context).pop(_LabDocumentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.documentsFromGallery),
              onTap: () =>
                  Navigator.of(context).pop(_LabDocumentSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(t.selectFromFiles),
              onTap: () => Navigator.of(context).pop(_LabDocumentSource.files),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<DocumentUploadDraft>?> _pickDraftsFromSource({
    required BuildContext context,
    required _LabDocumentSource source,
    required DocumentsService documentsService,
  }) async {
    final t = AppLocalizations.of(context)!;
    final imagePicker = ImagePicker();

    try {
      switch (source) {
        case _LabDocumentSource.camera:
          final image = await imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: 90,
          );
          if (image == null) {
            return null;
          }

          final bytes = await image.readAsBytes();
          return [
            documentsService.createDraft(
              payload: bytes,
              fileName: image.name.isNotEmpty
                  ? image.name
                  : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
              mimeType: 'image/jpeg',
            ),
          ];
        case _LabDocumentSource.gallery:
          final image = await imagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 90,
          );
          if (image == null) {
            return null;
          }

          final bytes = await image.readAsBytes();
          return [
            documentsService.createDraft(
              payload: bytes,
              fileName: image.name.isNotEmpty
                  ? image.name
                  : 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
              mimeType: 'image/jpeg',
            ),
          ];
        case _LabDocumentSource.files:
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
              documentsService.createDraft(
                payload: bytes,
                fileName: selected.name,
                mimeType: _inferMimeType(selected.name),
              ),
            );
          }

          if (drafts.isEmpty) {
            if (!context.mounted) {
              return null;
            }

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(t.documentsUploadFailed)));
            return null;
          }

          if (drafts.length > documentsService.currentMaxFilesPerDocument) {
            if (!context.mounted) {
              return null;
            }

            final maxFiles = documentsService.currentMaxFilesPerDocument;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.documentsMaxFilesSelectionLimit(maxFiles)),
              ),
            );
            return null;
          }

          return drafts;
      }
    } catch (_) {
      if (!context.mounted) {
        return null;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.documentsUploadFailed)));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final canPop = Navigator.of(context).canPop();
    final documentsService = ServiceLocator.instance.documentsService;
    final canUploadAndExtract = documentsService.documentExtractDataEnabled;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: t.addLabResultTitle,
            leading: canPop
                ? IconButton(
                    tooltip: t.onboardingBack,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  )
                : null,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.chooseHowToAddYourLabResults,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.labResultsAddDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _AddOptionCard(
                  icon: Icons.description_outlined,
                  iconBackground: const Color(0xFFDFF8FF),
                  iconColor: const Color(0xFF0EA5E9),
                  title: t.manualEntry,
                  description: t.manualEntryDetails,
                  onTap: () => _openManualEntry(context),
                ),
                if (canUploadAndExtract) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _AddOptionCard(
                    icon: Icons.document_scanner_outlined,
                    iconBackground: const Color(0xFFF2E9FF),
                    iconColor: const Color(0xFF9333EA),
                    title: t.uploadAndExtract,
                    description: t.uploadAndExtractDetails,
                    onTap: () => _openUploadAndExtract(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _LabDocumentSource { camera, gallery, files }

class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AddOptionCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = description.split('\n');

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: iconBackground,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.first,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final line in details.skip(1))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                line,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
