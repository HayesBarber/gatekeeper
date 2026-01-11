import 'dart:convert';

import 'package:gatekeeper_cli/src/models/auth_token_response.dart';
import 'package:gatekeeper_cli/src/models/challenge_response.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';

class ApiClient {
  ApiClient(this._baseUrl, this._logger);

  final String _baseUrl;
  final Logger _logger;

  Future<ChallengeResponse> postChallenge() async {
    _logger.detail('POSTing challenge request to $_baseUrl/challenge');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenge'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get challenge: ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return ChallengeResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Network error during challenge request: $e');
    }
  }

  Future<AuthTokenResponse> postChallengeVerification(
    Map<String, dynamic> request,
  ) async {
    _logger.detail(
      'POSTing challenge verification to $_baseUrl/challenge/verify',
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenge/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to verify challenge: ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthTokenResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Network error during challenge verification: $e');
    }
  }
}
