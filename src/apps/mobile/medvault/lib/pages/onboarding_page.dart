import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/medical_models.dart';
import '../services/api/auth_api.dart';
import '../utils/biometric_auth.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

enum OnboardingStep { biometric, notifications, cloudSync, medical }

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  ServiceLocator get _locator => ServiceLocator.instance;

  BiometricAvailabilityStatus _biometricAvailability =
      BiometricAvailabilityStatus.unavailable;
  bool _biometricEnabled = false;
  final String _biometricType = 'System';

  bool _pushEnabled = true;

  final String _cloudProvider = 'MedVault';
  final bool _autoBackup = true;

  String? _bloodType;

  @override
  void initState() {
    super.initState();
    _loadBiometricAvailability();
  }

  Future<void> _loadBiometricAvailability() async {
    final BiometricAvailabilityStatus availability = await BiometricAuth()
        .checkAvailability();

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricAvailability = availability;
      _biometricEnabled = availability == BiometricAvailabilityStatus.available;
    });
  }

  List<OnboardingStep> get _activeSteps => const [
    OnboardingStep.biometric,
    OnboardingStep.notifications,
    OnboardingStep.medical,
  ];

  String _getStepTitle(AppLocalizations t, OnboardingStep step) {
    switch (step) {
      case OnboardingStep.biometric:
        return t.onboardingStepBiometricTitle;
      case OnboardingStep.notifications:
        return t.onboardingStepNotificationsTitle;
      case OnboardingStep.cloudSync:
        return t.onboardingStepCloudTitle;
      case OnboardingStep.medical:
        return t.onboardingStepMedicalTitle;
    }
  }

  String _getStepSubtitle(AppLocalizations t, OnboardingStep step) {
    switch (step) {
      case OnboardingStep.biometric:
        return t.onboardingStepBiometricSubtitle;
      case OnboardingStep.notifications:
        return t.onboardingStepNotificationsSubtitle;
      case OnboardingStep.cloudSync:
        return t.onboardingStepCloudSubtitle;
      case OnboardingStep.medical:
        return t.onboardingStepMedicalSubtitle;
    }
  }

  Future<void> _onStepContinue() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentStepType = _activeSteps[_currentStep];
      switch (currentStepType) {
        case OnboardingStep.biometric:
          await _locator.authService.saveBiometricConfig(
            biometricType: _biometricType,
            isEnabled: _biometricEnabled,
          );
          break;
        case OnboardingStep.notifications:
          await _locator.authService.saveNotificationPreferences(
            pushEnabled: _pushEnabled,
          );
          break;
        case OnboardingStep.cloudSync:
          await _locator.authService.enableCloudSync(
            provider: _cloudProvider,
            autoBackupEnabled: _autoBackup,
          );
          break;
        case OnboardingStep.medical:
          await _locator.authService.saveOnboardingMedicalInfo(
            bloodType: _bloodType,
          );
          break;
      }

      if (_currentStep >= _activeSteps.length - 1) {
        await _locator.authService.markOnboardingComplete();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
        return;
      }

      setState(() => _currentStep++);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = t?.onboardingErrorGeneric ?? t?.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _skipToHome() async {
    try {
      await _locator.authService.markOnboardingComplete();
    } catch (_) {
    }

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final int totalSteps = _activeSteps.length;
    final ThemeData theme = Theme.of(context);
    final double progress = ((_currentStep + 1) / totalSteps).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF06B6D4), Color(0xFF14B8A6)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      t.onboardingStepCounter(_currentStep + 1, totalSteps),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isLoading ? null : _skipToHome,
                      child: Text(t.onboardingSkip),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildStepContent(t, _activeSteps[_currentStep]),
                            if (_error != null) ...<Widget>[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _onStepCancel,
                          child: Text(t.onboardingBack),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _onStepContinue,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        label: Text(
                          _currentStep >= totalSteps - 1
                              ? t.onboardingGetStarted
                              : t.onboardingContinue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(AppLocalizations t, OnboardingStep step) {
    switch (step) {
      case OnboardingStep.biometric:
        return _buildBiometricStep(t, step);
      case OnboardingStep.notifications:
        return _buildNotificationsStep(t, step);
      case OnboardingStep.cloudSync:
        return _buildCloudSyncStep(t, step);
      case OnboardingStep.medical:
        return _buildMedicalInfoStep(t, step);
    }
  }

  Widget _buildBiometricStep(AppLocalizations t, OnboardingStep step) {
    final theme = Theme.of(context);
    final title = _getStepTitle(t, step);
    final subtitle = _getStepSubtitle(t, step);
    final bool isBiometricAvailable =
        _biometricAvailability == BiometricAvailabilityStatus.available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fingerprint,
              color: Color(0xFF0284C7),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      t.onboardingEnableBiometricLock,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.onboardingBiometricFaster,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isBiometricAvailable ? _biometricEnabled : false,
                onChanged: isBiometricAvailable
                    ? (bool value) => setState(() => _biometricEnabled = value)
                    : null,
                activeTrackColor: const Color(0xFF06B6D4),
              ),
            ],
          ),
        ),
        if (!isBiometricAvailable) ...<Widget>[
          const SizedBox(height: 12),
          _buildBiometricWarning(t),
        ],
        const SizedBox(height: 24),

        _buildCheckmarkItem(t.onboardingBiometricCheck1),
        const SizedBox(height: 12),
        _buildCheckmarkItem(t.onboardingBiometricCheck2),
        const SizedBox(height: 12),
        _buildCheckmarkItem(t.onboardingBiometricCheck3),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBiometricWarning(AppLocalizations t) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  t.biometricUnavailableTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
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

  String _getBiometricUnavailableReason(AppLocalizations t) {
    switch (_biometricAvailability) {
      case BiometricAvailabilityStatus.unsupported:
        return t.biometricUnavailableNoHardware;
      case BiometricAvailabilityStatus.notEnrolled:
        return t.biometricUnavailableNotEnrolled;
      case BiometricAvailabilityStatus.unavailable:
        return t.biometricUnavailableUnknown;
      case BiometricAvailabilityStatus.available:
        return t.onboardingBiometricFaster;
    }
  }

  Widget _buildCheckmarkItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeader(AppLocalizations t, OnboardingStep step) {
    final theme = Theme.of(context);
    final title = _getStepTitle(t, step);
    final subtitle = _getStepSubtitle(t, step);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNotificationsStep(AppLocalizations t, OnboardingStep step) {
    final theme = Theme.of(context);
    final title = _getStepTitle(t, step);
    final subtitle = _getStepSubtitle(t, step);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFCEFAFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF0284C7),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF717182),
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      t.onboardingPushNotifications,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.onboardingPushNotificationsSubtext,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF4A5565),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _pushEnabled,
                onChanged: (bool value) => setState(() => _pushEnabled = value),
                activeTrackColor: const Color(0xFF06B6D4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          t.onboardingNotifyWhen,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: const Color(0xFF4A5565),
          ),
        ),
        const SizedBox(height: 8),
        _buildBulletItem(t.onboardingNotifyReasonQR),
        const SizedBox(height: 8),
        _buildBulletItem(t.onboardingNotifyReasonShared),
        const SizedBox(height: 8),
        _buildBulletItem(t.onboardingNotifyReasonSecurity),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "• ",
          style: TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
          ),
        ),
      ],
    );
  }

  Widget _buildCloudSyncStep(AppLocalizations t, OnboardingStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildStepHeader(t, step),
        Text(t.onboardingCloudDescription),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _cloudProvider,
          decoration: InputDecoration(
            labelText: t.onboardingBackupProvider,
            enabled: false,
          ),
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem(
              value: 'MedVault',
              child: Text(t.onboardingProviderMedVault),
            ),
            DropdownMenuItem(
              value: 'GoogleDrive',
              child: Text(t.onboardingProviderGoogleDrive),
            ),
            DropdownMenuItem(
              value: 'iCloud',
              child: Text(t.onboardingProviderICloud),
            ),
          ],
          onChanged: null,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(t.onboardingAutoBackup),
          subtitle: Text(t.onboardingAutoBackupSubtitle),
          value: _autoBackup,
          onChanged: null,
        ),
      ],
    );
  }

  Widget _buildMedicalInfoStep(AppLocalizations t, OnboardingStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildStepHeader(t, step),
        Text(t.onboardingMedicalInfoDescription),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _bloodType,
          decoration: InputDecoration(labelText: t.bloodType),
          items: BloodGroup.valuesList
              .map(
                (String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (String? value) => setState(() => _bloodType = value),
        ),
      ],
    );
  }
}
