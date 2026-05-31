import 'dart:convert';

import '../api_client.dart';
import '../../models/api_models.dart';
import 'auth_api.dart';

class ProfileApi {
  final ApiClient _client;

  ProfileApi(this._client);

  Future<UserProfile> getProfile() async {
    final response = await _client.get('/api/user/profile');

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to load profile');
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    final response = await _client.put(
      '/api/user/profile',
      body: request.toJson(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to update profile');
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    return UserProfile.fromJson(data);
  }

  Future<Map<String, dynamic>> getCompleteness() async {
    final response = await _client.get('/api/user/profile/completeness');

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to load completeness');
    }

    final json = jsonDecode(response.body);
    return json['data'] ?? json;
  }

  Future<List<ProfileEmergencyContact>> getEmergencyContacts() async {
    final response = await _client.get('/api/user/profile/emergency-contacts');

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to load emergency contacts',
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(ProfileEmergencyContact.fromJson)
        .toList(growable: false);
  }

  Future<List<ProfileEmergencyContact>> replaceEmergencyContacts({
    required List<ProfileEmergencyContact> contacts,
  }) async {
    final response = await _client.put(
      '/api/user/profile/emergency-contacts',
      body: {'contacts': contacts.map((contact) => contact.toJson()).toList()},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to update emergency contacts',
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] ?? json;
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(ProfileEmergencyContact.fromJson)
        .toList(growable: false);
  }
}
