import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_models.dart';
import '../../widgets/custom_dialog.dart';

import '../../services/medical_data_service.dart';

class AllergiesPage extends StatefulWidget {
  const AllergiesPage({super.key});

  @override
  State<AllergiesPage> createState() => _AllergiesPageState();
}

class _AllergiesPageState extends State<AllergiesPage> {
  late final MedicalDataService _dataService;

  @override
  void initState() {
    super.initState();
    _dataService = ServiceLocator.instance.medicalDataService;
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Color _getSeverityColor(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.severe:
        return Colors.red;
      case AllergySeverity.moderate:
        return Colors.amber;
      case AllergySeverity.mild:
        return Colors.yellow;
    }
  }

  String _getSeverityLabel(BuildContext context, AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.severe:
        return 'Severe';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.mild:
        return 'Mild';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_dataService.allergies.length} ${t?.allergiesRecorded ?? "allergies recorded"}',
                style: theme.textTheme.bodyMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddAllergyDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(t?.add ?? 'Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
              ),
              itemCount: _dataService.allergies.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final allergy = _dataService.allergies[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              allergy.substance,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(
                                  allergy.severity,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getSeverityLabel(context, allergy.severity),
                                style: TextStyle(
                                  color: _getSeverityColor(allergy.severity),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: allergy.status == AllergyStatus.active
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                allergy.status == AllergyStatus.active
                                    ? 'Active'
                                    : 'Resolved',
                                style: TextStyle(
                                  color: allergy.status == AllergyStatus.active
                                      ? Colors.green[800]
                                      : Colors.grey[800],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          allergy.reaction,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (allergy.notes != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            allergy.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showEditAllergyDialog(context, allergy),
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteDialog(context, allergy),
                              iconSize: 20,
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
      ),
    );
  }

  Future<void> _showAddAllergyDialog(
    BuildContext context, {
    Allergy? existingAllergy,
  }) async {
    final t = AppLocalizations.of(context);

    final substanceCtrl = TextEditingController(
      text: existingAllergy?.substance ?? '',
    );
    final reactionCtrl = TextEditingController(
      text: existingAllergy?.reaction ?? '',
    );
    final notesCtrl = TextEditingController(text: existingAllergy?.notes ?? '');
    final attachmentCtrl = TextEditingController(
      text: existingAllergy?.documentAttachment ?? '',
    );
    AllergySeverity selectedSeverity =
        existingAllergy?.severity ?? AllergySeverity.moderate;
    AllergyStatus selectedStatus =
        existingAllergy?.status ?? AllergyStatus.active;
    final isEditing = existingAllergy != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CustomDialog(
              title: isEditing
                  ? (t?.editAllergy ?? 'Edit Allergy')
                  : (t?.addAllergy ?? 'Add Allergy'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: substanceCtrl,
                      decoration: InputDecoration(
                        labelText: '${t?.allergyName ?? "Substance"} *',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: reactionCtrl,
                      decoration: InputDecoration(
                        labelText: '${t?.reaction ?? 'Reaction'} *',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<AllergySeverity>(
                      initialValue: selectedSeverity,
                      items: AllergySeverity.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.name[0].toUpperCase() + s.name.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedSeverity = value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: t?.severity ?? 'Severity',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<AllergyStatus>(
                      initialValue: selectedStatus,
                      items: AllergyStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.name[0].toUpperCase() +
                                    status.name.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedStatus = value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: t?.status ?? 'Status',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: t?.notes ?? 'Notes',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t?.cancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (substanceCtrl.text.trim().isEmpty ||
                        reactionCtrl.text.trim().isEmpty) {
                      return;
                    }

                    final newAllergy = Allergy(
                      id:
                          existingAllergy?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: 'user123',
                      substance: substanceCtrl.text.trim(),
                      reaction: reactionCtrl.text.trim(),
                      severity: selectedSeverity,
                      status: selectedStatus,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      documentAttachment: attachmentCtrl.text.trim().isEmpty
                          ? null
                          : attachmentCtrl.text.trim(),
                      createdAt: existingAllergy?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (isEditing) {
                      _dataService.updateAllergy(newAllergy);
                    } else {
                      _dataService.addAllergy(newAllergy);
                    }

                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? (t?.allergyUpdatedSuccessfully ??
                                      'Allergy updated successfully')
                                : (t?.allergyAddedSuccessfully ??
                                      'Allergy added successfully'),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(t?.save ?? 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditAllergyDialog(
    BuildContext context,
    Allergy allergy,
  ) async {
    _showAddAllergyDialog(context, existingAllergy: allergy);
  }

  Future<void> _showDeleteDialog(BuildContext context, Allergy allergy) async {
    final t = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: t?.deleteAllergy ?? 'Delete Allergy?',
          content: Text(
            '${t?.areYouSureYouWantToDelete ?? "Are you sure you want to delete"} ${allergy.substance}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _dataService.deleteAllergy(allergy.id);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t?.allergyDeletedSuccessfully ??
                            'Allergy deleted successfully',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                t?.delete ?? 'Delete',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
