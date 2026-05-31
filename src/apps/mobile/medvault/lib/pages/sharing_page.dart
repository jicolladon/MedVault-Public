import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/di/service_locator.dart';
import '../core/theme/app_spacing.dart';
import '../models/documents_models.dart';
import '../l10n/app_localizations.dart';
import '../models/sharing_models.dart';
import '../services/connectivity_service.dart';
import '../services/documents_service.dart';
import '../services/sharing_service.dart';
import '../services/sharing_email_launcher.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/medvault_page_header.dart';

String resolveSharingActionErrorMessage(
  Object error, {
  required String fallback,
}) {
  final message = error is StateError ? error.message : error.toString();

  final cleaned = message
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '')
      .trim();

  if (cleaned.isEmpty) {
    return fallback;
  }

  return cleaned;
}

enum _QrDownloadFormat {
  png;

  String get extension => 'png';

  String get displayName => extension.toUpperCase();
}

Future<Uint8List> _generateQrImageBytes({
  required String payload,
  required _QrDownloadFormat format,
}) async {
  final painter = QrPainter(
    data: payload,
    version: QrVersions.auto,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Color(0xFF111827),
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Color(0xFF111827),
    ),
    gapless: true,
  );

  final byteData = await painter.toImageData(
    1024,
    format: ui.ImageByteFormat.png,
  );
  if (byteData == null) {
    throw StateError('Unable to render QR image bytes.');
  }

  final pngBytes = byteData.buffer.asUint8List();
  if (format == _QrDownloadFormat.png) {
    return pngBytes;
  }

  final decoded = img.decodePng(pngBytes);
  if (decoded == null) {
    throw StateError('Unable to decode generated PNG QR data.');
  }

  final jpgBytes = img.encodeJpg(decoded, quality: 92);
  return Uint8List.fromList(jpgBytes);
}

Future<String> _saveTemporaryQrPngForSharing({
  required String qrPayload,
  required String shareCode,
}) async {
  final bytes = await _generateQrImageBytes(
    payload: qrPayload,
    format: _QrDownloadFormat.png,
  );
  final tempDirectory = await getTemporaryDirectory();
  await tempDirectory.create(recursive: true);

  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final normalizedCode = shareCode.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );
  final fileName = 'medvault_share_qr_${normalizedCode}_$timestamp.png';
  final file = File(path.join(tempDirectory.path, fileName));
  await file.writeAsBytes(bytes, flush: true);

  return file.path;
}

class SharingPage extends StatefulWidget {
  const SharingPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<SharingPage> createState() => _SharingPageState();
}

