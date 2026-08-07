import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'API error $statusCode: $body';
}

/// Shared JSON HTTP client for the customer application.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _accessToken;

  void setAccessToken(String? token) => _accessToken = token;

  Future<Object?> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Future<Object?> post(String path, {Object? data}) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _headers,
          body: data == null ? null : jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Future<Object?> put(String path, {Object? data}) async {
    final response = await _client
        .put(
          _uri(path),
          headers: _headers,
          body: data == null ? null : jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
    // Free ngrok tunnels return an HTML interstitial to browser user agents
    // unless this request header is present. Native Flutter is unaffected.
    'ngrok-skip-browser-warning': 'true',
    if (_accessToken != null && _accessToken!.isNotEmpty)
      'Authorization': 'Bearer $_accessToken',
  };

  Object? _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

final apiClient = ApiClient();
