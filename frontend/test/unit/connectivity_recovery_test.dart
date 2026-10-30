import 'dart:io' show SocketException;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/core/network/api_exceptions.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';

void main() {
  group('Connectivity & Recovery Unit Tests', () {
    const testConfig = AppConfig(
      baseUrl: 'http://testserver:8000',
      timeout: Duration(milliseconds: 300),
    );

    test(
      'ApiClient maps SocketException to truthful NetworkException without leaking OS errno',
      () async {
        final mockClient = MockClient((request) async {
          throw const SocketException(
            'Connection refused (OS Error: Connection refused, errno = 111)',
          );
        });

        final client = ApiClient(client: mockClient, config: testConfig);

        try {
          await client.get<Map<String, dynamic>>(
            '/sections/',
            fromJson: (j) => j as Map<String, dynamic>,
          );
          fail('Expected NetworkException');
        } on NetworkException catch (e) {
          expect(
            e.message,
            contains('Unable to connect to the legal database server'),
          );
          expect(e.message, contains('verify the backend service is running'));
          expect(e.message, isNot(contains('errno = 111')));
          expect(e.message, isNot(contains('device offline')));
        }
      },
    );

    test(
      'ApiClient maps http.ClientException to clean NetworkException',
      () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('XMLHttpRequest error');
        });

        final client = ApiClient(client: mockClient, config: testConfig);

        expect(
          () => client.get<Map<String, dynamic>>(
            '/sections/',
            fromJson: (j) => j as Map<String, dynamic>,
          ),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              contains('Unable to connect to the legal database server'),
            ),
          ),
        );
      },
    );

    test('ApiClient maps TimeoutException to ApiTimeoutException', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return http.Response('{"status": "ok"}', 200);
      });

      final client = ApiClient(client: mockClient, config: testConfig);

      expect(
        () => client.get<Map<String, dynamic>>(
          '/sections/',
          fromJson: (j) => j as Map<String, dynamic>,
        ),
        throwsA(
          isA<ApiTimeoutException>().having(
            (e) => e.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
    });

    test(
      'Recovery: subsequent request succeeds after network failure',
      () async {
        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            throw const SocketException('Network down');
          }
          return http.Response(
            '{"section_number": 1, "heading_en": "Title", "has_telugu": true}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = ApiClient(client: mockClient, config: testConfig);

        // First call fails
        expect(
          () => client.get<int>(
            '/sections/1',
            fromJson: (j) => j['section_number'] as int,
          ),
          throwsA(isA<NetworkException>()),
        );

        // Second call recovers and succeeds
        final result = await client.get<int>(
          '/sections/1',
          fromJson: (j) => j['section_number'] as int,
        );
        expect(result, 1);
        expect(callCount, 2);
      },
    );

    test(
      'SectionRepository propagates clean ApiException and recovers on retry',
      () async {
        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            return http.Response(
              '{"detail": "Service Temporarily Unavailable"}',
              503,
            );
          }
          return http.Response(
            '{"sections": [{"section_number": 1, "heading_en": "Definitions", "heading_te": "", "has_telugu": false}], "total": 1, "page": 1, "page_size": 20, "total_pages": 1}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = ApiClient(client: mockClient, config: testConfig);
        final repo = SectionRepository(apiClient: client);

        // Attempt 1 fails with ServerException
        expect(
          () => repo.getSections(page: 1, pageSize: 20),
          throwsA(
            isA<ServerException>().having(
              (e) => e.statusCode,
              'statusCode',
              503,
            ),
          ),
        );

        // Attempt 2 succeeds after server recovery
        final response = await repo.getSections(page: 1, pageSize: 20);
        expect(response.total, 1);
        expect(response.sections.first.sectionNumber, 1);
        expect(callCount, 2);
      },
    );

    test(
      'Generic unexpected exceptions retain error details without exposing raw stack trace in message',
      () async {
        final mockClient = MockClient((request) async {
          throw StateError('Unexpected memory corruption failure');
        });

        final client = ApiClient(client: mockClient, config: testConfig);

        try {
          await client.get('/test', fromJson: (j) => j);
          fail('Expected ApiException');
        } on ApiException catch (e) {
          expect(
            e.message,
            contains(
              'An unexpected error occurred while communicating with the server',
            ),
          );
          expect(
            e.details.toString(),
            contains('Unexpected memory corruption failure'),
          );
        }
      },
    );
  });
}
