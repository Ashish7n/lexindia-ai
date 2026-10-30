/// Base exception for all API operations in LexIndia-AI.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Thrown when a network-level failure occurs (e.g., DNS failure, offline device, refused connection).
class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Unable to connect to the legal database server. Please check your network connection.',
  ]);
}

/// Thrown when an HTTP request exceeds the configured timeout threshold.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([
    super.message =
        'The request to the legal database timed out. Please try again.',
  ]);
}

/// Thrown on HTTP 400 Bad Request (e.g., unsupported language code requested).
class BadRequestException extends ApiException {
  const BadRequestException(super.message, {super.details})
    : super(statusCode: 400);
}

/// Thrown on HTTP 404 Not Found (e.g., nonexistent BNS section number).
class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.details})
    : super(statusCode: 404);
}

/// Thrown on HTTP 422 Unprocessable Content (e.g., page < 1 or page_size > 100).
class ValidationException extends ApiException {
  const ValidationException(super.message, {super.details})
    : super(statusCode: 422);
}

/// Thrown on HTTP 5xx Server Errors.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode = 500, super.details});
}

/// Thrown when the server response cannot be parsed as JSON or has an unexpected shape.
class MalformedResponseException extends ApiException {
  const MalformedResponseException(super.message, {super.details});
}
