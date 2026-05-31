import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/lab_result_localizations.dart';
import '../../models/medical_models.dart';
import '../../services/medical_data_service.dart';
import '../../widgets/medvault_page_header.dart';

class LabResultsManualAddPage extends StatefulWidget {
  final LabResult? existingResult;

  const LabResultsManualAddPage({super.key, this.existingResult});

  @override
  State<LabResultsManualAddPage> createState() =>
      _LabResultsManualAddPageState();
}

class _LabResultsManualAddPageState extends State<LabResultsManualAddPage> {
  late final MedicalDataService _dataService;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _doctorInterpretationController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<_LabValueDraftController> _valueControllers = [];

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = '';

  bool get _isEditing => widget.existingResult != null;

  List<LabResultType> get _availableTypes {
    final types = _dataService.labResultTypes;
    if (types.isNotEmpty) {
      return types;
    }

    return const [
      LabResultType(
        name: 'Complete Blood Count (CBC)',
        suggestedFields: [
          'Hemoglobin',
          'Hematocrit',
          'White Blood Cells',
          'Platelets',
        ],
        description: 'Checks your blood cells.',
      ),
      LabResultType(
        name: 'Metabolic Panels (BMP or CMP)',
        suggestedFields: ['Glucose', 'Sodium', 'Potassium', 'Creatinine'],
        description: 'Checks organ function and chemistry.',
      ),
      LabResultType(
        name: 'Lipid Panel',
        suggestedFields: ['Total Cholesterol', 'LDL', 'HDL', 'Triglycerides'],
        description: 'Checks your heart health and fats.',
      ),
      LabResultType(
        name: 'Thyroid Panel',
        suggestedFields: ['TSH', 'Free T4'],
        description: 'Checks your metabolism regulator.',
      ),
      LabResultType(
        name: 'Diabetes Monitoring',
        suggestedFields: ['Blood Glucose', 'Fasting Glucose'],
        description: 'Checks long-term sugar.',
      ),
      LabResultType(
        name: 'Hemoglobin A1c',
        suggestedFields: ['Hemoglobin A1c'],
        description: 'Your average blood sugar over the last 3 months.',
      ),
      LabResultType(
        name: 'Urinalysis',
        suggestedFields: ['Protein', 'Glucose', 'Ketones', 'Specific Gravity'],
        description: 'Checks waste management.',
      ),
      LabResultType(
        name: 'Nutrient Levels',
        suggestedFields: ['Vitamin D', 'Vitamin B12', 'Ferritin'],
        description: 'Checks for deficiencies.',
      ),
    ];
  }

