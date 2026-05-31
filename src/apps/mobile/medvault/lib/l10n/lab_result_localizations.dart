import 'app_localizations.dart';

class LabResultCategoryPreset {
  final String name;
  final String label;
  final String description;
  final List<String> suggestedFields;

  const LabResultCategoryPreset({
    required this.name,
    required this.label,
    required this.description,
    this.suggestedFields = const [],
  });
}

extension LabResultCategoryLocalizations on AppLocalizations {
  List<LabResultCategoryPreset> get predefinedLabResultCategories {
    return [
      LabResultCategoryPreset(
        name: 'Complete Blood Count (CBC)',
        label: labCategoryCompleteBloodCountLabel,
        description: labCategoryCompleteBloodCountDescription,
        suggestedFields: const [
          'Hemoglobin',
          'Hematocrit',
          'White Blood Cells',
          'Platelets',
        ],
      ),
      LabResultCategoryPreset(
        name: 'Metabolic Panels (BMP or CMP)',
        label: labCategoryMetabolicPanelsLabel,
        description: labCategoryMetabolicPanelsDescription,
        suggestedFields: const ['Glucose', 'Sodium', 'Potassium', 'Creatinine'],
      ),
      LabResultCategoryPreset(
        name: 'Lipid Panel',
        label: labCategoryLipidPanelLabel,
        description: labCategoryLipidPanelDescription,
        suggestedFields: const [
          'Total Cholesterol',
          'LDL',
          'HDL',
          'Triglycerides',
        ],
      ),
      LabResultCategoryPreset(
        name: 'Thyroid Panel',
        label: labCategoryThyroidPanelLabel,
        description: labCategoryThyroidPanelDescription,
        suggestedFields: const ['TSH', 'Free T4'],
      ),
      LabResultCategoryPreset(
        name: 'Diabetes Monitoring',
        label: labCategoryDiabetesMonitoringLabel,
        description: labCategoryDiabetesMonitoringDescription,
        suggestedFields: const ['Blood Glucose', 'Fasting Glucose'],
      ),
      LabResultCategoryPreset(
        name: 'Hemoglobin A1c',
        label: labCategoryHemoglobinA1cLabel,
        description: labCategoryHemoglobinA1cDescription,
        suggestedFields: const ['Hemoglobin A1c'],
      ),
      LabResultCategoryPreset(
        name: 'Urinalysis',
        label: labCategoryUrinalysisLabel,
        description: labCategoryUrinalysisDescription,
        suggestedFields: const [
          'Protein',
          'Glucose',
          'Ketones',
          'Specific Gravity',
        ],
      ),
      LabResultCategoryPreset(
        name: 'Nutrient Levels',
        label: labCategoryNutrientLevelsLabel,
        description: labCategoryNutrientLevelsDescription,
        suggestedFields: const ['Vitamin D', 'Vitamin B12', 'Ferritin'],
      ),
    ];
  }

  String labResultCategoryLabel(String categoryName) {
    final normalizedName = categoryName.trim().toLowerCase();
    for (final preset in predefinedLabResultCategories) {
      if (preset.name.toLowerCase() == normalizedName) {
        return preset.label;
      }
    }

    return categoryName.trim();
  }

  String labResultCategoryDescription(String categoryName) {
    final normalizedName = categoryName.trim().toLowerCase();
    for (final preset in predefinedLabResultCategories) {
      if (preset.name.toLowerCase() == normalizedName) {
        return preset.description;
      }
    }

    return '';
  }
}
