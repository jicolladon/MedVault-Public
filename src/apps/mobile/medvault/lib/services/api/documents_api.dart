import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_client.dart';
import 'auth_api.dart';
import '../../models/documents_models.dart';

class DocumentsApiFilePayload {
  final String fileName;
  final String? mimeType;
  final List<int> payload;

  const DocumentsApiFilePayload({
    required this.fileName,
    required this.mimeType,
    required this.payload,
  });
}

abstract class DocumentsApiClient {
  Future<DocumentExtractionResult?> extractDocumentData({
    required String documentId,
    required List<DocumentsApiFilePayload> files,
    required String preferredLanguage,
  });
}

class PendingDocumentsApiClient implements DocumentsApiClient {
  const PendingDocumentsApiClient({ApiClient? apiClient})
    : _apiClient = apiClient;

  final ApiClient? _apiClient;

  @override
  Future<DocumentExtractionResult?> extractDocumentData({
    required String documentId,
    required List<DocumentsApiFilePayload> files,
    required String preferredLanguage,
  }) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      return null;
    }

    final response = await apiClient.postMultipart(
      '/api/documents/extract',
      fields: <String, String>{'preferredLanguage': preferredLanguage},
      files: files
          .map(
            (file) => http.MultipartFile.fromBytes(
              'files',
              file.payload,
              filename: file.fileName,
            ),
          )
          .toList(growable: false),
      timeout: const Duration(seconds: 300),
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractError(response.body));
    }

    final decoded = jsonDecode(response.body);
    final envelope = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    final data = envelope['data'] ?? envelope;

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected extraction response payload.');
    }

    return DocumentExtractionResult.fromJson(data);
  }

  String _extractError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        return body;
      }

      final errors = json['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }

      return (json['message'] as String?) ?? body;
    } catch (_) {
      return body;
    }
  }
}
