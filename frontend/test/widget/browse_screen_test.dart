import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/features/browse/screens/browse_screen.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';
import 'package:lexindia_frontend/features/sections/widgets/section_card.dart';

void main() {
  group('BrowseScreen Widget Tests', () {
    const testConfig = AppConfig(baseUrl: 'http://testserver:8000');

    http.Response utf8Response(String body, int statusCode) {
      return http.Response.bytes(
        utf8.encode(body),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    testWidgets('loads and renders paginated sections on initial open', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/sections/');
        expect(request.url.queryParameters['page'], '1');

        return utf8Response('''
        {
          "total": 358,
          "page": 1,
          "page_size": 20,
          "total_pages": 18,
          "sections": [
            {
              "section_number": 1,
              "heading_en": "Short title and commencement",
              "text_en": "This Act may be called...",
              "heading_te": "సంక్షిప్త శీర్షిక",
              "text_te": "ఈ చట్టాన్ని...",
              "translation_status": "translated"
            },
            {
              "section_number": 2,
              "heading_en": "Definitions",
              "text_en": "In this Sanhita...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated"
            }
          ]
        }
        ''', 200);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(home: BrowseScreen(repository: repository)),
      );

      // Verify loading indicator is shown initially
      expect(find.text('Fetching BNS legal provisions...'), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify header count
      expect(find.text('358 Sections'), findsOneWidget);

      // Verify section cards
      expect(find.byType(SectionCard), findsNWidgets(2));
      expect(find.text('BNS § 1'), findsOneWidget);
      expect(find.text('Short title and commencement'), findsOneWidget);
      expect(find.text('BNS § 2'), findsOneWidget);
      expect(find.text('Definitions'), findsOneWidget);

      // Verify Telugu availability tag vs English Only tag
      expect(find.text('Telugu'), findsOneWidget);
      expect(find.text('English Only'), findsOneWidget);

      // Verify pagination bar
      expect(find.text('Page 1 of 18'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('executes debounced search and exact numeric queries', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        final search = request.url.queryParameters['search'];
        if (search == '42') {
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
                "text_en": "When harm other than death...",
                "heading_te": "ఆత్మరక్షణ",
                "text_te": "చట్టం...",
                "translation_status": "translated"
              }
            ]
          }
          ''', 200);
        }

        return utf8Response('''
        {
          "total": 358,
          "page": 1,
          "page_size": 20,
          "total_pages": 18,
          "sections": [
            {
              "section_number": 1,
              "heading_en": "Short title",
              "text_en": "Text...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated"
            }
          ]
        }
        ''', 200);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(home: BrowseScreen(repository: repository)),
      );

      await tester.pumpAndSettle();
      expect(find.text('BNS § 1'), findsOneWidget);

      // Enter search '42'
      await tester.enterText(find.byType(TextField), '42');
      // Wait for debounce timer (300ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Expect exact match section 42
      expect(find.text('BNS § 42'), findsOneWidget);
      expect(find.text('Private defence'), findsOneWidget);
      expect(find.text('BNS § 1'), findsNothing);

      // Clear search via suffix button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Back to initial results
      expect(find.text('BNS § 1'), findsOneWidget);
    });

    testWidgets('shows EmptyState when no sections match search', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        return utf8Response('''
        {
          "total": 0,
          "page": 1,
          "page_size": 20,
          "total_pages": 0,
          "sections": []
        }
        ''', 200);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(home: BrowseScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Matching Provisions Found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);
    });

    testWidgets('shows ErrorView on network failure and allows retry', (
      tester,
    ) async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Internal Server Error', 500);
        }
        return utf8Response('''
        {
          "total": 1,
          "page": 1,
          "page_size": 20,
          "total_pages": 1,
          "sections": [
            {
              "section_number": 1,
              "heading_en": "Recovered Title",
              "text_en": "Text...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated"
            }
          ]
        }
        ''', 200);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(home: BrowseScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Provisions'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered Title'), findsOneWidget);
    });

    testWidgets('tapping a section card navigates to SectionDetailScreen', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/sections/1') {
          return utf8Response('''
          {
            "section_number": 1,
            "heading_en": "Short title and commencement",
            "text_en": "Detailed legal text of section 1...",
            "heading_te": "సంక్షిప్త శీర్షిక",
            "text_te": "తెలుగు వచనం...",
            "translation_status": "translated",
            "source": "India Code - BNS 2023",
            "updated_at": "2026-10-21 12:00:00"
          }
          ''', 200);
        }
        if (request.url.path == '/sections/1/language/en') {
          return utf8Response('''
          {
            "section_number": 1,
            "language": "en",
            "heading": "Short title and commencement",
            "text": "Detailed legal text of section 1..."
          }
          ''', 200);
        }
        return utf8Response('''
        {
          "total": 1,
          "page": 1,
          "page_size": 20,
          "total_pages": 1,
          "sections": [
            {
              "section_number": 1,
              "heading_en": "Short title and commencement",
              "text_en": "Text...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated"
            }
          ]
        }
        ''', 200);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(home: BrowseScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      // Tap section 1 card
      await tester.tap(find.text('Short title and commencement'));
      await tester.pumpAndSettle();

      // Verify SectionDetailScreen opened
      expect(find.byType(SectionDetailScreen), findsOneWidget);
      expect(find.text('Detailed legal text of section 1...'), findsOneWidget);
      expect(find.text('STATUTORY PROVENANCE'), findsOneWidget);
    });
  });
}
