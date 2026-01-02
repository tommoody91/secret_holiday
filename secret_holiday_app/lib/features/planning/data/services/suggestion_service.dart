import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/utils/logger.dart';
import '../models/suggestion_model.dart';

/// Service for getting destination suggestions from the backend
class SuggestionService {
  // Backend API URL - mirrors PhotoUploadService configuration
  static const String _ngrokUrl = 'https://collenchymatous-antony-naggingly.ngrok-free.dev';
  static const bool _useNgrok = true;

  static String get baseUrl {
    if (_useNgrok && !kIsWeb) {
      return _ngrokUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Get destination suggestions based on criteria
  static Future<SuggestionResult> getSuggestions({
    required SuggestionRequest request,
    required String authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/v1/destinations/suggest');

      AppLogger.info('Requesting suggestions from: $uri');
      AppLogger.info('Request body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      AppLogger.info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final suggestionResponse = SuggestionResponse.fromJson(data);

        return SuggestionResult.success(suggestionResponse);
      } else {
        // Parse error response
        String errorMessage = 'Failed to get suggestions';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (_) {}

        AppLogger.error('Suggestion API error: ${response.statusCode} - $errorMessage');
        return SuggestionResult.failure(errorMessage);
      }
    } catch (e, stack) {
      AppLogger.error('Suggestion service error', e, stack);
      return SuggestionResult.failure('Network error: ${e.toString()}');
    }
  }
}

/// Result wrapper for suggestion API calls
class SuggestionResult {
  final SuggestionResponse? data;
  final String? error;
  final bool isSuccess;

  const SuggestionResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory SuggestionResult.success(SuggestionResponse data) => SuggestionResult._(
        data: data,
        isSuccess: true,
      );

  factory SuggestionResult.failure(String error) => SuggestionResult._(
        error: error,
        isSuccess: false,
      );
}