class _SharingPageState extends State<SharingPage> with WidgetsBindingObserver {
  late final SharingService _sharingService;
  ConnectivityService? _connectivityService;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sharingService = ServiceLocator.instance.sharingService;
    try {
      _connectivityService = ServiceLocator.instance.connectivityService;
    } catch (_) {
      _connectivityService = null;
    }
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sharingService.initialize();
    }
  }

  Future<void> _initialize() async {
    await _sharingService.initialize();
    if (!mounted) {
      return;
    }

    setState(() {
      _initializing = false;
    });
  }

  Future<void> _openEmergencyFlow() async {
    if (_connectivityService?.isOffline == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This action requires internet. You are currently offline.',
            ),
          ),
        );
      }
      return;
    }

    final t = AppLocalizations.of(context);
    if (_sharingService.hasReachedSharingLinksLimit) {
      if (!mounted) {
        return;
      }

      final maxLinks = _sharingService.maxSharingLinksPerUser;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            maxLinks == 0
                ? (t?.sharingLinkCreationDisabledInSettings ??
                      'Sharing link creation is disabled in your settings.')
                : (t?.sharingMaxActiveLinksReached(maxLinks) ??
                      'You have reached the maximum of $maxLinks active sharing links. Revoke one to continue.'),
          ),
        ),
      );
      return;
    }

    if (!_sharingService.emergencySharingEnabled) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t?.emergencySharingDisabledInSettings ??
                'Emergency sharing is disabled in your settings.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EmergencySharingConfigurationPage(sharingService: _sharingService),
      ),
    );

    await _sharingService.initialize();
  }

  Future<void> _openPhysicianFlow() async {
    if (_connectivityService?.isOffline == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This action requires internet. You are currently offline.',
            ),
          ),
        );
      }
      return;
    }

    final t = AppLocalizations.of(context);
    if (_sharingService.hasReachedSharingLinksLimit) {
      if (!mounted) {
        return;
      }

      final maxLinks = _sharingService.maxSharingLinksPerUser;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            maxLinks == 0
                ? (t?.sharingLinkCreationDisabledInSettings ??
                      'Sharing link creation is disabled in your settings.')
                : (t?.sharingMaxActiveLinksReached(maxLinks) ??
                      'You have reached the maximum of $maxLinks active sharing links. Revoke one to continue.'),
          ),
        ),
      );
      return;
    }

    if (!_sharingService.physicianSharingEnabled) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t?.sharingPhysicianDisabledInSettings ??
                'Physician sharing is disabled in your settings.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PhysicianSharingConfigurationPage(sharingService: _sharingService),
      ),
    );

    await _sharingService.initialize();
  }

  Future<void> _openManageLinksDialog() async {
    await _sharingService.initialize();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => ManageLinksDialog(sharingService: _sharingService),
    );

    await _sharingService.initialize();
  }

  Future<void> _openActivityLog() async {
    await _sharingService.initialize();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharingActivityLogPage(sharingService: _sharingService),
      ),
    );

    await _sharingService.initialize();
  }

  Future<void> _openPendingApprovalsDialog() async {
    if (_connectivityService?.isOffline == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pending approvals require internet access.'),
          ),
        );
      }
      return;
    }

    await _sharingService.refreshPendingApprovals();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) =>
          PendingTwoFactorApprovalsDialog(sharingService: _sharingService),
    );

    await _sharingService.refreshPendingApprovals();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _sharingService,
        ...?(_connectivityService == null ? null : [_connectivityService!]),
      ]),
      builder: (context, _) {
        final isOffline = _connectivityService?.isOffline ?? false;
        final links = _sharingService.links;
        final summary = _sharingService.summary;
        final featureSettings = _sharingService.featureSettings;
        final activeLinksCount = _sharingService.activeLinksCount;
        final pendingApprovalsCount = _sharingService.pendingApprovals.length;
        final hasReachedSharingLinksLimit =
            _sharingService.hasReachedSharingLinksLimit;
        final maxSharingLinksPerUser = _sharingService.maxSharingLinksPerUser;
        final sharingDisabledByLimit = maxSharingLinksPerUser == 0;
        final emergencyStatus = featureSettings.emergencySharingEnabled
            ? (t?.sharingPreferenceEnabled ?? 'Enabled')
            : (t?.sharingPreferenceDisabled ?? 'Disabled');
        final physicianStatus = featureSettings.physicianSharingEnabled
            ? (t?.sharingPreferenceEnabled ?? 'Enabled')
            : (t?.sharingPreferenceDisabled ?? 'Disabled');

        return LoadingOverlay(
          isLoading: _initializing,
          semanticLabel: t?.loadingInProgress,
          message: t?.loadingInProgress,
          child: ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.zero,
            children: [
              MedVaultPageHeader(
                title: t?.share ?? 'Share',
                subtitle:
                    t?.sharingManageDataAccessSubtitle ?? 'Manage data access',
              ),
              if (isOffline)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Offline mode: existing links remain visible. '
                      'Creating links and approval actions are unavailable.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t?.sharingPreferencesTitle ??
                                  'Sharing preferences',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              t?.sharingPreferencesSummary(
                                    emergencyStatus,
                                    physicianStatus,
                                    maxSharingLinksPerUser,
                                    activeLinksCount,
                                    featureSettings.maxDocumentsToShare,
                                  ) ??
                                  'Emergency: ${featureSettings.emergencySharingEnabled ? 'Enabled' : 'Disabled'} • Physician: ${featureSettings.physicianSharingEnabled ? 'Enabled' : 'Disabled'} • Max links: $maxSharingLinksPerUser • Active links: $activeLinksCount • Max docs: ${featureSettings.maxDocumentsToShare}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              t?.sharingManagedByApiConfiguration ??
                                  'Managed by API configuration',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 176,
                            child: _quickActionCard(
                              context,
                              title:
                                  t?.sharingEmergencyQrTitle ?? 'Emergency QR',
                              subtitle:
                                  t?.sharingQuickAccessSubtitle ??
                                  'Quick access',
                              icon: Icons.qr_code_2,
                              colors: const [
                                Color(0xFFFF2D55),
                                Color(0xFFFF6A00),
                              ],
                              onTap:
                                  featureSettings.emergencySharingEnabled &&
                                      !hasReachedSharingLinksLimit &&
                                      !isOffline
                                  ? _openEmergencyFlow
                                  : null,
                              enabled:
                                  featureSettings.emergencySharingEnabled &&
                                  !hasReachedSharingLinksLimit &&
                                  !isOffline,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SizedBox(
                            height: 176,
                            child: _quickActionCard(
                              context,
                              title:
                                  t?.sharingWithPhysicianTitle ??
                                  'Share with Physician',
                              subtitle:
                                  t?.sharingSecureSharingSubtitle ??
                                  'Secure sharing',
                              icon: Icons.person_add_alt_1,
                              colors: const [
                                Color(0xFF00B8DB),
                                Color(0xFF00BBA7),
                              ],
                              onTap:
                                  featureSettings.physicianSharingEnabled &&
                                      !hasReachedSharingLinksLimit &&
                                      !isOffline
                                  ? _openPhysicianFlow
                                  : null,
                              enabled:
                                  featureSettings.physicianSharingEnabled &&
                                  !hasReachedSharingLinksLimit &&
                                  !isOffline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasReachedSharingLinksLimit)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Card(
                          color: theme.colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    sharingDisabledByLimit
                                        ? (t?.sharingLinkCreationDisabledBySystemConfiguration ??
                                              'Sharing link creation is disabled by system configuration.')
                                        : (t?.sharingReachedMaxActiveLinksInAccessManagement(
                                                maxSharingLinksPerUser,
                                              ) ??
                                              'You reached the maximum of $maxSharingLinksPerUser active sharing links. Revoke one in Access Management to create a new link.'),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _openManageLinksDialog,
                                  child: Text(
                                    t?.sharingManageButton ?? 'Manage',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  t?.sharingActiveSharesTitle ??
                                      'Active Shares',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Chip(label: Text('${summary.active}')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (links.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: Text(
                                  t?.sharingNoActiveSharesMessage ??
                                      'No active sharing links yet.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            else
                              ...links
                                  .take(3)
                                  .map(
                                    (link) => _linkPreviewTile(
                                      context,
                                      link,
                                      onTap: _openManageLinksDialog,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t?.sharingManageAccessTitle ?? 'Manage Access',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.manage_accounts_outlined,
                              ),
                              title: Text(
                                t?.sharingAccessManagementLabel ??
                                    'Access Management',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _openManageLinksDialog,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.shield_outlined),
                              title: Text(
                                t?.sharingActivityLogLabel ?? 'Activity Log',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _openActivityLog,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.verified_user_outlined),
                              title: Text(
                                t?.sharingPendingAccessApprovalsTitle ??
                                    'Pending access approvals',
                              ),
                              subtitle: Text(
                                pendingApprovalsCount == 0
                                    ? (t?.sharingNoPendingRequests ??
                                          'No pending requests')
                                    : (t?.sharingWaitingRequests(
                                            pendingApprovalsCount,
                                          ) ??
                                          '$pendingApprovalsCount waiting requests'),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _openPendingApprovalsDialog,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        color: theme.colorScheme.primaryContainer,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t?.sharingPrivacyCardTitle ??
                                      'Your Control, Your Privacy',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  t?.sharingPrivacyCardDescription ??
                                      'You maintain full control over who can access your medical records. All access is logged and can be revoked at any time.',
                                  style: Theme.of(context).textTheme.bodyMedium,
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
            ],
          ),
        );
      },
    );
  }

  Widget _quickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: enabled ? onTap : null,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? colors
                : [
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                    Theme.of(context).colorScheme.surfaceContainer,
                  ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: enabled
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.surface,
                child: Icon(
                  icon,
                  color: enabled
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: enabled
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? Colors.white.withValues(alpha: 0.85)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkPreviewTile(
    BuildContext context,
    SharingLinkGrant link, {
    required VoidCallback onTap,
  }) {
    final t = AppLocalizations.of(context);
    final expires = _formatDate(link.expiresAt);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        link.targetName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _typeChip(context, link.type),
                  ],
                ),
                if ((link.targetEmail ?? '').isNotEmpty)
                  Text(
                    link.targetEmail!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  '${t?.sharingExpiresLabel ?? 'Expires'}: $expires',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(onPressed: onTap, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class EmergencySharingConfigurationPage extends StatefulWidget {
  const EmergencySharingConfigurationPage({
    super.key,
    required this.sharingService,
  });

  final SharingService sharingService;

  @override
  State<EmergencySharingConfigurationPage> createState() =>
      _EmergencySharingConfigurationPageState();
}

class _EmergencySharingConfigurationPageState
    extends State<EmergencySharingConfigurationPage> {
  late Set<SharingScope> _selectedScopes;
  Set<String> _selectedFileIds = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedScopes = {
      SharingScope.personalInformation,
      SharingScope.bloodType,
      SharingScope.allergies,
      SharingScope.medications,
      SharingScope.emergencyContact,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final maxSelectableFiles = widget.sharingService.maxDocumentsToShare;
    final options = [
      SharingScope.personalInformation,
      SharingScope.bloodType,
      SharingScope.allergies,
      SharingScope.emergencyContact,
      SharingScope.medications,
      SharingScope.diagnoses,
      SharingScope.vaccines,
      SharingScope.labResults,
    ];
    final criticalScopes = {
      SharingScope.bloodType,
      SharingScope.allergies,
      SharingScope.medications,
      SharingScope.emergencyContact,
    };

    return Scaffold(
      appBar: _gradientAppBar(
        context,
        title: t?.sharingEmergencySharingTitle ?? 'Emergency Sharing',
        subtitle:
            t?.sharingEmergencySharingSubtitle ??
            'Quick access for first responders',
        colors: const [Color(0xFFFF2D55), Color(0xFFFF6A00)],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    t?.sharingEmergencyWarningBody ??
                        'Anyone with the code or QR can access selected data. Only share in emergencies. All access is logged and you will be notified.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingSelectInformationTitle ??
                        'Select Information to Share',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t?.sharingEmergencySelectInformationSubtitle ??
                        'Choose what emergency responders can access',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...options.map((scope) {
                    final documentsDisabled =
                        scope == SharingScope.medicalDocuments &&
                        maxSelectableFiles == 0;
                    final selected =
                        !documentsDisabled && _selectedScopes.contains(scope);

                    return CheckboxListTile(
                      value: selected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      tileColor: selected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      title: Text(scope.label(context)),
                      subtitle: documentsDisabled
                          ? Text(
                              t?.sharingDocumentSharingDisabledInSettings ??
                                  'Document sharing is disabled in your settings.',
                            )
                          : _recommendedChipFor(criticalScopes, scope, context),
                      onChanged: documentsDisabled
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedScopes.add(scope);
                                } else {
                                  _selectedScopes.remove(scope);
                                  if (scope == SharingScope.medicalDocuments) {
                                    _selectedFileIds = <String>{};
                                  }
                                }
                              });
                            },
                    );
                  }),
                  if (_selectedScopes.contains(SharingScope.medicalDocuments))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          t?.sharingSelectedFilesCount(
                                _selectedFileIds.length,
                                maxSelectableFiles,
                              ) ??
                              'Selected files: ${_selectedFileIds.length}/$maxSelectableFiles',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        OutlinedButton.icon(
                          onPressed: maxSelectableFiles == 0
                              ? null
                              : _openFileSelection,
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text(
                            t?.sharingSelectFilesButton ?? 'Select Files',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.pagePadding,
        child: FilledButton(
          onPressed: _selectedScopes.isEmpty
              ? null
              : () {
                  if (_selectedScopes.contains(SharingScope.medicalDocuments) &&
                      _selectedFileIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t?.sharingSelectAtLeastOneMedicalDocument ??
                              'Select at least one file for Medical Documents sharing.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmergencySharingSecurityPage(
                        sharingService: widget.sharingService,
                        selectedScopes: _selectedScopes,
                        selectedFileIds: _selectedFileIds,
                      ),
                    ),
                  );
                },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: Text(t?.sharingContinueButton ?? 'Continue'),
        ),
      ),
    );
  }

  Widget? _recommendedChipFor(
    Set<SharingScope> criticalScopes,
    SharingScope scope,
    BuildContext context,
  ) {
    final t = AppLocalizations.of(context);

    if (!criticalScopes.contains(scope) &&
        scope != SharingScope.diagnoses &&
        scope != SharingScope.personalInformation) {
      return null;
    }

    return Wrap(
      spacing: 6,
      children: [
        Chip(
          visualDensity: VisualDensity.compact,
          label: Text(t?.sharingRecommendedBadge ?? 'Recommended'),
        ),
        if (criticalScopes.contains(scope))
          Chip(
            visualDensity: VisualDensity.compact,
            backgroundColor: Theme.of(context).colorScheme.error,
            label: Text(
              t?.sharingCriticalBadge ?? 'Critical',
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Future<void> _openFileSelection() async {
    final selected = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => SharingFileSelectionPage(
          initialSelectedFileIds: _selectedFileIds,
          maxSelectableFiles: widget.sharingService.maxDocumentsToShare,
        ),
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedFileIds = selected;
    });
  }
}

class EmergencySharingSecurityPage extends StatefulWidget {
  const EmergencySharingSecurityPage({
    super.key,
    required this.sharingService,
    required this.selectedScopes,
    required this.selectedFileIds,
  });

  final SharingService sharingService;
  final Set<SharingScope> selectedScopes;
  final Set<String> selectedFileIds;

  @override
  State<EmergencySharingSecurityPage> createState() =>
      _EmergencySharingSecurityPageState();
}

class _EmergencySharingSecurityPageState
    extends State<EmergencySharingSecurityPage> {
  late Duration _selectedDuration;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration = const Duration(hours: 1);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _gradientAppBar(
        context,
        title: t?.sharingEmergencySecurityTitle ?? 'Security Configuration',
        subtitle:
            t?.sharingEmergencySecuritySubtitle ??
            'Configure emergency link duration',
        colors: const [Color(0xFFFF2D55), Color(0xFFFF6A00)],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingAccessDurationTitle ?? 'Access Duration',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t?.sharingEmergencyDurationQuestion ??
                        'How long should the emergency code remain valid?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Duration>(
                    initialValue: _selectedDuration,
                    items: [
                      DropdownMenuItem(
                        value: Duration(hours: 1),
                        child: Text(t?.sharingDuration1Hour ?? '1 hour'),
                      ),
                      DropdownMenuItem(
                        value: Duration(hours: 6),
                        child: Text(t?.sharingDuration6Hours ?? '6 hours'),
                      ),
                      DropdownMenuItem(
                        value: Duration(hours: 12),
                        child: Text(t?.sharingDuration12Hours ?? '12 hours'),
                      ),
                      DropdownMenuItem(
                        value: Duration(hours: 24),
                        child: Text(t?.sharingDuration24Hours ?? '24 hours'),
                      ),
                      DropdownMenuItem(
                        value: Duration(days: 3),
                        child: Text(t?.sharingDuration3Days ?? '3 days'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedDuration = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingDataSummaryTitle ?? 'Data Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t?.sharingDataSummarySubtitle ??
                        'Information that will be accessible',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...widget.selectedScopes.map(
                    (scope) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(scope.label(context)),
                      trailing: _criticalBadgeIfNeeded(scope, context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
              color: theme.colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t?.sharingPrivacySecurityTitle ?? 'Privacy & Security',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t?.sharingSecurityBulletLogged ??
                      'All access attempts are logged',
                ),
                Text(
                  t?.sharingSecurityBulletNotified ??
                      'You will receive instant notifications',
                ),
                Text(
                  t?.sharingSecurityBulletRevoke ??
                      'You can revoke access anytime',
                ),
                Text(
                  t?.sharingSecurityBulletExpires ??
                      'Code expires automatically',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.pagePadding,
        child: FilledButton(
          onPressed: _creating
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() {
                    _creating = true;
                  });

                  try {
                    final link = await widget.sharingService
                        .createEmergencySharingLink(
                          scopes: widget.selectedScopes,
                          selectedFileIds: widget.selectedFileIds,
                          securitySettings: SharingSecuritySettings(
                            accessDuration: _selectedDuration,
                            notifyOnAccess: true,
                          ),
                        );

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => SharingCodeGenerationPage(
                          sharingService: widget.sharingService,
                          grant: link,
                        ),
                      ),
                    );
                  } on Exception catch (error) {
                    if (!context.mounted) {
                      return;
                    }

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          resolveSharingActionErrorMessage(
                            error,
                            fallback:
                                t?.error ?? 'Unable to complete this action.',
                          ),
                        ),
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _creating = false;
                      });
                    }
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE11D48),
          ),
          child: Text(
            _creating
                ? (t?.sharingGeneratingCodeButton ?? 'Generating code...')
                : (t?.sharingGenerateEmergencyCodeButton ??
                      'Generate Emergency Code'),
          ),
        ),
      ),
    );
  }

  Widget? _criticalBadgeIfNeeded(SharingScope scope, BuildContext context) {
    if (scope != SharingScope.bloodType &&
        scope != SharingScope.allergies &&
        scope != SharingScope.medications) {
      return null;
    }

    final t = AppLocalizations.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: Theme.of(context).colorScheme.error,
      label: Text(
        t?.sharingCriticalBadge ?? 'Critical',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class SharingCodeGenerationPage extends StatelessWidget {
  const SharingCodeGenerationPage({
    super.key,
    required this.sharingService,
    required this.grant,
  });

  final SharingService sharingService;
  final SharingLinkGrant grant;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    void backToSharingMainView() {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        backToSharingMainView();
      },
      child: Scaffold(
        appBar: _gradientAppBar(
          context,
          title: t?.sharingEmergencyCodeActiveTitle ?? 'Emergency Code Active',
          colors: const [Color(0xFFFF2D55), Color(0xFFFF6A00)],
          onBackPressed: backToSharingMainView,
        ),
        body: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
                color: theme.colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${t?.sharingEmergencyAccessActiveLabel ?? 'Emergency access is active'}\n${t?.sharingExpiresInLabel ?? 'Expires in'} ${_humanizeDuration(grant.expiresAt.difference(DateTime.now()))}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      t?.sharingScanQrCodeTitle ?? 'Scan QR Code',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t?.sharingScanQrCodeSubtitle ??
                          'First responders can scan this to access your info',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    QrImageView(
                      data: grant.qrPayload,
                      backgroundColor: Colors.white,
                      size: 220,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      t?.sharingUseCodeTitle ?? 'Or Use Code',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            t?.sharingEmergencyAccessCodeLabel ??
                                'Emergency Access Code',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            grant.shareCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${t?.sharingVisitAndEnterCodeText ?? 'Visit'} ${grant.shareUrl}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final qrImagePath = await _saveTemporaryQrPngForSharing(
                          qrPayload: grant.qrPayload,
                          shareCode: grant.shareCode,
                        );

                        final shareMessage =
                            '${t?.sharingVisitAndEnterCodeText ?? 'Visit and enter this code:'}\n${grant.shareUrl}\n\n${t?.sharingEmergencyAccessCodeLabel ?? 'Emergency Access Code'}: ${grant.shareCode}';

                        await Share.shareXFiles(
                          [
                            XFile(
                              qrImagePath,
                              mimeType: 'image/png',
                              name: path.basename(qrImagePath),
                            ),
                          ],
                          text: shareMessage,
                          subject:
                              t?.sharingEmergencyCodeActiveTitle ??
                              'Emergency Code Active',
                        );
                      } on Exception {
                        if (!context.mounted) {
                          return;
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              t?.error ??
                                  'Unable to open the share dialog right now.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: Text(t?.sharingShareButton ?? 'Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.35),
                ),
                color: theme.colorScheme.secondaryContainer,
              ),
              child: Text(
                t?.sharingEmergencyNotificationInfo ??
                    'You will be notified every time someone accesses your emergency information.',
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: backToSharingMainView,
                child: Text(t?.sharingDoneButton ?? 'Done'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await sharingService.revokeLink(linkId: grant.id);
                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } on Exception catch (error) {
                    if (!context.mounted) {
                      return;
                    }

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          resolveSharingActionErrorMessage(
                            error,
                            fallback:
                                t?.error ?? 'Unable to complete this action.',
                          ),
                        ),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                child: Text(
                  t?.sharingRevokeEmergencyAccessButton ??
                      'Revoke Emergency Access',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhysicianSharingConfigurationPage extends StatefulWidget {
  const PhysicianSharingConfigurationPage({
    super.key,
    required this.sharingService,
  });

  final SharingService sharingService;

  @override
  State<PhysicianSharingConfigurationPage> createState() =>
      _PhysicianSharingConfigurationPageState();
}

class _PhysicianSharingConfigurationPageState
    extends State<PhysicianSharingConfigurationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  late Set<SharingScope> _selectedScopes;
  Set<String> _selectedFileIds = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedScopes = {
      SharingScope.personalInformation,
      SharingScope.medicalInformation,
      SharingScope.allergies,
      SharingScope.medications,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final maxSelectableFiles = widget.sharingService.maxDocumentsToShare;
    final options = [
      SharingScope.personalInformation,
      SharingScope.medicalInformation,
      SharingScope.allergies,
      SharingScope.medications,
      SharingScope.diagnoses,
      SharingScope.vaccines,
      SharingScope.labResults,
      SharingScope.medicalDocuments,
    ];

    return Scaffold(
      appBar: _gradientAppBar(
        context,
        title: t?.sharingWithPhysicianTitle ?? 'Share with Physician',
        subtitle: t?.sharingWithPhysicianSubtitle ?? 'Secure provider access',
        colors: const [Color(0xFF00B8DB), Color(0xFF00BBA7)],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingPhysicianInformationTitle ??
                        'Physician Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText:
                          t?.sharingPhysicianNameLabel ?? 'Physician Name *',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText:
                          t?.sharingPhysicianEmailLabel ?? 'Email Address',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t?.sharingPhysicianEmailHelpText ??
                        'Optional. Add an email to include physician contact in the sharing record.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText:
                          t?.sharingNotesOptionalLabel ?? 'Notes (Optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingSelectDataToShareTitle ?? 'Select Data to Share',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t?.sharingSelectDataToShareSubtitle ??
                        'Choose what the physician can access',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...options.map((scope) {
                    final documentsDisabled =
                        scope == SharingScope.medicalDocuments &&
                        maxSelectableFiles == 0;
                    final selected =
                        !documentsDisabled && _selectedScopes.contains(scope);

                    return CheckboxListTile(
                      value: selected,
                      title: Text(scope.label(context)),
                      subtitle: documentsDisabled
                          ? Text(
                              t?.sharingDocumentSharingDisabledInSettings ??
                                  'Document sharing is disabled in your settings.',
                            )
                          : _recommendedScope(scope, context),
                      onChanged: documentsDisabled
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedScopes.add(scope);
                                } else {
                                  _selectedScopes.remove(scope);
                                  if (scope == SharingScope.medicalDocuments) {
                                    _selectedFileIds = <String>{};
                                  }
                                }
                              });
                            },
                    );
                  }),
                  if (_selectedScopes.contains(SharingScope.medicalDocuments))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          t?.sharingSelectedFilesCount(
                                _selectedFileIds.length,
                                maxSelectableFiles,
                              ) ??
                              'Selected files: ${_selectedFileIds.length}/$maxSelectableFiles',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        OutlinedButton.icon(
                          onPressed: maxSelectableFiles == 0
                              ? null
                              : _openFileSelection,
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text(
                            t?.sharingSelectFilesButton ?? 'Select Files',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.pagePadding,
        child: FilledButton(
          onPressed: _selectedScopes.isEmpty
              ? null
              : () {
                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                  if (name.isEmpty ||
                      (email.isNotEmpty && !emailRegex.hasMatch(email))) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t?.sharingPhysicianValidationMessage ??
                              'Please enter a valid physician name. If provided, email must be valid.',
                        ),
                      ),
                    );
                    return;
                  }

                  if (_selectedScopes.contains(SharingScope.medicalDocuments) &&
                      _selectedFileIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t?.sharingSelectAtLeastOneMedicalDocument ??
                              'Select at least one file for Medical Documents sharing.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PhysicianSharingSecurityPage(
                        sharingService: widget.sharingService,
                        draft: PhysicianSharingDraft(
                          physicianName: name,
                          physicianEmail: email.isEmpty ? null : email,
                          notes: _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                          scopes: _selectedScopes,
                          selectedFileIds: _selectedFileIds,
                        ),
                      ),
                    ),
                  );
                },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
          child: Text(
            t?.sharingContinueToSecuritySettingsButton ??
                'Continue to Security Settings',
          ),
        ),
      ),
    );
  }

  Widget? _recommendedScope(SharingScope scope, BuildContext context) {
    if (scope == SharingScope.medicalDocuments) {
      return null;
    }
    final t = AppLocalizations.of(context);

    return Wrap(
      spacing: 6,
      children: [
        Chip(
          visualDensity: VisualDensity.compact,
          label: Text(t?.sharingRecommendedBadge ?? 'Recommended'),
        ),
      ],
    );
  }

  Future<void> _openFileSelection() async {
    final selected = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => SharingFileSelectionPage(
          initialSelectedFileIds: _selectedFileIds,
          maxSelectableFiles: widget.sharingService.maxDocumentsToShare,
        ),
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedFileIds = selected;
    });
  }
}

