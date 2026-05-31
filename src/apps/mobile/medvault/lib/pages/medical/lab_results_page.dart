import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/lab_result_localizations.dart';
import '../../models/medical_models.dart';
import '../../services/medical_data_service.dart';
import '../../widgets/medvault_page_header.dart';
import 'lab_results_add_selection_page.dart';
import 'lab_result_detail_page.dart';
import 'lab_results_manual_add_page.dart';

@visibleForTesting
bool shouldShowLabResultDetails(LabResult result) {
  return result.values.isNotEmpty ||
      result.doctorInterpretation != null ||
      result.notes != null;
}

class LabResultsPage extends StatefulWidget {
  const LabResultsPage({super.key});

  @override
  State<LabResultsPage> createState() => _LabResultsPageState();
}

class _LabResultsPageState extends State<LabResultsPage> {
  static const _allCategoryFilter = '__all__';

  late final MedicalDataService _dataService;
  late final TextEditingController _searchController;
  String _selectedCategory = _allCategoryFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dataService = ServiceLocator.instance.medicalDataService;
    _searchController = TextEditingController();
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<String> _availableCategories() {
    final categories = _dataService.labResults
        .map((result) => result.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  void _onDataChanged() {
    if (!mounted) {
      return;
    }

    final availableCategories = _availableCategories().toSet();
    if (_selectedCategory != _allCategoryFilter &&
        !availableCategories.contains(_selectedCategory)) {
      setState(() {
        _selectedCategory = _allCategoryFilter;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _openAddSelection() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LabResultsAddSelectionPage()),
    );
  }

  Future<void> _openEdit(LabResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LabResultsManualAddPage(existingResult: result),
      ),
    );
  }

  Future<void> _confirmDelete(LabResult result) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.deleteLabResultTitle),
          content: Text(t.deleteLabResultConfirmation(result.testName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _dataService.deleteLabResult(result.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.labResultDeletedSuccessfully)));
  }

  Future<void> _openDetail(LabResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LabResultDetailPage(
          result: result,
          aggregateStatus: _aggregateStatus(result.values),
          categoryLabel: _categoryLabel(
            AppLocalizations.of(context),
            result.category,
          ),
        ),
      ),
    );
  }

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

  TestResultStatus _aggregateStatus(List<LabTestValue> values) {
    if (values.any((value) => value.status == TestResultStatus.abnormal)) {
      return TestResultStatus.abnormal;
    }

    if (values.any((value) => value.status == TestResultStatus.pending)) {
      return TestResultStatus.pending;
    }

    return TestResultStatus.normal;
  }

  String _formatDate(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }

  String _categoryLabel(AppLocalizations? localizations, String category) {
    return localizations?.labResultCategoryLabel(category) ?? category;
  }

  bool _matchesSearch(LabResult result, AppLocalizations? localizations) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final categoryLabel = _categoryLabel(
      localizations,
      result.category,
    ).toLowerCase();
    final notes = [
      result.doctorInterpretation,
      result.notes,
    ].whereType<String>().join(' ').toLowerCase();
    final valuesText = result.values
        .map(
          (value) =>
              '${value.name} ${value.value} ${value.unit} ${value.minRange ?? ''} ${value.maxRange ?? ''}',
        )
        .join(' ')
        .toLowerCase();

    return result.testName.toLowerCase().contains(query) ||
        result.category.toLowerCase().contains(query) ||
        categoryLabel.contains(query) ||
        notes.contains(query) ||
        valuesText.contains(query);
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

  List<LabResult> _filteredResults() {
    final results = [..._dataService.labResults];
    results.sort((left, right) => right.testDate.compareTo(left.testDate));

    return results
        .where((result) {
          if (_selectedCategory != _allCategoryFilter &&
              result.category != _selectedCategory) {
            return false;
          }

          return _matchesSearch(result, AppLocalizations.of(context));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final results = _filteredResults();
    final categories = _availableCategories();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: t.labResults,
            leading: canPop
                ? IconButton(
                    tooltip: t.onboardingBack,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  )
                : null,
            trailing: PopupMenuButton<_LabResultsAction>(
              icon: const Icon(Icons.add, color: Colors.white),
              onSelected: (action) {
                switch (action) {
                  case _LabResultsAction.addResult:
                    _openAddSelection();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _LabResultsAction.addResult,
                  child: Text(t.addLabResult),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: t.searchLabResults,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _FilterBar(
                  selectedCategory: _selectedCategory,
                  onSelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  allLabel: t.labResultsAll,
                  categories: categories,
                  labelBuilder: (category) => _categoryLabel(t, category),
                ),
                const SizedBox(height: AppSpacing.md),
                if (results.isEmpty)
                  _EmptyStateCard(
                    title:
                        _searchQuery.trim().isEmpty &&
                            _selectedCategory == _allCategoryFilter
                        ? t.noLabResults
                        : t.noMatchingLabResults,
                    subtitle: t.chooseHowToAddYourLabResults,
                    actionLabel: t.add,
                    onAction: _openAddSelection,
                  )
                else
                  Column(
                    children: [
                      for (final result in results)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _LabResultCard(
                            result: result,
                            aggregateStatus: _aggregateStatus(result.values),
                            formatDate: _formatDate(result.testDate),
                            categoryLabel: _categoryLabel(t, result.category),
                            statusLabelBuilder: (status) =>
                                _statusLabel(t, status),
                            statusColorBuilder: _statusColor,
                            statusIconBuilder: _statusIcon,
                            formatReferenceRange: _formatReferenceRange,
                            doctorInterpretationLabel: t.doctorInterpretation,
                            onTap: () => _openDetail(result),
                            onEdit: () => _openEdit(result),
                            onDelete: () => _confirmDelete(result),
                            editLabel: t.edit,
                            deleteLabel: t.delete,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  static const _allCategoryFilter = _LabResultsPageState._allCategoryFilter;

  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final String allLabel;
  final List<String> categories;
  final String Function(String category) labelBuilder;

  const _FilterBar({
    required this.selectedCategory,
    required this.onSelected,
    required this.allLabel,
    required this.categories,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TypeChip(
            label: allLabel,
            selected: selectedCategory == _allCategoryFilter,
            onTap: () => onSelected(_allCategoryFilter),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            _TypeChip(
              label: labelBuilder(category),
              selected: selectedCategory == category,
              onTap: () => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
      selectedColor: theme.colorScheme.surface,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _LabResultCard extends StatelessWidget {
  final LabResult result;
  final TestResultStatus aggregateStatus;
  final String formatDate;
  final String categoryLabel;
  final String Function(TestResultStatus status) statusLabelBuilder;
  final Color Function(TestResultStatus status) statusColorBuilder;
  final IconData Function(TestResultStatus status) statusIconBuilder;
  final String Function(LabTestValue value) formatReferenceRange;
  final String doctorInterpretationLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final String deleteLabel;

  const _LabResultCard({
    required this.result,
    required this.aggregateStatus,
    required this.formatDate,
    required this.categoryLabel,
    required this.statusLabelBuilder,
    required this.statusColorBuilder,
    required this.statusIconBuilder,
    required this.formatReferenceRange,
    required this.doctorInterpretationLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.editLabel,
    required this.deleteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = statusColorBuilder(aggregateStatus);
    final showDetails = shouldShowLabResultDetails(result);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIconBuilder(aggregateStatus),
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: aggregateStatus == TestResultStatus.abnormal
                              ? theme.colorScheme.error
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          statusLabelBuilder(aggregateStatus),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: aggregateStatus == TestResultStatus.abnormal
                                ? theme.colorScheme.onError
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PopupMenuButton<_LabResultCardAction>(
                        tooltip: '',
                        onSelected: (action) {
                          switch (action) {
                            case _LabResultCardAction.edit:
                              onEdit();
                              break;
                            case _LabResultCardAction.delete:
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _LabResultCardAction.edit,
                            child: Text(editLabel),
                          ),
                          PopupMenuItem(
                            value: _LabResultCardAction.delete,
                            child: Text(deleteLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (showDetails) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 12),
                for (final value in result.values) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${value.name}:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatReferenceRange(value),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${value.value} ${value.unit}'.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: statusColorBuilder(value.status),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              statusLabelBuilder(value.status),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColorBuilder(value.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (result.doctorInterpretation != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorInterpretationLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.doctorInterpretation!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _LabResultsAction { addResult }

enum _LabResultCardAction { edit, delete }
