import 'package:flutter/foundation.dart';
// Conditional import or safe check: Platform is only accessed when !kIsWeb
import 'dart:io' as io;

/// Centralized API configuration for LexIndia-AI.
/// Supports development defaults and allows overriding for testing/production.
class AppConfig {
  final String baseUrl;
  final Duration timeout;

  const AppConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  /// Factory for development environments.
  /// Automatically detects target platform:
  /// - Android emulator uses `http://10.0.2.2:8000`
  /// - Web and desktop use `http://127.0.0.1:8000`
  /// Optional [overrideBaseUrl] allows specifying an alternate host (e.g. physical device IP or HTTPS URL).
  factory AppConfig.development({
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) {
    if (overrideBaseUrl != null && overrideBaseUrl.trim().isNotEmpty) {
      return AppConfig(
        baseUrl: _normalizeUrl(overrideBaseUrl),
        timeout: timeout,
      );
    }

    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return AppConfig(baseUrl: _normalizeUrl(envBaseUrl), timeout: timeout);
    }

    String defaultUrl = 'http://127.0.0.1:8000';
    if (!kIsWeb) {
      try {
        if (io.Platform.isAndroid) {
          defaultUrl = 'http://10.0.2.2:8000';
        }
      } catch (_) {
        // Fallback to localhost if Platform check is unavailable
        defaultUrl = 'http://127.0.0.1:8000';
      }
    }

    return AppConfig(baseUrl: defaultUrl, timeout: timeout);
  }

  static String _normalizeUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Builds a fully resolved [Uri] for an API [endpoint] with optional [queryParameters].
  /// Correctly handles leading slashes and filters null query values.
  Uri buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$baseUrl$cleanEndpoint';

    Map<String, String>? stringParams;
    if (queryParameters != null && queryParameters.isNotEmpty) {
      stringParams = {};
      queryParameters.forEach((key, value) {
        if (value != null) {
          stringParams![key] = value.toString();
        }
      });
    }

    final uri = Uri.parse(fullUrl);
    if (stringParams != null && stringParams.isNotEmpty) {
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }
}
