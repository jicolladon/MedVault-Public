import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_models.dart';
import '../../widgets/custom_dialog.dart';

import '../../services/medical_data_service.dart';

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
                '${_dataService.medications.length} ${t?.medicationsRecorded ?? "medications recorded"}',
                style: theme.textTheme.bodyMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddMedicationDialog(context),
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
              itemCount: _dataService.medications.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final med = _dataService.medications[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${t?.dosage ?? "Dosage"}:',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    med.dosage,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${t?.frequency ?? "Frequency"}:',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    med.frequency,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Start date: ${_formatDate(med.startDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        if (med.endDate != null)
                          Text(
                            'End date: ${_formatDate(med.endDate!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        Text(
                          'Status: ${med.status.name[0].toUpperCase()}${med.status.name.substring(1)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        if (med.notes != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            med.notes!,
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
                                  _showEditMedicationDialog(context, med),
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(context, med),
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

  Future<void> _showAddMedicationDialog(
    BuildContext context, {
    Medication? existingMedication,
  }) async {
    final t = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(
      text: existingMedication?.name ?? '',
    );
    final dosageCtrl = TextEditingController(
      text: existingMedication?.dosage ?? '',
    );
    final frequencyCtrl = TextEditingController(
      text: existingMedication?.frequency ?? '',
    );
    var selectedStartDate = existingMedication?.startDate ?? DateTime.now();
    DateTime? selectedEndDate = existingMedication?.endDate;
    final startDateCtrl = TextEditingController(
      text: _formatDate(selectedStartDate),
    );
    final endDateCtrl = TextEditingController(
      text: selectedEndDate == null ? '' : _formatDate(selectedEndDate),
    );
    final notesCtrl = TextEditingController(
      text: existingMedication?.notes ?? '',
    );
    final attachmentCtrl = TextEditingController(
      text: existingMedication?.documentAttachment ?? '',
    );
    MedicationStatus selectedStatus =
        existingMedication?.status ?? MedicationStatus.active;
    final isEditing = existingMedication != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickStartDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedStartDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(now.year + 10),
              );

              if (picked == null) {
                return;
              }

              setState(() {
                selectedStartDate = picked;
                startDateCtrl.text = _formatDate(picked);
                if (selectedEndDate != null &&
                    selectedEndDate!.isBefore(selectedStartDate)) {
                  selectedEndDate = selectedStartDate;
                  endDateCtrl.text = _formatDate(selectedEndDate!);
                }
              });
            }

            Future<void> pickEndDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedEndDate ?? selectedStartDate,
                firstDate: selectedStartDate,
                lastDate: DateTime(now.year + 10),
              );

              if (picked == null) {
                return;
              }

              setState(() {
                selectedEndDate = picked;
                endDateCtrl.text = _formatDate(picked);
              });
            }

            return CustomDialog(
              title: isEditing
                  ? (t?.editMedication ?? 'Edit Medication')
                  : (t?.addMedication ?? 'Add Medication'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: t?.name ?? 'Name *',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: dosageCtrl,
                      decoration: InputDecoration(
                        labelText: '${t?.dosage ?? "Dosage"} *',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: frequencyCtrl,
                      decoration: InputDecoration(
                        labelText: '${t?.frequency ?? "Frequency"} *',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: startDateCtrl,
                      readOnly: true,
                      onTap: pickStartDate,
                      decoration: InputDecoration(
                        labelText: '${t?.startDate ?? 'Start date'} *',
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: endDateCtrl,
                      readOnly: true,
                      onTap: pickEndDate,
                      decoration: InputDecoration(
                        labelText: t?.endDate ?? 'End date',
                        suffixIcon: selectedEndDate == null
                            ? const Icon(Icons.calendar_today_outlined)
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    selectedEndDate = null;
                                    endDateCtrl.clear();
                                  });
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<MedicationStatus>(
                      initialValue: selectedStatus,
                      items: MedicationStatus.values
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
                    if (nameCtrl.text.trim().isEmpty ||
                        dosageCtrl.text.trim().isEmpty ||
                        frequencyCtrl.text.trim().isEmpty) {
                      return;
                    }

                    final updatedMed = Medication(
                      id:
                          existingMedication?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: 'user123',
                      name: nameCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim(),
                      frequency: frequencyCtrl.text.trim(),
                      startDate: selectedStartDate,
                      endDate: selectedEndDate,
                      status: selectedStatus,
                      documentAttachment: attachmentCtrl.text.trim().isEmpty
                          ? null
                          : attachmentCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      createdAt:
                          existingMedication?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (isEditing) {
                      _dataService.updateMedication(updatedMed);
                    } else {
                      _dataService.addMedication(updatedMed);
                    }

                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? (t?.medicationUpdatedSuccessfully ??
                                      'Medication updated successfully')
                                : (t?.medicationAddedSuccessfully ??
                                      'Medication added successfully'),
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

  Future<void> _showEditMedicationDialog(
    BuildContext context,
    Medication medication,
  ) async {
    _showAddMedicationDialog(context, existingMedication: medication);
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Medication medication,
  ) async {
    final t = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: t?.deleteMedication ?? 'Delete Medication?',
          content: Text(
            '${t?.areYouSureYouWantToDelete ?? "Are you sure you want to delete"} ${medication.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _dataService.deleteMedication(medication.id);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t?.medicationDeletedSuccessfully ??
                            'Medication deleted successfully',
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
