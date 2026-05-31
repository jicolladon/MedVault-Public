import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_models.dart';
import '../../widgets/medvault_page_header.dart';

class LabResultDetailPage extends StatelessWidget {
  final LabResult result;
  final TestResultStatus aggregateStatus;
  final String categoryLabel;

  const LabResultDetailPage({
    super.key,
    required this.result,
    required this.aggregateStatus,
    required this.categoryLabel,
  });

  Color _statusColor(TestResultStatus status) {
    switch (status) {
      case TestResultStatus.normal:
        return const Color(0xFF16A34A);
      case TestResultStatus.abnormal:
        return const Color(0xFFDC2626);
      case TestResultStatus.pending:
        return const Color(0xFF6B7280);
    }
  }

  IconData _statusIcon(TestResultStatus status) {
    switch (status) {
      case TestResultStatus.normal:
        return Icons.remove_rounded;
      case TestResultStatus.abnormal:
        return Icons.trending_up_rounded;
      case TestResultStatus.pending:
        return Icons.schedule_rounded;
    }
  }

  String _statusLabel(AppLocalizations t, TestResultStatus status) {
    switch (status) {
      case TestResultStatus.normal:
        return t.normal;
      case TestResultStatus.abnormal:
        return t.abnormal;
      case TestResultStatus.pending:
        return t.pending;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d/M/yyyy h:mm a').format(dateTime);
  }

  String _formatReferenceRange(LabTestValue value) {
    final minRange = value.minRange?.trim();
    final maxRange = value.maxRange?.trim();

    if ((minRange == null || minRange.isEmpty) &&
        (maxRange == null || maxRange.isEmpty)) {
      return '';
    }

    if (minRange != null &&
        minRange.isNotEmpty &&
        maxRange != null &&
        maxRange.isNotEmpty) {
      return '($minRange - $maxRange)';
    }

    if (minRange != null && minRange.isNotEmpty) {
      return '(> $minRange)';
    }

    return '(< $maxRange)';
  }

  List<String> _parseDocumentUrls() {
    final rawUrls = result.documentUrls;
    if (rawUrls == null || rawUrls.trim().isEmpty) {
      return const <String>[];
    }

    try {
      final decoded = jsonDecode(rawUrls);
      if (decoded is! List) {
        return const <String>[];
      }

      return decoded
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(BuildContext context, LabTestValue value) {
    final theme = Theme.of(context);
    final valueStatusColor = _statusColor(value.status);
    final referenceRange = _formatReferenceRange(value);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (referenceRange.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        referenceRange,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${value.value} ${value.unit}'.trim(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: valueStatusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel(AppLocalizations.of(context)!, value.status),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: valueStatusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final canPop = Navigator.of(context).canPop();
    final documentUrls = _parseDocumentUrls();
    final statusColor = _statusColor(aggregateStatus);
    final statusIcon = _statusIcon(aggregateStatus);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: t.labResultDetails,
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
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.testName,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  categoryLabel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(result.testDate),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 18),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      aggregateStatus ==
                                          TestResultStatus.abnormal
                                      ? theme.colorScheme.error
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  _statusLabel(t, aggregateStatus),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color:
                                        aggregateStatus ==
                                            TestResultStatus.abnormal
                                        ? theme.colorScheme.onError
                                        : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        label: t.category,
                        value: categoryLabel,
                      ),
                      _buildInfoRow(
                        context,
                        label: t.added,
                        value: _formatDateTime(result.createdAt),
                      ),
                      _buildInfoRow(
                        context,
                        label: t.updated,
                        value: _formatDateTime(result.updatedAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.testInformation,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildInfoRow(
                        context,
                        label: t.testName,
                        value: result.testName,
                      ),
                      _buildInfoRow(
                        context,
                        label: t.category,
                        value: categoryLabel,
                      ),
                      _buildInfoRow(
                        context,
                        label: t.testDate,
                        value: _formatDate(result.testDate),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.testValues,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final value in result.values)
                        _buildValueCard(context, value),
                    ],
                  ),
                ),
                if (result.doctorInterpretation != null ||
                    result.notes != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.interpretationAndNotes,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (result.doctorInterpretation != null) ...[
                          Text(
                            t.doctorInterpretation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.doctorInterpretation!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (result.notes != null) const SizedBox(height: 14),
                        ],
                        if (result.notes != null) ...[
                          Text(
                            t.notes,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (documentUrls.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.attachments,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final url in documentUrls)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              url,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
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