class PhysicianSharingDraft {
  final String physicianName;
  final String? physicianEmail;
  final String? notes;
  final Set<SharingScope> scopes;
  final Set<String> selectedFileIds;

  const PhysicianSharingDraft({
    required this.physicianName,
    required this.physicianEmail,
    required this.notes,
    required this.scopes,
    this.selectedFileIds = const <String>{},
  });
}

class PhysicianSharingSecurityPage extends StatefulWidget {
  const PhysicianSharingSecurityPage({
    super.key,
    required this.sharingService,
    required this.draft,
  });

  final SharingService sharingService;
  final PhysicianSharingDraft draft;

  @override
  State<PhysicianSharingSecurityPage> createState() =>
      _PhysicianSharingSecurityPageState();
}

class _PhysicianSharingSecurityPageState
    extends State<PhysicianSharingSecurityPage> {
  Duration _duration = const Duration(days: 30);
  bool _passwordProtected = true;
  bool _requiresTwoFactor = false;
  final bool _allowDownload = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateSecurityInputs() {
    final t = AppLocalizations.of(context);
    if (_passwordProtected) {
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();
      if (password.isEmpty || confirmPassword.isEmpty) {
        return t?.sharingEnterAndConfirmPassword ??
            'Enter and confirm the access password.';
      }

      if (password.length < 8) {
        return t?.sharingPasswordMinRequirements ??
            'Password must be at least 8 characters long and include letters and numbers.';
      }

      final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
      final hasDigit = RegExp(r'\d').hasMatch(password);
      if (!hasLetter || !hasDigit) {
        return t?.sharingPasswordMinRequirements ??
            'Password must be at least 8 characters long and include letters and numbers.';
      }

      if (password != confirmPassword) {
        return t?.sharingPasswordMismatch ??
            'Password and confirmation do not match.';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _gradientAppBar(
        context,
        title: t?.sharingSecuritySettingsTitle ?? 'Security Settings',
        colors: const [Color(0xFF00B8DB), Color(0xFF00BBA7)],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingAccessDurationTitle ?? 'Access Duration',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Duration>(
                    initialValue: _duration,
                    items: [
                      DropdownMenuItem(
                        value: Duration(days: 1),
                        child: Text(t?.sharingDuration1Day ?? '1 day'),
                      ),
                      DropdownMenuItem(
                        value: Duration(days: 7),
                        child: Text(t?.sharingDuration7Days ?? '7 days'),
                      ),
                      DropdownMenuItem(
                        value: Duration(days: 30),
                        child: Text(t?.sharingDuration30Days ?? '30 days'),
                      ),
                      DropdownMenuItem(
                        value: Duration(days: 90),
                        child: Text(t?.sharingDuration90Days ?? '90 days'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _duration = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _passwordProtected,
                    title: Text(
                      t?.sharingPasswordProtectedLabel ?? 'Password Protected',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _passwordProtected = value;
                        if (!value) {
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        }
                      });
                    },
                  ),
                  if (_passwordProtected) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText:
                            '${t?.sharingAccessPasswordLabel ?? 'Access Password'} *',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText:
                            '${t?.sharingConfirmPasswordLabel ?? 'Confirm Password'} *',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t?.sharingPasswordConstraintsHelpText ??
                          'Use at least 8 characters with letters and numbers. Share it securely with the physician.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _requiresTwoFactor,
                    title: Text(
                      t?.sharingTwoFactorRequiredLabel ??
                          '2FA Approval Required',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _requiresTwoFactor = value;
                      });
                    },
                  ),
                  if (_requiresTwoFactor) ...[
                    Text(
                      t?.sharingTwoFactorApprovalDescription ??
                          'When enabled, access will remain pending until you approve or deny it in the app.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.pagePadding,
        child: FilledButton(
          onPressed: () {
            final validationMessage = _validateSecurityInputs();
            if (validationMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(validationMessage)));
              return;
            }

            final accessPassword = _passwordProtected
                ? _passwordController.text.trim()
                : null;

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PhysicianSharingReviewPage(
                  sharingService: widget.sharingService,
                  draft: widget.draft,
                  securitySettings: SharingSecuritySettings(
                    accessDuration: _duration,
                    passwordProtected: _passwordProtected,
                    requiresTwoFactorApproval: _requiresTwoFactor,
                    allowDownload: _allowDownload,
                    accessPassword: accessPassword,
                  ),
                ),
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
          child: Text(t?.sharingContinueButton ?? 'Continue'),
        ),
      ),
    );
  }
}

