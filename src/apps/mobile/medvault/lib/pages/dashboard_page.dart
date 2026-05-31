import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_spacing.dart';
import '../core/di/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/medical_models.dart';
import '../services/medical_data_service.dart';
import '../services/sharing_service.dart';
import '../widgets/medvault_page_header.dart';
import 'medical/lab_results_page.dart';
import 'medical_information_page.dart';
import 'sharing_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  MedicalDataService get _dataService =>
      ServiceLocator.instance.medicalDataService;

  SharingService get _sharingService => ServiceLocator.instance.sharingService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_dataService, _sharingService]),
      builder: (context, _) {
        final allergyCount = _dataService.allergies.length;
        final medicationCount = _dataService.medications.length;
        final vaccinationCount = _dataService.vaccinations.length;
        final bloodType = _dataService.bloodType;

        final sortedAllergies = [..._dataService.allergies]
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
        final criticalAllergy = _pickCriticalAllergy(sortedAllergies);

        final sortedLabResults = [..._dataService.labResults]
          ..sort((left, right) => right.testDate.compareTo(left.testDate));
        final labValues = _dataService.labResults
            .expand((result) => result.values)
            .toList(growable: false);
        final totalTests = labValues.length;
        final normalTests = labValues
            .where((value) => value.status == TestResultStatus.normal)
            .length;
        final flaggedTests = labValues
            .where((value) => value.status == TestResultStatus.abnormal)
            .length;
        final labPreviews = sortedLabResults
            .take(2)
            .map(_DashboardLabPreview.fromResult)
            .toList(growable: false);

        final activityItems = _buildActivityItems(
          context: context,
          criticalAllergy: criticalAllergy,
          labResults: sortedLabResults,
          medications: _dataService.medications,
          vaccinations: _dataService.vaccinations,
        );
        final emergencySharingEnabled = _sharingService.emergencySharingEnabled;

        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            MedVaultPageHeader(
              title: t?.appTitle ?? 'MedVault',
              subtitle: t?.dashboardSubtitle ?? 'Your Health Dashboard',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: _EmergencyAccessCard(
                title: t?.emergencyAccess ?? 'Emergency Access',
                subtitle: emergencySharingEnabled
                    ? (t?.shareCriticalInfoInstantly ??
                          'Share critical info instantly')
                    : 'Disabled in sharing settings',
                enabled: emergencySharingEnabled,
                onTap: () async {
                  final sharingService = ServiceLocator.instance.sharingService;
                  await sharingService.initialize();
                  if (!context.mounted) {
                    return;
                  }

                  if (!sharingService.emergencySharingEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t?.emergencySharingDisabledInSettings ??
                              'Emergency sharing is disabled in settings.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmergencySharingConfigurationPage(
                        sharingService: sharingService,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: _SectionCard(
                title: t?.medicalInfo ?? 'Medical Info',
                icon: Icons.favorite_border_rounded,
                iconColor: theme.colorScheme.error,
                trailing: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicalInformationPage(),
                      ),
                    );
                  },
                  child: Text(t?.viewAll ?? 'View All'),
                ),
                child: Column(
                  children: [
                    _BloodTypePanel(
                      title: t?.bloodType ?? 'Blood Type',
                      subtitle:
                          t?.criticialInformation ?? 'Critical Information',
                      value: bloodType,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryStatCard(
                            label: t?.allergies ?? 'Allergies',
                            value: allergyCount.toString(),
                            icon: Icons.warning_amber_rounded,
                            backgroundColor:
                                theme.colorScheme.tertiaryContainer,
                            iconColor: theme.colorScheme.onTertiaryContainer,
                            labelColor: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryStatCard(
                            label: t?.medications ?? 'Medications',
                            value: medicationCount.toString(),
                            icon: Icons.medication_outlined,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            iconColor: theme.colorScheme.onPrimaryContainer,
                            labelColor: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryStatCard(
                            label: t?.vaccinations ?? 'Vaccinations',
                            value: vaccinationCount.toString(),
                            icon: Icons.vaccines_outlined,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            iconColor: theme.colorScheme.onSecondaryContainer,
                            labelColor: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CriticalAllergyCard(
                      title: t?.criticalAllergy ?? 'Critical Allergy',
                      allergy: criticalAllergy,
                      fallbackLabel:
                          t?.noCriticalAllergies ?? 'No critical allergies',
                      highLabel: t?.high ?? 'High',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: _SectionCard(
                title: t?.labResults ?? 'Lab Results',
                icon: Icons.science_outlined,
                iconColor: theme.colorScheme.primary,
                trailing: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LabResultsPage(),
                      ),
                    );
                  },
                  child: Text(t?.viewAll ?? 'View All'),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryStatCard(
                            label: t?.totalTests ?? 'Total Tests',
                            value: totalTests.toString(),
                            icon: Icons.science_rounded,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            iconColor: theme.colorScheme.onSecondaryContainer,
                            labelColor: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryStatCard(
                            label: t?.normal ?? 'Normal',
                            value: normalTests.toString(),
                            icon: Icons.verified_rounded,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            iconColor: theme.colorScheme.onSecondaryContainer,
                            labelColor: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryStatCard(
                            label: t?.flagged ?? 'Flagged',
                            value: flaggedTests.toString(),
                            icon: Icons.error_outline_rounded,
                            backgroundColor: theme.colorScheme.errorContainer,
                            iconColor: theme.colorScheme.onErrorContainer,
                            labelColor: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (labPreviews.isEmpty)
                      _EmptySectionHint(
                        text: t?.noLabResults ?? 'No lab results yet',
                      )
                    else
                      Column(
                        children: [
                          for (final preview in labPreviews)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _LabPreviewCard(
                                preview: preview,
                                locale: Localizations.localeOf(context),
                                normalLabel: t?.normal ?? 'Normal',
                                pendingLabel: t?.pending ?? 'Pending',
                                abnormalLabel: t?.high ?? 'High',
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: _SectionCard(
                title: t?.recentActivity ?? 'Recent Activity',
                icon: Icons.history_rounded,
                iconColor: theme.colorScheme.primary,
                trailing: TextButton(onPressed: () {}, child: Text('')),
                child: activityItems.isEmpty
                    ? _EmptySectionHint(
                        text: t?.noRecentActivity ?? 'No recent activity yet',
                      )
                    : Column(
                        children: [
                          for (final item in activityItems)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _ActivityRow(
                                item: item,
                                locale: Localizations.localeOf(context),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: _SecurityBanner(
                title: t?.yourDataIsSecure ?? 'Your data is secure',
                subtitle:
                    t?.dashboardSecurityDescription ??
                    'All records are encrypted end-to-end. Only you control access.',
              ),
            ),
            const SizedBox(height: 88),
          ],
        );
      },
    );
  }
}

class _EmergencyAccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _EmergencyAccessCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? const [Color(0xFFFF4A3A), Color(0xFFFF7A00)]
                  : [
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surfaceContainer,
                    ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: enabled
                    ? const Color(0x334F46E5)
                    : Theme.of(
                        context,
                      ).colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: enabled
                    ? Colors.white.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: enabled
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: enabled
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? Colors.white.withValues(alpha: 0.92)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _BloodTypePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  const _BloodTypePanel({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.error.withValues(alpha: 0.2),
            child: Icon(
              Icons.bloodtype_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color labelColor;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CriticalAllergyCard extends StatelessWidget {
  final String title;
  final Allergy? allergy;
  final String fallbackLabel;
  final String highLabel;

  const _CriticalAllergyCard({
    required this.title,
    required this.allergy,
    required this.fallbackLabel,
    required this.highLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAllergy = allergy != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasAllergy
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: hasAllergy
              ? theme.colorScheme.error.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: hasAllergy
                ? theme.colorScheme.error.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              hasAllergy ? Icons.error_outline_rounded : Icons.info_outline,
              color: hasAllergy
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAllergy ? title : fallbackLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasAllergy
                        ? theme.colorScheme.onErrorContainer
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasAllergy
                      ? '${allergy!.substance} · ${allergy!.reaction}'
                      : fallbackLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasAllergy
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasAllergy)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                highLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LabPreviewCard extends StatelessWidget {
  final _DashboardLabPreview preview;
  final Locale locale;
  final String normalLabel;
  final String pendingLabel;
  final String abnormalLabel;

  const _LabPreviewCard({
    required this.preview,
    required this.locale,
    required this.normalLabel,
    required this.pendingLabel,
    required this.abnormalLabel,
  });

  Color _statusColor() {
    switch (preview.status) {
      case TestResultStatus.normal:
        return const Color(0xFF16A34A);
      case TestResultStatus.abnormal:
        return const Color(0xFFF97316);
      case TestResultStatus.pending:
        return const Color(0xFF6B7280);
    }
  }

  String _statusLabel() {
    switch (preview.status) {
      case TestResultStatus.normal:
        return normalLabel;
      case TestResultStatus.abnormal:
        return abnormalLabel;
      case TestResultStatus.pending:
        return pendingLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd(locale.toLanguageTag()).format(preview.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                preview.value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _statusLabel(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _DashboardActivityItem item;
  final Locale locale;

  const _ActivityRow({required this.item, required this.locale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: item.iconBackground,
            child: Icon(item.icon, color: item.iconColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.subtitle} · ${DateFormat.MMMd(locale.toLanguageTag()).format(item.timestamp)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (item.badgeLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: item.badgeColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.badgeLabel!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SecurityBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SecurityBanner({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.shield_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
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

class _EmptySectionHint extends StatelessWidget {
  final String text;

  const _EmptySectionHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _DashboardLabPreview {
  final String title;
  final String value;
  final TestResultStatus status;
  final DateTime date;

  const _DashboardLabPreview({
    required this.title,
    required this.value,
    required this.status,
    required this.date,
  });

  factory _DashboardLabPreview.fromResult(LabResult result) {
    if (result.values.isEmpty) {
      return _DashboardLabPreview(
        title: result.testName,
        value: '',
        status: TestResultStatus.pending,
        date: result.testDate,
      );
    }

    final primaryValue = result.values.firstWhere(
      (entry) => entry.status != TestResultStatus.normal,
      orElse: () => result.values.first,
    );

    return _DashboardLabPreview(
      title: result.testName,
      value: '${primaryValue.value} ${primaryValue.unit}'.trim(),
      status: primaryValue.status,
      date: result.testDate,
    );
  }
}

class _DashboardActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String? badgeLabel;
  final Color? badgeColor;
  final DateTime timestamp;

  const _DashboardActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.timestamp,
    this.badgeLabel,
    this.badgeColor,
  });
}

Allergy? _pickCriticalAllergy(List<Allergy> allergies) {
  for (final allergy in allergies) {
    if (allergy.status == AllergyStatus.active &&
        allergy.severity == AllergySeverity.severe) {
      return allergy;
    }
  }

  if (allergies.isEmpty) {
    return null;
  }

  return allergies.first;
}

List<_DashboardActivityItem> _buildActivityItems({
  required BuildContext context,
  required Allergy? criticalAllergy,
  required List<LabResult> labResults,
  required List<Medication> medications,
  required List<Vaccination> vaccinations,
}) {
  final t = AppLocalizations.of(context);
  final items = <_DashboardActivityItem>[];

  if (criticalAllergy != null) {
    items.add(
      _DashboardActivityItem(
        title: criticalAllergy.substance,
        subtitle: criticalAllergy.reaction,
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBackground: const Color(0xFFFFE4E6),
        badgeLabel: t?.high ?? 'High',
        badgeColor: const Color(0xFFDC2626),
        timestamp: criticalAllergy.updatedAt,
      ),
    );
  }

  if (labResults.isNotEmpty) {
    final latestLab = labResults.first;
    final preview = _DashboardLabPreview.fromResult(latestLab);
    items.add(
      _DashboardActivityItem(
        title: preview.title,
        subtitle: preview.value.isEmpty
            ? (t?.labResults ?? 'Lab Results')
            : preview.value,
        icon: Icons.science_outlined,
        iconColor: preview.status == TestResultStatus.abnormal
            ? const Color(0xFFF97316)
            : const Color(0xFF7C3AED),
        iconBackground: preview.status == TestResultStatus.abnormal
            ? const Color(0xFFFFF4E5)
            : const Color(0xFFF4EFFF),
        badgeLabel: preview.status == TestResultStatus.abnormal
            ? (t?.high ?? 'High')
            : null,
        badgeColor: const Color(0xFFF97316),
        timestamp: preview.date,
      ),
    );
  }

  if (medications.isNotEmpty) {
    final latestMedication = [...medications]
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final medication = latestMedication.first;
    items.add(
      _DashboardActivityItem(
        title: medication.name,
        subtitle: medication.frequency,
        icon: Icons.medication_outlined,
        iconColor: const Color(0xFF2563EB),
        iconBackground: const Color(0xFFEAF2FF),
        timestamp: medication.updatedAt,
      ),
    );
  }

  if (vaccinations.isNotEmpty) {
    final latestVaccination = [...vaccinations]
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final vaccination = latestVaccination.first;
    items.add(
      _DashboardActivityItem(
        title: vaccination.vaccineName,
        subtitle: vaccination.dates.isNotEmpty
            ? DateFormat.yMMMd(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(vaccination.dates.first)
            : (t?.vaccinations ?? 'Vaccinations'),
        icon: Icons.vaccines_outlined,
        iconColor: const Color(0xFF9333EA),
        iconBackground: const Color(0xFFF4EFFF),
        timestamp: vaccination.updatedAt,
      ),
    );
  }

  items.sort((left, right) => right.timestamp.compareTo(left.timestamp));
  return items.take(3).toList(growable: false);
}
