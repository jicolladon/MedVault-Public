import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_models.dart';
import '../../services/medical_data_service.dart';
import '../../widgets/custom_dialog.dart';

class DiagnosesPage extends StatefulWidget {
  const DiagnosesPage({super.key});

  @override
  State<DiagnosesPage> createState() => _DiagnosesPageState();
}

class _DiagnosesPageState extends State<DiagnosesPage> {
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

  Color _getStatusColor(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.active:
        return Colors.red;
      case DiagnosisStatus.resolved:
        return Colors.green;
    }
  }

  String _getStatusLabel(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.active:
        return 'Active';
      case DiagnosisStatus.resolved:
        return 'Resolved';
    }
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
                '${_dataService.diagnoses.length} ${t?.diagnosesRecorded ?? "diagnoses recorded"}',
                style: theme.textTheme.bodyMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDiagnosisDialog(context),
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
              itemCount: _dataService.diagnoses.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final diagnosis = _dataService.diagnoses[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                diagnosis.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  diagnosis.status,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusLabel(diagnosis.status),
                                style: TextStyle(
                                  color: _getStatusColor(diagnosis.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${t?.date ?? "Date"}: ${_formatDate(diagnosis.date)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        if (diagnosis.duration != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Duration: ${diagnosis.duration}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        if (diagnosis.notes != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${t?.notes ?? "Notes"}: ${diagnosis.notes}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        if (diagnosis.documentAttachment != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Attachment: ${diagnosis.documentAttachment}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddDiagnosisDialog(
                                context,
                                existingDiagnosis: diagnosis,
                              ),
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteDialog(context, diagnosis),
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

  Future<void> _showAddDiagnosisDialog(
    BuildContext context, {
    Diagnosis? existingDiagnosis,
  }) async {
    final t = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existingDiagnosis?.name ?? '');
    var selectedDate = existingDiagnosis?.date ?? DateTime.now();
    final dateCtrl = TextEditingController(text: _formatDate(selectedDate));
    final durationCtrl = TextEditingController(
      text: existingDiagnosis?.duration ?? '',
    );
    final notesCtrl = TextEditingController(
      text: existingDiagnosis?.notes ?? '',
    );
    final attachmentCtrl = TextEditingController(
      text: existingDiagnosis?.documentAttachment ?? '',
    );
    DiagnosisStatus selectedStatus =
        existingDiagnosis?.status ?? DiagnosisStatus.active;
    final isEditing = existingDiagnosis != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(now.year + 10),
              );

              if (picked == null) {
                return;
              }

              setState(() {
                selectedDate = picked;
                dateCtrl.text = _formatDate(picked);
              });
            }

            return CustomDialog(
              title: isEditing
                  ? (t?.editDiagnosis ?? 'Edit Diagnosis')
                  : (t?.addDiagnosis ?? 'Add Diagnosis'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: '${t?.condition ?? "Condition"} *',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      onTap: pickDate,
                      decoration: InputDecoration(
                        labelText: '${t?.date ?? 'Date'} *',
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<DiagnosisStatus>(
                      initialValue: selectedStatus,
                      items: DiagnosisStatus.values
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
                      controller: durationCtrl,
                      decoration: InputDecoration(
                        labelText: t?.duration ?? 'Duration',
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
                    if (nameCtrl.text.trim().isEmpty) {
                      return;
                    }

                    final updatedDiagnosis = Diagnosis(
                      id:
                          existingDiagnosis?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: 'user123',
                      name: nameCtrl.text.trim(),
                      status: selectedStatus,
                      date: selectedDate,
                      duration: durationCtrl.text.trim().isEmpty
                          ? null
                          : durationCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      documentAttachment: attachmentCtrl.text.trim().isEmpty
                          ? null
                          : attachmentCtrl.text.trim(),
                      createdAt: existingDiagnosis?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (isEditing) {
                      _dataService.updateDiagnosis(updatedDiagnosis);
                    } else {
                      _dataService.addDiagnosis(updatedDiagnosis);
                    }

                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? (t?.diagnosisUpdatedSuccessfully ??
                                      'Diagnosis updated successfully')
                                : (t?.diagnosisAddedSuccessfully ??
                                      'Diagnosis added successfully'),
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

  Future<void> _showDeleteDialog(
    BuildContext context,
    Diagnosis diagnosis,
  ) async {
    final t = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: t?.deleteDiagnosis ?? 'Delete Diagnosis?',
          content: Text(
            '${t?.areYouSureYouWantToDelete ?? "Are you sure you want to delete"} ${diagnosis.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _dataService.deleteDiagnosis(diagnosis.id);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t?.diagnosisDeletedSuccessfully ??
                            'Diagnosis deleted successfully',
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