class PhysicianSharingReviewPage extends StatefulWidget {
  const PhysicianSharingReviewPage({
    super.key,
    required this.sharingService,
    required this.draft,
    required this.securitySettings,
    this.messageLauncher = const SharePlusSharingMessageLauncher(),
    this.patientNameProvider,
  });

  final SharingService sharingService;
  final PhysicianSharingDraft draft;
  final SharingSecuritySettings securitySettings;
  final SharingMessageLauncher messageLauncher;
  final Future<String?> Function()? patientNameProvider;

  @override
  State<PhysicianSharingReviewPage> createState() =>
      _PhysicianSharingReviewPageState();
}

class _PhysicianSharingReviewPageState
    extends State<PhysicianSharingReviewPage> {
  bool _consent = false;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _gradientAppBar(
        context,
        title: t?.sharingReviewAndConfirmTitle ?? 'Review & Confirm',
        colors: const [Color(0xFF00B8DB), Color(0xFF00BBA7)],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingWithLabel ?? 'Sharing With',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.draft.physicianName),
                  if ((widget.draft.physicianEmail ?? '').isNotEmpty)
                    Text(widget.draft.physicianEmail!),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingDataBeingSharedTitle ?? 'Data Being Shared',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...widget.draft.scopes.map(
                    (scope) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF16A34A),
                      ),
                      title: Text(scope.label(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.sharingSecuritySettingsTitle ?? 'Security Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _securityRow(
                    context,
                    t?.sharingAccessDurationLabel ?? 'Access Duration',
                    _durationLabel(widget.securitySettings.accessDuration),
                  ),
                  _securityRow(
                    context,
                    t?.sharingPasswordProtectedLabel ?? 'Password Protected',
                    widget.securitySettings.passwordProtected
                        ? (t?.sharingYesLabel ?? 'Yes')
                        : (t?.sharingNoLabel ?? 'No'),
                  ),
                  _securityRow(
                    context,
                    t?.sharingTwoFactorRequiredLabel ?? '2FA Approval Required',
                    widget.securitySettings.requiresTwoFactorApproval
                        ? (t?.sharingYesLabel ?? 'Yes')
                        : (t?.sharingNoLabel ?? 'No'),
                  ),
                  _securityRow(
                    context,
                    t?.sharingAllowDownloadLabel ?? 'Allow Download',
                    widget.securitySettings.allowDownload
                        ? (t?.sharingYesLabel ?? 'Yes')
                        : (t?.sharingNoLabel ?? 'No'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
              color: theme.colorScheme.primaryContainer,
            ),
            child: CheckboxListTile(
              value: _consent,
              contentPadding: EdgeInsets.zero,
              title: Text(
                t?.sharingConsentStatement ??
                    'I confirm that I consent to sharing my medical information and understand that all access will be logged and can be revoked at any time.',
              ),
              onChanged: (value) {
                setState(() {
                  _consent = value ?? false;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.pagePadding,
        child: FilledButton(
          onPressed: !_consent || _sending
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final approved = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(
                        t?.sharingConfirmationDialogTitle ?? 'Confirm Sharing',
                      ),
                      content: Text(
                        t?.sharingConfirmationDialogMessage ??
                            'Create and send the secure sharing link to this physician?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(t?.cancel ?? 'Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(t?.sharingConfirmButton ?? 'Confirm'),
                        ),
                      ],
                    ),
                  );

                  if (approved != true || !context.mounted) {
                    return;
                  }

                  setState(() {
                    _sending = true;
                  });

                  try {
                    final link = await widget.sharingService
                        .createPhysicianSharingLink(
                          physicianName: widget.draft.physicianName,
                          physicianEmail: widget.draft.physicianEmail,
                          notes: widget.draft.notes,
                          scopes: widget.draft.scopes,
                          selectedFileIds: widget.draft.selectedFileIds,
                          securitySettings: widget.securitySettings,
                        );

                    if (!context.mounted) {
                      return;
                    }

                    await _openSharingOptions(context: context, link: link);

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } on Exception {
                    if (!context.mounted) {
                      return;
                    }

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          t?.error ?? 'Unable to complete this action.',
                        ),
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _sending = false;
                      });
                    }
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
          child: Text(
            _sending
                ? (t?.sharingSendingLinkButton ?? 'Sending link...')
                : (t?.sharingConfirmAndSendButton ??
                      'Confirm & Send Share Link'),
          ),
        ),
      ),
    );
  }

  Future<void> _openSharingOptions({
    required BuildContext context,
    required SharingLinkGrant link,
  }) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final subject =
        t?.sharingPhysicianEmailSubject ??
        'MedVault secure medical information sharing';
    final intro =
        t?.sharingPhysicianEmailBodyIntro ??
        'Please use this secure MedVault link to review my shared medical information.';
    final patientLabel = t?.sharingPatientLabel ?? 'Patient';
    final accessDurationLabel =
        t?.sharingAccessDurationLabel ?? 'Access Duration';
    final dataBeingSharedLabel =
        t?.sharingDataBeingSharedTitle ?? 'Data Being Shared';
    final notesLabel = t?.notes ?? 'Notes';
    final instructions =
        t?.sharingPhysicianEmailBodyInstructions ??
        'This link is time-limited and intended only for this physician. Please avoid forwarding it.';
    final scopes = widget.draft.scopes
        .map((scope) => scope.label(context))
        .join(', ');

    final patientName = await _resolvePatientName(fallbackLabel: patientLabel);
    final body = _buildPhysicianShareBody(
      link: link,
      patientName: patientName,
      patientLabel: patientLabel,
      intro: intro,
      accessDurationLabel: accessDurationLabel,
      accessDurationValue: _durationLabel(
        widget.securitySettings.accessDuration,
      ),
      dataBeingSharedLabel: dataBeingSharedLabel,
      scopes: scopes,
      notesLabel: notesLabel,
      notes: widget.draft.notes,
      instructions: instructions,
    );

    final opened = await widget.messageLauncher.openShareSheet(
      SharingMessageRequest(subject: subject, body: body),
    );

    if (!context.mounted) {
      return;
    }

    if (opened) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t?.sharingEmailOpenedMessage ??
                'Email app opened with your sharing link.',
          ),
        ),
      );
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: link.shareUrl));
    } on Exception {
      // Clipboard may be unavailable on some environments (for example tests).
    }

    if (!context.mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          t?.sharingEmailFallbackCopiedMessage ??
              'Unable to open email app. Link copied to clipboard.',
        ),
      ),
    );
  }

  Future<String> _resolvePatientName({required String fallbackLabel}) async {
    final providedName = await widget.patientNameProvider?.call();
    final trimmedProvidedName = providedName?.trim();
    if (trimmedProvidedName != null && trimmedProvidedName.isNotEmpty) {
      return trimmedProvidedName;
    }

    final user = await ServiceLocator.instance.authService.getCurrentUser();
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return fallbackLabel;
  }

  String _buildPhysicianShareBody({
    required SharingLinkGrant link,
    required String patientName,
    required String patientLabel,
    required String intro,
    required String accessDurationLabel,
    required String accessDurationValue,
    required String dataBeingSharedLabel,
    required String scopes,
    required String notesLabel,
    required String? notes,
    required String instructions,
  }) {
    final lines = <String>[
      intro,
      '',
      '$patientLabel: $patientName',
      '',
      link.shareUrl,
      '',
      '$accessDurationLabel: $accessDurationValue',
      '$dataBeingSharedLabel: $scopes',
      if (notes != null && notes.isNotEmpty) '$notesLabel: $notes',
      '',
      instructions,
    ];

    return lines.join('\n');
  }

  Widget _securityRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text('$label:')),
          Chip(label: Text(value)),
        ],
      ),
    );
  }
}

