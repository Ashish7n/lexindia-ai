import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/core/network/api_exceptions.dart';

void main() {
  group('ApiClient', () {
    const testConfig = AppConfig(
      baseUrl: 'http://testserver:8000',
      timeout: Duration(milliseconds: 500),
    );

    test('executes successful GET request and maps JSON to model', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/sections/');
        expect(request.url.queryParameters['page'], '2');
        expect(request.url.queryParameters['page_size'], '10');

        return http.Response(
          '{"message": "success", "count": 42}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);

      final result = await apiClient.get<int>(
        '/sections/',
        queryParameters: {'page': 2, 'page_size': 10},
        fromJson: (json) => json['count'] as int,
      );

      expect(result, 42);
    });

    test(
      'throws BadRequestException on HTTP 400 with detail message',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"detail": "Unsupported language. Use en or te."}',
            400,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);

        expect(
          () => apiClient.get('/sections/1/language/hi', fromJson: (j) => j),
          throwsA(
            isA<BadRequestException>().having(
              (e) => e.message,
              'message',
              'Unsupported language. Use en or te.',
            ),
          ),
        );
      },
    );

    test('throws NotFoundException on HTTP 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "BNS section not found"}',
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);

      expect(
        () => apiClient.get('/sections/9999', fromJson: (j) => j),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'BNS section not found',
          ),
        ),
      );
    });

    test(
      'throws ValidationException on HTTP 422 with formatted errors',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"detail": [{"loc": ["query", "page"], "msg": "Input should be greater than or equal to 1"}]}',
            422,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);

        expect(
          () => apiClient.get('/sections/?page=0', fromJson: (j) => j),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('Input should be greater than or equal to 1'),
            ),
          ),
        );
      },
    );

    test('throws ServerException on HTTP 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Internal server error"}', 500);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);

      expect(
        () => apiClient.get('/sections/', fromJson: (j) => j),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'throws MalformedResponseException when response is invalid JSON',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('<!DOCTYPE html><html>Server Crash</html>', 200);
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);

        expect(
          () => apiClient.get('/sections/', fromJson: (j) => j),
          throwsA(isA<MalformedResponseException>()),
        );
      },
    );

    test(
      'throws ApiTimeoutException when request exceeds timeout threshold',
      () async {
        final mockClient = MockClient((request) async {
          await Future.delayed(const Duration(milliseconds: 800));
          return http.Response('{"status": "ok"}', 200);
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);

        expect(
          () => apiClient.get('/sections/', fromJson: (j) => j),
          throwsA(isA<ApiTimeoutException>()),
        );
      },
    );
  });

  group('AppConfig', () {
    test('development factory applies default host and timeout', () {
      final config = AppConfig.development();
      expect(config.baseUrl, isNotEmpty);
      expect(config.timeout, const Duration(seconds: 10));
    });

    test('overrideBaseUrl strips trailing slashes and whitespace', () {
      final config = AppConfig.development(
        overrideBaseUrl: '  https://api.lexindia.example.com///  ',
      );
      expect(config.baseUrl, 'https://api.lexindia.example.com');
    });

    test('buildUri formats endpoints and query parameters properly', () {
      const config = AppConfig(baseUrl: 'https://api.lexindia.example.com');
      final uriWithoutSlash = config.buildUri('sections/1');
      expect(
        uriWithoutSlash.toString(),
        'https://api.lexindia.example.com/sections/1',
      );

      final uriWithSlash = config.buildUri('/sections/1');
      expect(
        uriWithSlash.toString(),
        'https://api.lexindia.example.com/sections/1',
      );

      final uriWithParams = config.buildUri('/sections/', {
        'page': 2,
        'page_size': 20,
        'search': 'theft',
        'unused': null,
      });
      expect(uriWithParams.queryParameters, {
        'page': '2',
        'page_size': '20',
        'search': 'theft',
      });
    });
  });
}
