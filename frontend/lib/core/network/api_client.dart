import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException, HttpException;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_exceptions.dart';

/// Reusable HTTP API client for LexIndia-AI.
/// Wraps [http.Client] with timeout handling, safe JSON parsing, and typed exception mapping.
class ApiClient {
  final http.Client _client;
  final AppConfig config;
  final bool _isCustomClient;

  ApiClient({http.Client? client, AppConfig? config})
    : _client = client ?? http.Client(),
      config = config ?? AppConfig.development(),
      _isCustomClient = client != null;

  /// Executes an HTTP GET request to the given [endpoint].
  /// Encodes [queryParameters], applies timeout, parses JSON safely, and executes [fromJson].
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    final uri = config.buildUri(endpoint, queryParameters);

    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(
            config.timeout,
            onTimeout: () => throw const ApiTimeoutException(),
          );

      return _handleResponse<T>(response, fromJson);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
        'Unable to connect to the legal database server. Please verify the backend service is running.',
      );
    } on HttpException {
      throw const NetworkException(
        'A communication error occurred with the legal database server. Please try again.',
      );
    } on http.ClientException {
      throw const NetworkException(
        'Unable to connect to the legal database server. Please verify the backend service is running.',
      );
    } on FormatException catch (e) {
      throw MalformedResponseException(
        'Unable to parse response JSON: ${e.message}',
      );
    } on TimeoutException {
      throw const ApiTimeoutException();
    } catch (e) {
      throw ApiException(
        'An unexpected error occurred while communicating with the server. Please try again.',
        details: e.toString(),
      );
    }
  }

  T _handleResponse<T>(
    http.Response response,
    T Function(dynamic json) fromJson,
  ) {
    final statusCode = response.statusCode;

    // Safely decode response body bytes as UTF-8
    dynamic decodedBody;
    String rawBodyString = '';
    try {
      if (response.bodyBytes.isNotEmpty) {
        rawBodyString = utf8.decode(response.bodyBytes);
        if (rawBodyString.trim().isNotEmpty) {
          decodedBody = jsonDecode(rawBodyString);
        }
      }
    } on FormatException catch (e) {
      if (statusCode >= 200 && statusCode < 300) {
        throw MalformedResponseException(
          'Failed to parse success JSON response: ${e.message}',
          details: rawBodyString,
        );
      }
    }

    // Extract detail message from error payload if available
    String errorMessage = 'Request failed with status $statusCode';
    if (decodedBody is Map && decodedBody.containsKey('detail')) {
      final detail = decodedBody['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else if (detail is List) {
        // FastAPI validation errors
        errorMessage = detail
            .map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString())
            .join('; ');
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (decodedBody == null) {
        throw const MalformedResponseException('Empty response body received');
      }
      try {
        return fromJson(decodedBody);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw MalformedResponseException(
          'Failed to map response to model: $e',
          details: decodedBody,
        );
      }
    }

    switch (statusCode) {
      case 400:
        throw BadRequestException(errorMessage, details: decodedBody);
      case 404:
        throw NotFoundException(errorMessage, details: decodedBody);
      case 422:
        throw ValidationException(errorMessage, details: decodedBody);
      default:
        if (statusCode >= 500 && statusCode < 600) {
          throw ServerException(
            errorMessage,
            statusCode: statusCode,
            details: decodedBody,
          );
        }
        throw ApiException(
          errorMessage,
          statusCode: statusCode,
          details: decodedBody,
        );
    }
  }

  void dispose() {
    if (!_isCustomClient) {
      _client.close();
    }
  }
}
