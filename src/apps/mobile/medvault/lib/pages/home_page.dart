import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../core/di/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/documents_models.dart';
import '../utils/biometric_auth.dart';
import '../widgets/loading_spinner.dart';
import 'document_detail_page.dart';
import 'medical/lab_results_add_selection_page.dart';
import 'documents_page.dart';
import 'dashboard_page.dart';
import 'sharing_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _authenticated = false;
  bool _checkingAuth = true;
  final ImagePicker _imagePicker = ImagePicker();
  late final List<ScrollController> _tabScrollControllers = List.generate(
    5,
    (_) => ScrollController(),
  );
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(scrollController: _tabScrollControllers[0]),
      DocumentsPage(scrollController: _tabScrollControllers[1]),
      SharingPage(scrollController: _tabScrollControllers[2]),
      NotificationsPage(scrollController: _tabScrollControllers[3]),
      ProfilePage(scrollController: _tabScrollControllers[4]),
    ];
    _initializeStartupServices();
    _checkBiometricAuth();
  }

  Future<void> _initializeStartupServices() async {
    try {
      await ServiceLocator.instance.sharingService.initialize();
    } on Exception catch (error, stackTrace) {
      debugPrint(
        'Failed to initialize sharing configuration at app startup: '
        '$error\n$stackTrace',
      );
    }

    try {
      await ServiceLocator.instance.notificationsService.initialize();
    } on Exception catch (error, stackTrace) {
      debugPrint(
        'Failed to initialize notifications at app startup: '
        '$error\n$stackTrace',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _tabScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkBiometricAuth() async {
    final useBiometric = await ServiceLocator.instance.settingsService
        .getUseBiometric();

    if (useBiometric) {
      final biometric = BiometricAuth();
      final isAvailable = await biometric.isBiometricAvailable;

      if (isAvailable) {
        if (!mounted) return;
        final authenticated = await biometric.authenticate(
          reason:
              AppLocalizations.of(context)?.authenticationRequired ??
              'Authentication required',
          allowDeviceCredential: true,
        );

        if (!mounted) return;
        setState(() {
          _authenticated = authenticated;
          _checkingAuth = false;
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _authenticated = true;
      _checkingAuth = false;
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      _scrollCurrentTabToTop(index);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _scrollCurrentTabToTop(int index) {
    final controller = _tabScrollControllers[index];
    if (!controller.hasClients) {
      return;
    }

    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  List<_DashboardQuickAction> _dashboardQuickActions(AppLocalizations? t) {
    return [
      _DashboardQuickAction(
        id: 'add_document',
        label: t?.addNewDocument ?? 'Add New Document',
        icon: Icons.upload_file_outlined,
        onPressed: _showAddDocumentDialog,
      ),
      _DashboardQuickAction(
        id: 'add_lab_result',
        label: t?.addNewLabResult ?? 'Add New Lab Test Result',
        icon: Icons.science_outlined,
        onPressed: _showAddLabResultDialog,
      ),
    ];
  }

  Future<void> _openDashboardQuickActions(AppLocalizations? t) async {
    final actions = _dashboardQuickActions(t);
    final selectedActionId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                t?.quickActions ?? 'Quick Actions',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ...actions.map(
              (action) => ListTile(
                leading: Icon(action.icon),
                title: Text(action.label),
                onTap: () => Navigator.of(context).pop(action.id),
              ),
            ),
          ],
        ),
      ),
    );

    final selectedAction = actions
        .where((action) => action.id == selectedActionId)
        .firstOrNull;
    if (selectedAction == null) {
      return;
    }

    await selectedAction.onPressed();
  }

  Future<void> _showAddDocumentDialog() async {
    final t = AppLocalizations.of(context);
    final source = await showModalBottomSheet<_HomeDocumentSource>(
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
              onTap: () =>
                  Navigator.of(context).pop(_HomeDocumentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t?.documentsFromGallery ?? 'Gallery'),
              onTap: () =>
                  Navigator.of(context).pop(_HomeDocumentSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(t?.selectFromFiles ?? 'Select from files'),
              onTap: () => Navigator.of(context).pop(_HomeDocumentSource.files),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) {
      return;
    }

    final draft = await _pickDocumentDraft(source);
    if (draft == null || !mounted) {
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          documentsService: ServiceLocator.instance.documentsService,
          uploadDrafts: [draft],
        ),
      ),
    );

    if (created != true || !mounted) {
      return;
    }

    setState(() {
      _selectedIndex = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t?.documentCreatedSuccessfully ?? 'Document created successfully',
        ),
      ),
    );
  }

  Future<DocumentUploadDraft?> _pickDocumentDraft(
    _HomeDocumentSource source,
  ) async {
    final t = AppLocalizations.of(context);
    final documentsService = ServiceLocator.instance.documentsService;

    try {
      switch (source) {
        case _HomeDocumentSource.camera:
          final image = await _imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: 90,
          );
          if (image == null) {
            return null;
          }

          final payload = await image.readAsBytes();
          return documentsService.createDraft(
            payload: payload,
            fileName: image.name.isNotEmpty
                ? image.name
                : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
            mimeType: 'image/jpeg',
          );
        case _HomeDocumentSource.gallery:
          final image = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 90,
          );
          if (image == null) {
            return null;
          }

          final payload = await image.readAsBytes();
          return documentsService.createDraft(
            payload: payload,
            fileName: image.name.isNotEmpty
                ? image.name
                : 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
            mimeType: 'image/jpeg',
          );
        case _HomeDocumentSource.files:
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
          );

          if (result == null || result.files.isEmpty) {
            return null;
          }

          final file = result.files.first;
          if (file.bytes == null) {
            return null;
          }

          return documentsService.createDraft(
            payload: file.bytes!,
            fileName: file.name,
            mimeType: _inferMimeType(file.name),
          );
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

  Future<void> _showAddLabResultDialog() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LabResultsAddSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingSpinner(
                semanticLabel: AppLocalizations.of(context)?.loadingInProgress,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.authenticationRequired ??
                    'Authentication required',
              ),
            ],
          ),
        ),
      );
    }

    if (!_authenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.authenticationRequired ??
                    'Authentication required',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _checkingAuth = true;
                  });
                  _checkBiometricAuth();
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  AppLocalizations.of(context)?.authenticate ?? 'Authenticate',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: null,
        body: IndexedStack(index: _selectedIndex, children: _pages),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
                onPressed: () => _openDashboardQuickActions(t),
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  color: theme.colorScheme.onPrimaryContainer,
                );
              }

              return IconThemeData(color: theme.colorScheme.onSurfaceVariant);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: theme.colorScheme.surface,
            indicatorColor: theme.colorScheme.primaryContainer,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: t?.home ?? 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.description_outlined),
                selectedIcon: const Icon(Icons.description),
                label: t?.documents ?? 'Documents',
              ),
              NavigationDestination(
                icon: const Icon(Icons.share_outlined),
                selectedIcon: const Icon(Icons.share),
                label: t?.share ?? 'Share',
              ),
              NavigationDestination(
                icon: const Icon(Icons.notifications_outlined),
                selectedIcon: const Icon(Icons.notifications),
                label: t?.alerts ?? 'Alerts',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: t?.profile ?? 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardQuickAction {
  final String id;
  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;

  const _DashboardQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

enum _HomeDocumentSource { camera, gallery, files }
