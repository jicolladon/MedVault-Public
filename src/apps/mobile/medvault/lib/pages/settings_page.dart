import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/di/service_locator.dart';
import '../utils/biometric_auth.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/medvault_page_header.dart';
import 'landing_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  BiometricAvailabilityStatus _biometricAvailability =
      BiometricAvailabilityStatus.unavailable;
  bool _darkModeEnabled = false;
  bool _useBiometric = false;
  bool _pushNotificationsEnabled = true;
  bool _loading = true;
  bool _deletingAllData = false;

  ServiceLocator get _locator => ServiceLocator.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometricAvailability = await BiometricAuth().checkAvailability();
    final biometric = await _locator.settingsService.getUseBiometric();
    final darkModeEnabled =
        _locator.themeController.mode.value == ThemeMode.dark;
    final notificationsService = _locator.notificationsService;

    await notificationsService.initialize();
    final notificationSettings = notificationsService.settings;
    final pushNotificationsEnabled = notificationSettings.pushEnabled;

    final bool isBiometricAvailable =
        biometricAvailability == BiometricAvailabilityStatus.available;

    if (!isBiometricAvailable && biometric) {
      await _locator.settingsService.setUseBiometric(false);
    }

    setState(() {
      _biometricAvailability = biometricAvailability;
      _darkModeEnabled = darkModeEnabled;
      _useBiometric = isBiometricAvailable && biometric;
      _pushNotificationsEnabled = pushNotificationsEnabled;
      _loading = false;
    });
  }

  Future<void> _onDarkModeToggle(bool newVal) async {
    await _locator.themeController.toggleDarkMode(newVal);

    if (!mounted) {
      return;
    }

    setState(() {
      _darkModeEnabled = _locator.themeController.mode.value == ThemeMode.dark;
    });
  }

  Future<void> _onBiometricToggle(bool newVal) async {
    if (!newVal) {
      final t = AppLocalizations.of(context);
      final ok = await BiometricAuth().authenticate(
        reason:
            t?.confirmDisableBiometric ??
            'Confirm disabling biometric authentication',
      );

      if (!ok) {
        return;
      }
    }

    await _locator.settingsService.setUseBiometric(newVal);
    setState(() {
      _useBiometric = newVal;
    });
  }

  Future<void> _onPushNotificationsToggle(bool newVal) async {
    final notificationsService = _locator.notificationsService;
    final updatedSettings = notificationsService.settings.copyWith(
      pushEnabled: newVal,
    );

    await notificationsService.updateSettings(updatedSettings);
    if (!mounted) {
      return;
    }

    setState(() {
      _pushNotificationsEnabled = notificationsService.settings.pushEnabled;
    });
  }

  String _getBiometricUnavailableReason(AppLocalizations? t) {
    switch (_biometricAvailability) {
      case BiometricAvailabilityStatus.unsupported:
        return t?.biometricUnavailableNoHardware ??
            'This device does not support biometric authentication.';
      case BiometricAvailabilityStatus.notEnrolled:
        return t?.biometricUnavailableNotEnrolled ??
            'No biometric data is enrolled on this device.';
      case BiometricAvailabilityStatus.unavailable:
        return t?.biometricUnavailableUnknown ??
            'Biometric availability could not be verified on this device.';
      case BiometricAvailabilityStatus.available:
        return t?.onboardingBiometricFaster ?? 'Faster and more secure';
    }
  }

  Widget _buildBiometricWarning(AppLocalizations? t) {
    if (_biometricAvailability == BiometricAvailabilityStatus.available) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t?.biometricUnavailableTitle ?? 'Biometric login unavailable',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getBiometricUnavailableReason(t),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String label) {
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t?.comingSoon(label) ?? '$label is coming soon')),
    );
  }

  Future<void> _confirmAndDeleteAllData() async {
    if (_deletingAllData) {
      return;
    }

    final t = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            t?.deleteAllDataDialogTitle ??
                'Delete all your local data permanently?',
          ),
          content: Text(
            t?.deleteAllDataDialogMessage ??
                'This action cannot be undone. All locally stored medical '
                    'records, settings, and cached files will be deleted '
                    'permanently and cannot be restored.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE7000B),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                t?.deleteAllDataConfirmAction ?? 'Delete Permanently',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _deletingAllData = true;
    });

    try {
      await _locator.settingsService.deleteAllData();
      await _locator.authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t?.deleteAllDataError ??
                'We could not delete your data. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingAllData = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _locator.authService.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _navRow({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final rowColor = color ?? theme.colorScheme.onSurface;
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon, size: 18, color: rowColor.withValues(alpha: 0.9)),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: rowColor,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: rowColor.withValues(alpha: 0.85),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    if (_loading) {
      return Center(child: LoadingSpinner(semanticLabel: t?.loadingInProgress));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: t?.settings ?? 'Settings',
            leading: canPop
                ? IconButton(
                    tooltip: t?.onboardingBack,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  )
                : null,
          ),
          Expanded(
            child: ListView(
              children: [
                _sectionCard(
                  title: t?.theme ?? 'Theme',
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.dark_mode_outlined,
                            size: 20,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t?.darkMode ?? 'Dark Mode',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                Text(
                                  'Reduce eye strain in low-light environments',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            key: const Key('settings_dark_mode_switch'),
                            value: _darkModeEnabled,
                            onChanged: _onDarkModeToggle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _sectionCard(
                  title: t?.securityAndPrivacy ?? 'Security & Privacy',
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 20,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t?.onboardingEnableBiometricLock ??
                                      'Biometric Login',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                Text(
                                  t?.onboardingBiometricFaster ??
                                      'Faster and more secure',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value:
                                _biometricAvailability ==
                                    BiometricAvailabilityStatus.available
                                ? _useBiometric
                                : false,
                            onChanged:
                                _biometricAvailability ==
                                    BiometricAvailabilityStatus.available
                                ? _onBiometricToggle
                                : null,
                          ),
                        ],
                      ),
                    ),
                    _buildBiometricWarning(t),
                  ],
                ),
                _sectionCard(
                  title: t?.notificationsSectionTitle ?? 'Notifications',
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 20,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t?.onboardingPushNotifications ??
                                      'Push Notifications',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                Text(
                                  t?.onboardingPushNotificationsSubtext ??
                                      'Important alerts and reminders',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _pushNotificationsEnabled,
                            onChanged: _onPushNotificationsToggle,
                            activeTrackColor: const Color(0xFF06B6D4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _sectionCard(
                  title: t?.legalAndSupport ?? 'Legal & Support',
                  children: [
                    _navRow(
                      icon: Icons.description_outlined,
                      label: t?.termsOfService ?? 'Terms of Service',
                      onTap: () => _showComingSoon(
                        t?.termsOfService ?? 'Terms of Service',
                      ),
                    ),
                    _navRow(
                      icon: Icons.privacy_tip_outlined,
                      label: t?.privacyPolicy ?? 'Privacy Policy',
                      onTap: () =>
                          _showComingSoon(t?.privacyPolicy ?? 'Privacy Policy'),
                    ),
                    _navRow(
                      icon: Icons.help_outline,
                      label: t?.helpAndSupport ?? 'Help & Support',
                      onTap: () => _showComingSoon(
                        t?.helpAndSupport ?? 'Help & Support',
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: const Color(0xFFFFC9C9)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t?.dangerZone ?? 'Danger Zone',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFE7000B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.25,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            foregroundColor: const Color(0xFFE7000B),
                          ),
                          onPressed: _deletingAllData
                              ? null
                              : _confirmAndDeleteAllData,
                          icon: _deletingAllData
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: LoadingSpinner(
                                    size: 18,
                                    strokeWidth: 2,
                                    color: const Color(0xFFE7000B),
                                    semanticLabel: t?.loadingInProgress,
                                  ),
                                )
                              : const Icon(Icons.delete_outline),
                          label: Text(
                            _deletingAllData
                                ? (t?.deleteAllDataDeleting ?? 'Deleting...')
                                : (t?.deleteAllData ?? 'Delete All Data'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<bool>(
                  future: _locator.authService.hasValidSession(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.25,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleSignOut,
                          icon: const Icon(Icons.logout, size: 18),
                          label: Text(t?.signOut ?? 'Log Out'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Column(
                    children: [
                      Text(
                        t?.medVaultVersionMvp ?? 'MedVault v1.0.0 MVP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        t?.copyrightCompliance ??
                            '© 2026 MedVault. HIPAA & GDPR Compliant.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                        textAlign: TextAlign.center,
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
  }
}