class PendingTwoFactorApprovalsDialog extends StatefulWidget {
  const PendingTwoFactorApprovalsDialog({
    super.key,
    required this.sharingService,
  });

  final SharingService sharingService;

  @override
  State<PendingTwoFactorApprovalsDialog> createState() =>
      _PendingTwoFactorApprovalsDialogState();
}

class _PendingTwoFactorApprovalsDialogState
    extends State<PendingTwoFactorApprovalsDialog> {
  String? _processingRequestId;

  Future<void> _decide(
    PendingShareApprovalRequest request,
    bool approved,
  ) async {
    setState(() {
      _processingRequestId = request.requestId;
    });
    final t = AppLocalizations.of(context);

    try {
      if (approved) {
        await widget.sharingService.approvePendingApproval(
          requestId: request.requestId,
        );
      } else {
        await widget.sharingService.denyPendingApproval(
          requestId: request.requestId,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? (t?.sharingAccessApprovedFor(request.viewerName) ??
                      'Access approved for ${request.viewerName}.')
                : (t?.sharingAccessDeniedFor(request.viewerName) ??
                      'Access denied for ${request.viewerName}.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolveSharingActionErrorMessage(
              error,
              fallback:
                  t?.sharingUnableToUpdateApprovalRequest ??
                  'Unable to update approval request.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        t?.sharingPendingAccessApprovalsTitle ?? 'Pending access approvals',
      ),
      content: SizedBox(
        width: 520,
        child: AnimatedBuilder(
          animation: widget.sharingService,
          builder: (context, _) {
            final requests = widget.sharingService.pendingApprovals;
            if (requests.isEmpty) {
              return Text(
                t?.sharingNoPendingApprovalRequests ??
                    'There are no pending approval requests.',
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: requests
                    .map((request) {
                      final isProcessing =
                          _processingRequestId == request.requestId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.viewerName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${t?.sharingRequestedLabel ?? 'Requested'}: ${dateFormat.format(request.requestedAt.toLocal())}',
                              ),
                              Text(
                                '${t?.sharingExpiresLabel ?? 'Expires'}: ${dateFormat.format(request.expiresAt.toLocal())}',
                              ),
                              if ((request.viewerIpAddress ?? '').isNotEmpty)
                                Text(
                                  '${t?.sharingIpLabel ?? 'IP'}: ${request.viewerIpAddress}',
                                ),
                              if (request.shareCode.isNotEmpty)
                                Text(
                                  '${t?.sharingShareCodeLabel ?? 'Share code'}: ${request.shareCode}',
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _decide(request, true),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      label: Text(
                                        t?.sharingApproveButton ?? 'Approve',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _decide(request, false),
                                      icon: const Icon(Icons.block_outlined),
                                      label: Text(
                                        t?.sharingDenyButton ?? 'Deny',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t?.sharingCloseButton ?? 'Close'),
        ),
      ],
    );
  }
}

class ManageLinksDialog extends StatefulWidget {
  const ManageLinksDialog({super.key, required this.sharingService});

  final SharingService sharingService;

  @override
  State<ManageLinksDialog> createState() => _ManageLinksDialogState();
}

class _ManageLinksDialogState extends State<ManageLinksDialog> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AnimatedBuilder(
            animation: widget.sharingService,
            builder: (context, _) {
              final links = widget.sharingService.links;
              final summary = widget.sharingService.summary;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t?.sharingAccessManagementTitle ??
                              'Access Management',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCell(
                          context,
                          '${summary.active}',
                          t?.sharingSummaryActiveLabel ?? 'Active',
                        ),
                      ),
                      Expanded(
                        child: _summaryCell(
                          context,
                          '${summary.used}',
                          t?.sharingSummaryUsedLabel ?? 'Used',
                        ),
                      ),
                      Expanded(
                        child: _summaryCell(
                          context,
                          '${summary.expired}',
                          t?.sharingSummaryExpiredLabel ?? 'Expired',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: links.isEmpty
                        ? Center(
                            child: Text(
                              t?.sharingNoAccessGrantsMessage ??
                                  'No access grants available.',
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: links.length,
                            itemBuilder: (context, index) {
                              final link = links[index];
                              return Card(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              link.targetName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          _typeChip(context, link.type),
                                        ],
                                      ),
                                      if ((link.targetEmail ?? '').isNotEmpty)
                                        Text(link.targetEmail!),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '${t?.sharingGrantedLabel ?? 'Granted'}: ${_formatDate(link.createdAt)}  ${t?.sharingExpiresLabel ?? 'Expires'}: ${_formatDate(link.expiresAt)}',
                                      ),
                                      Text(
                                        '${t?.sharingLastAccessLabel ?? 'Last'}: ${link.lastAccessAt == null ? (t?.sharingNeverLabel ?? 'Never') : _formatDate(link.lastAccessAt!)}  ${t?.sharingPermissionsLabel ?? 'Perms'}: ${_shortPermissions(link.scopes)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              onPressed: link.revokedAt != null
                                                  ? null
                                                  : () async {
                                                      final messenger =
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          );
                                                      try {
                                                        await widget
                                                            .sharingService
                                                            .revokeLink(
                                                              linkId: link.id,
                                                            );
                                                      } on Exception {
                                                        if (!context.mounted) {
                                                          return;
                                                        }

                                                        messenger.showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              t?.error ??
                                                                  'Unable to complete this action.',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    theme.colorScheme.error,
                                              ),
                                              icon: const Icon(
                                                Icons.person_off_outlined,
                                              ),
                                              label: Text(
                                                t?.sharingRevokeAccessButton ??
                                                    'Revoke Access',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryCell(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label),
      ],
    );
  }
}

class PermissionUpdateResult {
  final Set<SharingScope> scopes;
  final SharingSecuritySettings securitySettings;

  const PermissionUpdateResult({
    required this.scopes,
    required this.securitySettings,
  });
}

class _EditPermissionsSheet extends StatefulWidget {
  const _EditPermissionsSheet({required this.link});

  final SharingLinkGrant link;

  @override
  State<_EditPermissionsSheet> createState() => _EditPermissionsSheetState();
}

class _EditPermissionsSheetState extends State<_EditPermissionsSheet> {
  late Set<SharingScope> _scopes;
  late Duration _duration;
  late bool _allowDownload;
  late bool _password;
  late bool _twoFactor;

  @override
  void initState() {
    super.initState();
    _scopes = widget.link.scopes.toSet();
    _duration = widget.link.securitySettings.accessDuration;
    _allowDownload = widget.link.securitySettings.allowDownload;
    _password = widget.link.securitySettings.passwordProtected;
    _twoFactor = widget.link.securitySettings.requiresTwoFactorApproval;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t?.sharingEditPermissionsTitle ?? 'Edit Permissions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SharingScope.values
                  .map(
                    (scope) => FilterChip(
                      selected: _scopes.contains(scope),
                      label: Text(scope.label(context)),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _scopes.add(scope);
                          } else {
                            _scopes.remove(scope);
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<Duration>(
              initialValue: _duration,
              items: [
                DropdownMenuItem(
                  value: Duration(hours: 1),
                  child: Text(t?.sharingDuration1Hour ?? '1 hour'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 1),
                  child: Text(t?.sharingDuration1Day ?? '1 day'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 7),
                  child: Text(t?.sharingDuration7Days ?? '7 days'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 30),
                  child: Text(t?.sharingDuration30Days ?? '30 days'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _duration = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _allowDownload,
              title: Text(t?.sharingAllowDownloadLabel ?? 'Allow Download'),
              onChanged: (value) {
                setState(() {
                  _allowDownload = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _password,
              title: Text(
                t?.sharingPasswordProtectedLabel ?? 'Password Protected',
              ),
              onChanged: (value) {
                setState(() {
                  _password = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _twoFactor,
              title: Text(
                t?.sharingTwoFactorRequiredLabel ?? '2FA Approval Required',
              ),
              onChanged: (value) {
                setState(() {
                  _twoFactor = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _scopes.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop(
                        PermissionUpdateResult(
                          scopes: _scopes,
                          securitySettings: SharingSecuritySettings(
                            accessDuration: _duration,
                            allowDownload: _allowDownload,
                            passwordProtected: _password,
                            requiresTwoFactorApproval: _twoFactor,
                          ),
                        ),
                      );
                    },
              child: Text(t?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class SharingActivityLogPage extends StatefulWidget {
  const SharingActivityLogPage({super.key, required this.sharingService});

  final SharingService sharingService;

  @override
  State<SharingActivityLogPage> createState() => _SharingActivityLogPageState();
}

class _SharingActivityLogPageState extends State<SharingActivityLogPage> {
  ActivityFilter _filter = ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _gradientAppBar(
        context,
        title: t?.sharingActivityLogTitle ?? 'Activity Log',
        subtitle: t?.sharingActivityLogSubtitle ?? 'Access & security events',
        colors: const [Color(0xFF00B8DB), Color(0xFF00BBA7)],
      ),
      body: AnimatedBuilder(
        animation: widget.sharingService,
        builder: (context, _) {
          final allEvents = widget.sharingService.activityLog;
          final events = allEvents
              .where((entry) {
                switch (_filter) {
                  case ActivityFilter.all:
                    return true;
                  case ActivityFilter.accessOnly:
                    return entry.type == SharingActivityType.linkAccessed;
                  case ActivityFilter.highRiskOnly:
                    return entry.highRisk;
                }
              })
              .toList(growable: false);

          return ListView(
            padding: AppSpacing.pagePadding,
            children: [
              DropdownButtonFormField<ActivityFilter>(
                initialValue: _filter,
                items: [
                  DropdownMenuItem(
                    value: ActivityFilter.all,
                    child: Text(t?.sharingAllEventsFilter ?? 'All Events'),
                  ),
                  DropdownMenuItem(
                    value: ActivityFilter.accessOnly,
                    child: Text(
                      t?.sharingAccessEventsFilter ?? 'Access Events',
                    ),
                  ),
                  DropdownMenuItem(
                    value: ActivityFilter.highRiskOnly,
                    child: Text(t?.sharingHighRiskFilter ?? 'High Risk'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _filter = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _metric(
                        context,
                        '${allEvents.where((entry) => entry.type == SharingActivityType.linkAccessed).length}',
                        t?.sharingSummaryAccessLabel ?? 'Access',
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        context,
                        '${widget.sharingService.highRiskEventsCount}',
                        t?.sharingSummaryHighRiskLabel ?? 'High Risk',
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        context,
                        t?.sharingSummaryPeriodValue ?? '7d',
                        t?.sharingSummaryPeriodLabel ?? 'Period',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t?.sharingActivityTimelineTitle ?? 'Activity Timeline',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (events.isEmpty)
                        Text(
                          t?.sharingNoActivityEventsMessage ??
                              'No activity events for this filter.',
                        )
                      else
                        ...events.map((event) => _eventTile(context, event)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t?.sharingExportComplianceTitle ??
                            'Export & Compliance',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t?.sharingExportPdfNotReadyMessage ??
                                    'PDF export will be connected in a future release.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: Text(
                          t?.sharingExportActivityPdfButton ??
                              'Export Activity Log (PDF)',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t?.sharingGdprExportNotReadyMessage ??
                                    'GDPR report export will be connected in a future release.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: Text(
                          t?.sharingExportGdprButton ??
                              'GDPR Data Portability Report',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metric(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _eventTile(BuildContext context, SharingActivityEntry event) {
    final Widget badge = event.highRisk
        ? Chip(
            visualDensity: VisualDensity.compact,
            backgroundColor: Theme.of(context).colorScheme.error,
            label: Text(
              AppLocalizations.of(context)?.sharingHighRiskFilter ??
                  'High Risk',
              style: const TextStyle(color: Colors.white),
            ),
          )
        : const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              event.highRisk ? Icons.error_outline : Icons.check_circle_outline,
              color: event.highRisk
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    badge,
                  ],
                ),
                Text(event.details),
                Text(
                  '${event.actorName} • ${_formatDate(event.occurredAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if ((event.location ?? '').isNotEmpty)
                  Text(
                    event.location!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if ((event.ipAddress ?? '').isNotEmpty)
                  Text(
                    '${AppLocalizations.of(context)?.sharingIpLabel ?? 'IP'}: ${event.ipAddress}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SharingFileSelectionPage extends StatefulWidget {
  const SharingFileSelectionPage({
    super.key,
    required this.initialSelectedFileIds,
    required this.maxSelectableFiles,
  });

  final Set<String> initialSelectedFileIds;
  final int maxSelectableFiles;

  @override
  State<SharingFileSelectionPage> createState() =>
      _SharingFileSelectionPageState();
}

class _SharingFileSelectionPageState extends State<SharingFileSelectionPage> {
  late final DocumentsService _documentsService;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  Set<String> _selectedFileIds = <String>{};
  MedicalDocumentCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _documentsService = ServiceLocator.instance.documentsService;
    _selectedFileIds = widget.initialSelectedFileIds
        .take(widget.maxSelectableFiles)
        .toSet();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _documentsService.initialize();
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems();
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: _gradientAppBar(
        context,
        title: t?.sharingSelectFilesToShareTitle ?? 'Select Files to Share',
        subtitle:
            t?.sharingChooseUpToFilesForLink(widget.maxSelectableFiles) ??
            'Choose up to ${widget.maxSelectableFiles} files for this link',
        colors: const [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText:
                              t?.sharingSearchFilesLabel ?? 'Search files',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<MedicalDocumentCategory?>(
                        initialValue: _categoryFilter,
                        decoration: InputDecoration(
                          labelText:
                              t?.sharingFilterByCategoryLabel ??
                              'Filter by category',
                        ),
                        items: [
                          DropdownMenuItem<MedicalDocumentCategory?>(
                            value: null,
                            child: Text(
                              t?.sharingAllCategories ?? 'All categories',
                            ),
                          ),
                          ...MedicalDocumentCategory.values.map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(_documentCategoryLabel(category)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _categoryFilter = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t?.sharingSelectedCount(
                                _selectedFileIds.length,
                                widget.maxSelectableFiles,
                              ) ??
                              'Selected: ${_selectedFileIds.length}/${widget.maxSelectableFiles}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            t?.sharingNoFilesMatchSearchFilter ??
                                'No files match your search/filter.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final selected = _selectedFileIds.contains(
                              item.fileId,
                            );
                            return CheckboxListTile(
                              value: selected,
                              title: Text(item.documentTitle),
                              subtitle: Text(
                                '${item.fileName} • ${_documentCategoryLabel(item.category)}',
                              ),
                              onChanged: widget.maxSelectableFiles == 0
                                  ? null
                                  : (value) {
                                      _toggleSelection(
                                        item.fileId,
                                        value == true,
                                      );
                                    },
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.pagePadding,
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedFileIds);
          },
          child: Text(t?.sharingApplySelectionButton ?? 'Apply Selection'),
        ),
      ),
    );
  }

  List<_ShareFileCandidate> _filteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    final items = _buildCandidates();
    return items
        .where((item) {
          if (_categoryFilter != null && item.category != _categoryFilter) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          final haystack =
              '${item.documentTitle} ${item.fileName} ${item.documentDescription ?? ''} ${item.category.name}'
                  .toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  List<_ShareFileCandidate> _buildCandidates() {
    final output = <_ShareFileCandidate>[];
    for (final document in _documentsService.documents) {
      for (final file in document.files) {
        output.add(
          _ShareFileCandidate(
            fileId: file.id,
            fileName: file.fileName,
            documentTitle: document.title,
            documentDescription: document.description,
            category: document.category,
          ),
        );
      }
    }

    return output;
  }

  void _toggleSelection(String fileId, bool selected) {
    if (selected &&
        !_selectedFileIds.contains(fileId) &&
        _selectedFileIds.length >= widget.maxSelectableFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can select up to ${widget.maxSelectableFiles} files.',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (selected) {
        _selectedFileIds = {..._selectedFileIds, fileId};
      } else {
        _selectedFileIds = _selectedFileIds.where((id) => id != fileId).toSet();
      }
    });
  }

  String _documentCategoryLabel(MedicalDocumentCategory category) {
    switch (category) {
      case MedicalDocumentCategory.labResults:
        return 'Lab Results';
      case MedicalDocumentCategory.medicalReport:
        return 'Medical Report';
      case MedicalDocumentCategory.medicationReport:
        return 'Medication Report';
      case MedicalDocumentCategory.vaccinations:
        return 'Vaccinations';
      case MedicalDocumentCategory.other:
        return 'Other';
    }
  }
}

class _ShareFileCandidate {
  const _ShareFileCandidate({
    required this.fileId,
    required this.fileName,
    required this.documentTitle,
    required this.documentDescription,
    required this.category,
  });

  final String fileId;
  final String fileName;
  final String documentTitle;
  final String? documentDescription;
  final MedicalDocumentCategory category;
}

enum ActivityFilter { all, accessOnly, highRiskOnly }

PreferredSizeWidget _gradientAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<Color> colors,
  VoidCallback? onBackPressed,
}) {
  return AppBar(
    leading: onBackPressed == null
        ? null
        : IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back),
          ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        if (subtitle != null)
          Text(subtitle, style: const TextStyle(fontSize: 14)),
      ],
    ),
    foregroundColor: Colors.white,
    flexibleSpace: Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
    ),
  );
}

Widget _typeChip(BuildContext context, SharingType type) {
  final isEmergency = type == SharingType.emergency;
  final colorScheme = Theme.of(context).colorScheme;

  return Chip(
    visualDensity: VisualDensity.compact,
    backgroundColor: isEmergency
        ? colorScheme.error
        : colorScheme.secondaryContainer,
    label: Text(
      isEmergency
          ? (AppLocalizations.of(context)?.sharingEmergencyTypeLabel ??
                'Emergency')
          : (AppLocalizations.of(context)?.sharingPhysicianTypeLabel ??
                'Physician'),
      style: TextStyle(
        color: isEmergency
            ? colorScheme.onError
            : colorScheme.onSecondaryContainer,
      ),
    ),
  );
}

String _shortPermissions(Set<SharingScope> scopes) {
  if (scopes.isEmpty) {
    return '-';
  }

  return scopes.map((scope) => scope.name).take(2).join(', ');
}

String _humanizeDuration(Duration duration) {
  if (duration.isNegative) {
    return 'expired';
  }

  if (duration.inHours < 24) {
    return '${duration.inHours}h';
  }

  return '${duration.inDays}d';
}

String _durationLabel(Duration duration) {
  if (duration.inHours < 24) {
    return '${duration.inHours}h';
  }

  return '${duration.inDays}d';
}

String _formatDate(DateTime date) {
  return DateFormat('M/d/yyyy, H:mm').format(date);
}

extension SharingScopeLabels on SharingScope {
  String label(BuildContext context) {
    final t = AppLocalizations.of(context);

    switch (this) {
      case SharingScope.personalInformation:
        return t?.sharingScopePersonalInformation ?? 'Personal Information';
      case SharingScope.medicalInformation:
        return t?.sharingScopeMedicalInformation ?? 'Medical Information';
      case SharingScope.bloodType:
        return t?.sharingScopeBloodType ?? 'Blood Type';
      case SharingScope.allergies:
        return t?.sharingScopeAllergies ?? 'Allergies';
      case SharingScope.medications:
        return t?.sharingScopeCurrentMedications ?? 'Current Medications';
      case SharingScope.diagnoses:
        return t?.diagnoses ?? 'Diagnoses';
      case SharingScope.vaccines:
        return t?.vaccines ?? 'Vaccines';
      case SharingScope.emergencyContact:
        return t?.sharingScopeEmergencyContact ?? 'Emergency Contact';
      case SharingScope.labResults:
        return t?.sharingScopeLabResults ?? 'Lab Results';
      case SharingScope.medicalDocuments:
        return t?.sharingScopeMedicalDocuments ?? 'Medical Documents';
      case SharingScope.medicalHistory:
        return t?.sharingScopeMedicalHistory ?? 'Medical History';
    }
  }
}
