import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_models.dart';
import '../../widgets/custom_dialog.dart';

import '../../services/medical_data_service.dart';

class VaccinationsPage extends StatefulWidget {
  const VaccinationsPage({super.key});

  @override
  State<VaccinationsPage> createState() => _VaccinationsPageState();
}

class _VaccinationsPageState extends State<VaccinationsPage> {
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
                '${_dataService.vaccinations.length} ${t?.vaccinationsRecorded ?? "vaccinations recorded"}',
                style: theme.textTheme.bodyMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddVaccinationDialog(context),
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
              itemCount: _dataService.vaccinations.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final vac = _dataService.vaccinations[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vac.vaccineName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Dates: ${vac.dates.map(_formatDate).join(', ')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (vac.documentAttachment != null)
                          Text(
                            'Attachment: ${vac.documentAttachment}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showEditVaccinationDialog(context, vac),
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(context, vac),
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

  Future<void> _showAddVaccinationDialog(
    BuildContext context, {
    Vaccination? existingVaccination,
  }) async {
    final t = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(
      text: existingVaccination?.vaccineName ?? '',
    );
    final selectedDates =
        existingVaccination?.dates
            .map((date) => DateTime(date.year, date.month, date.day))
            .toList(growable: true) ??
        <DateTime>[DateTime.now()];
    selectedDates.sort();
    final attachmentCtrl = TextEditingController(
      text: existingVaccination?.documentAttachment ?? '',
    );
    final isEditing = existingVaccination != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> addDoseDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDates.isEmpty ? now : selectedDates.last,
                firstDate: DateTime(1900),
                lastDate: DateTime(now.year + 10),
              );

              if (picked == null) {
                return;
              }

              final normalized = DateTime(
                picked.year,
                picked.month,
                picked.day,
              );
              final exists = selectedDates.any(
                (date) =>
                    date.year == normalized.year &&
                    date.month == normalized.month &&
                    date.day == normalized.day,
              );
              if (exists) {
                return;
              }

              setState(() {
                selectedDates.add(normalized);
                selectedDates.sort();
              });
            }

            return CustomDialog(
              title: isEditing
                  ? (t?.editVaccination ?? 'Edit Vaccination')
                  : (t?.addVaccination ?? 'Add Vaccination'),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${t?.doseDates ?? 'Dose dates'} *',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (selectedDates.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t?.noDatesSelected ?? 'No dates selected.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: selectedDates
                            .map(
                              (date) => InputChip(
                                label: Text(_formatDate(date)),
                                onDeleted: () {
                                  setState(() {
                                    selectedDates.remove(date);
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: addDoseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(t?.addDate ?? 'Add date'),
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
                    if (nameCtrl.text.trim().isEmpty || selectedDates.isEmpty) {
                      return;
                    }

                    final updatedVaccination = Vaccination(
                      id:
                          existingVaccination?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: 'user123',
                      vaccineName: nameCtrl.text.trim(),
                      dates: List<DateTime>.from(selectedDates),
                      documentAttachment: attachmentCtrl.text.trim().isEmpty
                          ? null
                          : attachmentCtrl.text.trim(),
                      createdAt:
                          existingVaccination?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (isEditing) {
                      _dataService.updateVaccination(updatedVaccination);
                    } else {
                      _dataService.addVaccination(updatedVaccination);
                    }

                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? (t?.vaccinationUpdatedSuccessfully ??
                                      'Vaccination updated successfully')
                                : (t?.vaccinationAddedSuccessfully ??
                                      'Vaccination added successfully'),
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

  Future<void> _showEditVaccinationDialog(
    BuildContext context,
    Vaccination vaccination,
  ) async {
    _showAddVaccinationDialog(context, existingVaccination: vaccination);
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Vaccination vaccination,
  ) async {
    final t = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: t?.deleteVaccination ?? 'Delete Vaccination?',
          content: Text(
            '${t?.areYouSureYouWantToDelete ?? "Are you sure you want to delete"} ${vaccination.vaccineName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _dataService.deleteVaccination(vaccination.id);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t?.vaccinationDeletedSuccessfully ??
                            'Vaccination deleted successfully',
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
