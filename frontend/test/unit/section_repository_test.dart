import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';

void main() {
  group('SectionRepository', () {
    const testConfig = AppConfig(baseUrl: 'http://testserver:8000');

    http.Response utf8Response(String body, int statusCode) {
      return http.Response.bytes(
        utf8.encode(body),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    test('getSections validates page and pageSize arguments locally', () async {
      final repository = SectionRepository();

      expect(
        () => repository.getSections(page: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.getSections(pageSize: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.getSections(pageSize: 101),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'getSections sends correct query parameters for numeric search',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/sections/');
          expect(request.url.queryParameters['page'], '1');
          expect(request.url.queryParameters['page_size'], '20');
          expect(request.url.queryParameters['search'], '42');

          return utf8Response('''
          {
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
            "sections": [
              {
                "section_number": 42,
                "heading_en": "Private defence",
                "text_en": "Legal text...",
                "heading_te": "ఆత్మరక్షణ",
                "text_te": "చట్టం...",
                "translation_status": "translated"
              }
            ]
          }
          ''', 200);
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);
        final repository = SectionRepository(apiClient: apiClient);

        final response = await repository.getSections(search: '42');

        expect(response.total, 1);
        expect(response.sections.first.sectionNumber, 42);
        expect(response.sections.first.headingEn, 'Private defence');
      },
    );

    test('getSectionDetail fetches full record including source', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/sections/1');

        return utf8Response('''
          {
            "section_number": 1,
            "heading_en": "Short title",
            "text_en": "Text 1...",
            "heading_te": "శీర్షిక",
            "text_te": "వచనం...",
            "translation_status": "translated",
            "source": "India Code - BNS 2023",
            "updated_at": "2026-10-21 12:00:00"
          }
          ''', 200);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      final detail = await repository.getSectionDetail(1);

      expect(detail.sectionNumber, 1);
      expect(detail.source, 'India Code - BNS 2023');
      expect(detail.updatedAt, '2026-10-21 12:00:00');
    });

    test(
      'getSectionByLanguage rejects unsupported language codes locally',
      () async {
        final repository = SectionRepository();

        expect(
          () => repository.getSectionByLanguage(1, 'hi'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => repository.getSectionByLanguage(1, 'fr'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('getSectionByLanguage fetches Telugu language endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/sections/1/language/te');

        return utf8Response('''
          {
            "section_number": 1,
            "language": "te",
            "heading": "సంక్షిప్త శీర్షిక",
            "text": "వచనం...",
            "translation_status": "translated"
          }
          ''', 200);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      final langSection = await repository.getSectionByLanguage(1, 'te');

      expect(langSection.sectionNumber, 1);
      expect(langSection.language, 'te');
      expect(langSection.isAvailableTelugu, isTrue);
    });

    test('getTranslationProgress fetches translation counts', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/sections/translation/progress');

        return utf8Response('''
          {
            "total_sections": 358,
            "translated_sections": 206,
            "remaining_sections": 152
          }
          ''', 200);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      final progress = await repository.getTranslationProgress();

      expect(progress.totalSections, 358);
      expect(progress.translatedSections, 206);
      expect(progress.remainingSections, 152);
    });
  });
}
