import 'dart:convert';

import '../api_client.dart';
import '../../models/api_models.dart';
import 'auth_api.dart';

class MedicalApi {
  final ApiClient _client;

  MedicalApi(this._client);

  Future<void> saveOnboardingMedicalInfo({
    String? bloodType,
    List<Map<String, dynamic>> allergies = const [],
    List<Map<String, dynamic>> medications = const [],
    List<Map<String, dynamic>> diagnoses = const [],
    List<Map<String, dynamic>> vaccinations = const [],
  }) async {
    final response = await _client.post(
      '/api/medical/onboarding',
      body: {
        'bloodType': bloodType,
        'allergies': allergies,
        'medications': medications,
        'diagnoses': diagnoses,
        'vaccinations': vaccinations,
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to save medical information',
      );
    }
  }

  Future<MedicalSummary> getSummary() async {
    final response = await _client.get('/api/medical/summary');

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to load medical summary');
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return MedicalSummary.fromJson(data);
  }
}
