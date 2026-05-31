import 'package:flutter/material.dart';
import '../core/di/service_locator.dart';
import '../core/theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
import 'medical/allergies_page.dart';
import 'medical/diagnoses_page.dart';
import 'medical/medications_page.dart';
import 'medical/vaccinations_page.dart';
import '../services/medical_data_service.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/medvault_page_header.dart';

import '../models/medical_models.dart';

class MedicalInformationPage extends StatefulWidget {
  const MedicalInformationPage({super.key});

  @override
  State<MedicalInformationPage> createState() => _MedicalInformationPageState();
}

class _MedicalInformationPageState extends State<MedicalInformationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final MedicalDataService _dataService;

  @override
  void initState() {
    super.initState();
    _dataService = ServiceLocator.instance.medicalDataService;
    _tabController = TabController(length: 5, vsync: this);
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {});
  }

  Future<void> _showEditBloodTypeDialog(BuildContext context) async {
    final t = AppLocalizations.of(context);
    String selectedType = _dataService.bloodType;
    final types = BloodGroup.valuesList;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CustomDialog(
              title: t?.editBloodType ?? 'Edit Blood Type',
              primaryActionLabel: t?.save ?? 'Save',
              primaryActionIcon: Icons.save_outlined,
              onPrimaryActionPressed: () {
                _dataService.updateBloodType(selectedType);
                Navigator.pop(context);
              },
              secondaryActionLabel: t?.cancel ?? 'Cancel',
              content: DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: CommonDialogInput.decoration(null),
                items: types
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedType = val);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          MedVaultPageHeader(
            title: t?.medicalInformation ?? 'Medical Information',
            subtitle:
                t?.yourCompleteHealthProfile ?? 'Your complete health profile',
            leading: canPop
                ? IconButton(
                    tooltip: t?.onboardingBack,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                padding: const EdgeInsets.all(4),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                isScrollable: false,
                tabs: const [
                  Tab(icon: Icon(Icons.home_outlined)),
                  Tab(icon: Icon(Icons.warning_amber_rounded)),
                  Tab(icon: Icon(Icons.medication_outlined)),
                  Tab(icon: Icon(Icons.vaccines_outlined)),
                  Tab(icon: Icon(Icons.medical_services_outlined)),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHomeTab(context, t, theme),
                  const AllergiesPage(),
                  const MedicationsPage(),
                  const VaccinationsPage(),
                  const DiagnosesPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(
    BuildContext context,
    AppLocalizations? t,
    ThemeData theme,
  ) {
    final criticalAllergies = _dataService.allergies
        .where(
          (a) =>
              a.status == AllergyStatus.active &&
              a.severity == AllergySeverity.severe,
        )
        .toList();
    final activeDiagnoses = _dataService.diagnoses
        .where((d) => d.status == DiagnosisStatus.active)
        .toList();

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE53935),
                  Color(0xFF8B0000),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showEditBloodTypeDialog(context),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.water_drop_outlined,
                                color: Colors.white,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                t?.bloodType ?? 'Blood Type',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.edit, color: Colors.white, size: 18),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _dataService.bloodType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (criticalAllergies.isNotEmpty) ...[
            _buildSectionCard(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: t?.allergies ?? 'Critical Allergies',
              count: criticalAllergies.length,
              child: Column(
                children: criticalAllergies.map((allergy) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allergy.substance,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7F1D1D),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                allergy.reaction,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Severe',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_dataService.medications.isNotEmpty) ...[
            _buildSectionCard(
              icon: Icons.link,
              iconColor: const Color(0xFF3B82F6),
              title: t?.medications ?? 'Current Medications',
              count: _dataService.medications.length,
              child: Column(
                children: _dataService.medications.map((med) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${med.frequency} - ${med.dosage}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_dataService.vaccinations.isNotEmpty) ...[
            _buildSectionCard(
              icon: Icons.vaccines_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: t?.vaccinations ?? 'Recent Vaccinations',
              count: _dataService.vaccinations.length,
              child: Column(
                children: _dataService.vaccinations.map((vac) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vac.vaccineName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vac.dates.map(_formatDate).join(', '),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (activeDiagnoses.isNotEmpty) ...[
            _buildSectionCard(
              icon: Icons.monitor_heart_outlined,
              iconColor: const Color(0xFF10B981),
              title: t?.diagnoses ?? 'Active Diagnoses',
              count: activeDiagnoses.length,
              child: Column(
                children: activeDiagnoses.map((diag) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      border: Border.all(color: const Color(0xFF6EE7B7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF059669),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  diag.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF065F46),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA7F3D0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                diag.status == DiagnosisStatus.active
                                    ? 'Active'
                                    : 'Resolved',
                                style: const TextStyle(
                                  color: Color(0xFF064E3B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (diag.notes != null && diag.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            diag.notes!,
                            style: const TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${_formatDate(diag.date)}',
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