  LabResultType get _selectedType {
    return _availableTypes.firstWhere(
      (type) => type.name == _selectedCategory,
      orElse: () => _availableTypes.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _dataService = ServiceLocator.instance.medicalDataService;
    _dataService.addListener(_onDataChanged);

    if (_isEditing) {
      _loadExistingResult(widget.existingResult!);
      return;
    }

    _selectedCategory = _availableTypes.first.name;
    _dateController.text = _formatDate(_selectedDate);
    _resetValueRows(_selectedType, refresh: false);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    _testNameController.dispose();
    _dateController.dispose();
    _doctorInterpretationController.dispose();
    _notesController.dispose();
    for (final controller in _valueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) {
      return;
    }

    final availableTypes = _availableTypes;
    if (availableTypes.isEmpty) {
      return;
    }

    final hasSelectedCategory = availableTypes.any(
      (type) => type.name == _selectedCategory,
    );

    if (hasSelectedCategory) {
      setState(() {});
      return;
    }

    setState(() {
      _selectedCategory = availableTypes.first.name;
      _resetValueRows(_selectedType, refresh: false);
    });
  }

  void _loadExistingResult(LabResult existingResult) {
    _testNameController.text = existingResult.testName;
    _selectedDate = existingResult.testDate;
    _dateController.text = _formatDate(_selectedDate);
    _doctorInterpretationController.text =
        existingResult.doctorInterpretation ?? '';
    _notesController.text = existingResult.notes ?? '';

    final availableTypes = _availableTypes;
    final hasCategory = availableTypes.any(
      (type) => type.name == existingResult.category,
    );
    _selectedCategory = hasCategory
        ? existingResult.category
        : availableTypes.first.name;

    _resetValueRows(_selectedType, refresh: false);

    if (existingResult.values.isEmpty) {
      return;
    }

    for (final controller in _valueControllers) {
      controller.dispose();
    }
    _valueControllers
      ..clear()
      ..addAll(
        existingResult.values.map(
          (value) => _LabValueDraftController(
            name: value.name,
            value: value.value,
            unit: value.unit,
            minRange: value.minRange ?? '',
            maxRange: value.maxRange ?? '',
          ),
        ),
      );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }

  String _categoryLabel(String category) {
    final localizations = AppLocalizations.of(context);
    return localizations?.labResultCategoryLabel(category) ?? category;
  }

  String _categoryDescription(String category) {
    final localizations = AppLocalizations.of(context);
    return localizations?.labResultCategoryDescription(category) ?? '';
  }

  bool get _canRemoveSelectedCategory {
    return _dataService.canRemoveLabResultType(_selectedCategory);
  }

  Future<void> _removeSelectedCategory() async {
    final t = AppLocalizations.of(context)!;
    final category = _selectedCategory;

    if (!_dataService.canRemoveLabResultType(category)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.labResultTypeInUseCannotRemove)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.removeLabResultType),
          content: Text(t.removeLabResultTypeConfirmation),
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

    final removed = await _dataService.removeLabResultType(category);
    if (!removed) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.labResultTypeInUseCannotRemove)));
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedCategory = _availableTypes.first.name;
      _resetValueRows(_selectedType, refresh: false);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.labResultTypeRemovedSuccessfully)));
  }

  void _resetValueRows(LabResultType type, {bool refresh = true}) {
    for (final controller in _valueControllers) {
      controller.dispose();
    }
    _valueControllers.clear();

    final suggestedFields = type.suggestedFields.isNotEmpty
        ? type.suggestedFields
        : <String>[''];

    for (final fieldName in suggestedFields) {
      _valueControllers.add(
        _LabValueDraftController(
          name: fieldName,
          value: '',
          unit: '',
          minRange: '',
          maxRange: '',
        ),
      );
    }

    if (_valueControllers.isEmpty) {
      _valueControllers.add(_LabValueDraftController());
    }

    if (mounted && refresh) {
      setState(() {});
    }
  }

  void _addValueRow() {
    setState(() {
      _valueControllers.add(_LabValueDraftController());
    });
  }

  void _removeValueRow(int index) {
    if (_valueControllers.length == 1) {
      return;
    }

    setState(() {
      _valueControllers[index].dispose();
      _valueControllers.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _dateController.text = _formatDate(picked);
    });
  }

  void _onCategoryChanged(String? value) {
    if (value == null || value == _selectedCategory) {
      return;
    }

    setState(() {
      _selectedCategory = value;
      _resetValueRows(_selectedType, refresh: false);
    });
  }

  TestResultStatus _statusForDraft(_LabValueDraftController controller) {
    final value = double.tryParse(
      controller.valueController.text.trim().replaceAll(',', '.'),
    );
    final minRange = double.tryParse(
      controller.minRangeController.text.trim().replaceAll(',', '.'),
    );
    final maxRange = double.tryParse(
      controller.maxRangeController.text.trim().replaceAll(',', '.'),
    );

    if (value == null) {
      return TestResultStatus.pending;
    }

    if (minRange == null && maxRange == null) {
      return TestResultStatus.pending;
    }

    if (minRange != null && value < minRange) {
      return TestResultStatus.abnormal;
    }

    if (maxRange != null && value > maxRange) {
      return TestResultStatus.abnormal;
    }

    return TestResultStatus.normal;
  }

  Future<void> _saveResult() async {
    final t = AppLocalizations.of(context)!;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final values = _valueControllers
        .map(
          (controller) => _LabValueDraft(
            name: controller.nameController.text.trim(),
            value: controller.valueController.text.trim(),
            unit: controller.unitController.text.trim(),
            minRange: controller.minRangeController.text.trim(),
            maxRange: controller.maxRangeController.text.trim(),
            status: _statusForDraft(controller),
          ),
        )
        .where((draft) => draft.hasContent)
        .map(
          (draft) => LabTestValue(
            name: draft.name,
            value: draft.value,
            unit: draft.unit,
            minRange: draft.minRange.isEmpty ? null : draft.minRange,
            maxRange: draft.maxRange.isEmpty ? null : draft.maxRange,
            status: draft.status,
          ),
        )
        .toList(growable: false);

    if (values.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.error)));
      return;
    }

    final now = DateTime.now();
    final existingResult = widget.existingResult;
    final result = LabResult(
      id: existingResult?.id ?? now.millisecondsSinceEpoch.toString(),
      userId: existingResult?.userId ?? '',
      testName: _testNameController.text.trim(),
      category: _selectedCategory,
      testDate: _selectedDate,
      values: values,
      doctorInterpretation: _doctorInterpretationController.text.trim().isEmpty
          ? null
          : _doctorInterpretationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      documentUrls: existingResult?.documentUrls,
      createdAt: existingResult?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditing) {
      await _dataService.updateLabResult(result);
    } else {
      await _dataService.addLabResult(result);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? t.labResultUpdatedSuccessfully
              : t.labResultAddedSuccessfully,
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _showAddCategoryDialog() async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final created = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.addLabResultType),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: t.category,
              hintText: t.selectCategory,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () {
                final trimmedName = controller.text.trim();
                if (trimmedName.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(trimmedName);
              },
              child: Text(t.save),
            ),
          ],
        );
      },
    );

    final trimmedName = created?.trim() ?? '';
    if (trimmedName.isEmpty) {
      return;
    }

    await _dataService.addLabResultType(LabResultType(name: trimmedName));

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedCategory = trimmedName;
      _resetValueRows(_selectedType, refresh: false);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.labResultTypeCreatedSuccessfully)));
  }

  Widget _buildCategoryControls(
    BuildContext context,
    AppLocalizations t,
    ThemeData theme,
  ) {
    final availableTypes = _availableTypes;

    final dropdown = DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      isExpanded: true,
      decoration: _decoration(t.category, hint: t.selectCategory),
      items: availableTypes
          .map(
            (type) => DropdownMenuItem<String>(
              value: type.name,
              child: Text(
                _categoryLabel(type.name),
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      selectedItemBuilder: (dropdownContext) {
        return availableTypes
            .map(
              (type) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _categoryLabel(type.name),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false);
      },
      onChanged: _onCategoryChanged,
    );

    final buttons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Semantics(
          label: t.addLabResultType,
          button: true,
          child: Tooltip(
            message: t.addLabResultType,
            child: InkWell(
              onTap: _showAddCategoryDialog,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  '+',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_canRemoveSelectedCategory)
          Semantics(
            label: t.removeLabResultType,
            button: true,
            child: Tooltip(
              message: t.removeLabResultType,
              child: InkWell(
                onTap: _removeSelectedCategory,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.14,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 22,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final actionButtonsWidth = _canRemoveSelectedCategory ? 104.0 : 48.0;

        if (constraints.maxWidth < actionButtonsWidth + 160) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dropdown,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: buttons),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: dropdown),
            const SizedBox(width: 8),
            buttons,
          ],
        );
      },
    );
  }

  Widget _buildBottomActions(AppLocalizations t) {
    final saveActionLabel = _isEditing ? t.save : t.saveResult;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _saveResult,
              child: Text(saveActionLabel),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final theme = Theme.of(context);

    return Container(
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
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildValueCard(BuildContext context, int index) {
    final t = AppLocalizations.of(context)!;
    final controller = _valueControllers[index];
    final isDeletable = _valueControllers.length > 1;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t.valueLabel} ${index + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isDeletable)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeValueRow(index),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
            ],
          ),
          TextFormField(
            controller: controller.nameController,
            decoration: _decoration(t.name, hint: t.labValueNameHint),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration(t.yourValue),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller.unitController,
                  decoration: _decoration(t.unit),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.minRangeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration(t.minimum),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller.maxRangeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration(t.maximum),
                  textInputAction: TextInputAction.next,
                ),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: _buildBottomActions(t),
      body: Column(
        children: [
          MedVaultPageHeader(
            title: _isEditing ? t.editLabResultTitle : t.addLabResultTitle,
            leading: canPop
                ? IconButton(
                    tooltip: t.onboardingBack,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  )
                : null,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                children: [
                  _buildSectionCard(
                    title: t.testInformation,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _testNameController,
                          decoration: _decoration(t.testName),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t.error;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _decoration(t.testDate).copyWith(
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCategoryControls(context, t, theme),
                        if (_categoryDescription(
                          _selectedCategory,
                        ).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _categoryDescription(_selectedCategory),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSectionCard(
                    title: t.testValues,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.testValues,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _addValueRow,
                              icon: const Icon(Icons.add),
                              label: Text(t.addValue),
                            ),
                          ],
                        ),
                        for (var i = 0; i < _valueControllers.length; i++)
                          _buildValueCard(context, i),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSectionCard(
                    title: t.interpretationAndNotes,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _doctorInterpretationController,
                          maxLines: 4,
                          decoration: _decoration(t.doctorInterpretation),
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: _decoration(t.notes),
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabValueDraftController {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final TextEditingController unitController;
  final TextEditingController minRangeController;
  final TextEditingController maxRangeController;

  _LabValueDraftController({
    String name = '',
    String value = '',
    String unit = '',
    String minRange = '',
    String maxRange = '',
  }) : nameController = TextEditingController(text: name),
       valueController = TextEditingController(text: value),
       unitController = TextEditingController(text: unit),
       minRangeController = TextEditingController(text: minRange),
       maxRangeController = TextEditingController(text: maxRange);

  void dispose() {
    nameController.dispose();
    valueController.dispose();
    unitController.dispose();
    minRangeController.dispose();
    maxRangeController.dispose();
  }
}

class _LabValueDraft {
  final String name;
  final String value;
  final String unit;
  final String minRange;
  final String maxRange;
  final TestResultStatus status;

  const _LabValueDraft({
    required this.name,
    required this.value,
    required this.unit,
    required this.minRange,
    required this.maxRange,
    required this.status,
  });

  bool get hasContent {
    return name.isNotEmpty ||
        value.isNotEmpty ||
        unit.isNotEmpty ||
        minRange.isNotEmpty ||
        maxRange.isNotEmpty;
  }
}
