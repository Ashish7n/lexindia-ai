import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';

void main() {
  group('SectionDetailScreen Widget Tests', () {
    const testConfig = AppConfig(baseUrl: 'http://testserver:8000');

    http.Response utf8Response(String body, int statusCode) {
      return http.Response.bytes(
        utf8.encode(body),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    testWidgets('renders complete section provision and provenance', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/sections/1') {
          return utf8Response('''
          {
            "section_number": 1,
            "heading_en": "Short title and commencement",
            "text_en": "Complete legal text of provision 1 with full sub-clauses.",
            "heading_te": "సంక్షిప్త శీర్షిక",
            "text_te": "తెలుగు వచనం...",
            "translation_status": "translated",
            "source": "India Code - Bharatiya Nyaya Sanhita, 2023",
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
            "text": "Complete legal text of provision 1 with full sub-clauses."
          }
          ''', 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SectionDetailScreen(sectionNumber: 1, repository: repository),
        ),
      );

      // Verify initial loading view
      expect(find.text('Loading section provision...'), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify title & content
      expect(find.text('BNS § 1'), findsOneWidget);
      expect(find.text('Short title and commencement'), findsOneWidget);
      expect(
        find.text('Complete legal text of provision 1 with full sub-clauses.'),
        findsOneWidget,
      );

      // Verify provenance
      expect(find.text('STATUTORY PROVENANCE'), findsOneWidget);
      expect(
        find.text('India Code - Bharatiya Nyaya Sanhita, 2023'),
        findsOneWidget,
      );
    });

    testWidgets('switches to Telugu and displays translation disclaimer', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/sections/1') {
          return utf8Response('''
          {
            "section_number": 1,
            "heading_en": "Short title",
            "text_en": "English text...",
            "heading_te": "సంక్షిప్త శీర్షిక",
            "text_te": "తెలుగు చట్ట వచనం పూర్తి నిబంధన.",
            "translation_status": "translated",
            "source": "India Code",
            "updated_at": "2026-10-21 12:00:00"
          }
          ''', 200);
        }
        if (request.url.path == '/sections/1/language/en') {
          return utf8Response('''
          {
            "section_number": 1,
            "language": "en",
            "heading": "Short title",
            "text": "English text..."
          }
          ''', 200);
        }
        if (request.url.path == '/sections/1/language/te') {
          return utf8Response('''
          {
            "section_number": 1,
            "language": "te",
            "heading": "సంక్షిప్త శీర్షిక",
            "text": "తెలుగు చట్ట వచనం పూర్తి నిబంధన.",
            "translation_status": "translated"
          }
          ''', 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SectionDetailScreen(sectionNumber: 1, repository: repository),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Telugu
      await tester.tap(find.text('తెలుగు (Telugu)'));
      await tester.pumpAndSettle();

      // Verify Telugu heading and text
      expect(find.text('సంక్షిప్త శీర్షిక'), findsOneWidget);
      expect(find.text('తెలుగు చట్ట వచనం పూర్తి నిబంధన.'), findsOneWidget);

      // Verify disclaimer tag
      expect(
        find.text(
          'Telugu reference translation (Draft / Informational reference only).',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows untranslated notice and allows switching back to English',
      (tester) async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/sections/250') {
            return utf8Response('''
          {
            "section_number": 250,
            "heading_en": "Taking gift to screen offender",
            "text_en": "Whoever accepts any gratification...",
            "heading_te": "",
            "text_te": "",
            "translation_status": "not_translated",
            "source": "India Code",
            "updated_at": "2026-10-21 12:00:00"
          }
          ''', 200);
          }
          if (request.url.path == '/sections/250/language/en') {
            return utf8Response('''
          {
            "section_number": 250,
            "language": "en",
            "heading": "Taking gift to screen offender",
            "text": "Whoever accepts any gratification..."
          }
          ''', 200);
          }
          if (request.url.path == '/sections/250/language/te') {
            // Live backend returns HTTP 200 with empty text and not_translated
            return utf8Response('''
          {
            "section_number": 250,
            "language": "te",
            "heading": "",
            "text": "",
            "translation_status": "not_translated"
          }
          ''', 200);
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);
        final repository = SectionRepository(apiClient: apiClient);

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 250,
              repository: repository,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to Telugu
        await tester.tap(find.text('తెలుగు (Telugu)'));
        await tester.pumpAndSettle();

        // Verify honest untranslated notice
        expect(
          find.text(
            'Telugu translation is not yet available for this section.',
          ),
          findsOneWidget,
        );
        expect(find.text('View English Provision'), findsOneWidget);

        // Tap 'View English Provision'
        await tester.tap(find.text('View English Provision'));
        await tester.pumpAndSettle();

        // Verify English text is shown
        expect(find.text('Taking gift to screen offender'), findsOneWidget);
        expect(
          find.text('Whoever accepts any gratification...'),
          findsOneWidget,
        );
      },
    );

    testWidgets('copy button triggers copy feedback', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/sections/1') {
          return utf8Response('''
          {
            "section_number": 1,
            "heading_en": "Short title",
            "text_en": "Text 1...",
            "heading_te": "",
            "text_te": "",
            "translation_status": "not_translated",
            "source": "India Code",
            "updated_at": ""
          }
          ''', 200);
        }
        if (request.url.path == '/sections/1/language/en') {
          return utf8Response('''
          {
            "section_number": 1,
            "language": "en",
            "heading": "Short title",
            "text": "Text 1..."
          }
          ''', 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SectionDetailScreen(sectionNumber: 1, repository: repository),
        ),
      );

      await tester.pumpAndSettle();

      // Tap copy action button
      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify SnackBar feedback
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('BNS § 1 copied to clipboard'), findsOneWidget);
    });

    testWidgets(
      'navigates from Section 42 to Section 41 on Previous tap and Section 43 on Next tap',
      (tester) async {
        final requestedUrls = <String>[];

        final mockClient = MockClient((request) async {
          requestedUrls.add(request.url.path);
          final path = request.url.path;

          if (path == '/sections/42') {
            return utf8Response('''
            {
              "section_number": 42,
              "heading_en": "Heading for Section 42",
              "text_en": "Text content of Section 42...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/42/language/en') {
            return utf8Response('''
            {
              "section_number": 42,
              "language": "en",
              "heading": "Heading for Section 42",
              "text": "Text content of Section 42..."
            }
            ''', 200);
          }
          if (path == '/sections/41') {
            return utf8Response('''
            {
              "section_number": 41,
              "heading_en": "Heading for Section 41",
              "text_en": "Text content of Section 41...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/41/language/en') {
            return utf8Response('''
            {
              "section_number": 41,
              "language": "en",
              "heading": "Heading for Section 41",
              "text": "Text content of Section 41..."
            }
            ''', 200);
          }
          if (path == '/sections/43') {
            return utf8Response('''
            {
              "section_number": 43,
              "heading_en": "Heading for Section 43",
              "text_en": "Text content of Section 43...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/43/language/en') {
            return utf8Response('''
            {
              "section_number": 43,
              "language": "en",
              "heading": "Heading for Section 43",
              "text": "Text content of Section 43..."
            }
            ''', 200);
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);
        final repository = SectionRepository(apiClient: apiClient);

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial Section 42
        expect(find.text('BNS § 42'), findsOneWidget);
        expect(find.text('Heading for Section 42'), findsOneWidget);
        expect(find.text('Previous (§ 41)'), findsOneWidget);
        expect(find.text('Next (§ 43)'), findsOneWidget);

        // Tap Previous (§ 41)
        await tester.tap(find.byKey(const Key('previous_section_button')));
        await tester.pumpAndSettle();

        // Verify navigated to Section 41
        expect(find.text('BNS § 41'), findsOneWidget);
        expect(find.text('Heading for Section 41'), findsOneWidget);
        expect(find.text('Text content of Section 41...'), findsOneWidget);
        expect(find.text('Previous (§ 40)'), findsOneWidget);
        expect(find.text('Next (§ 42)'), findsOneWidget);
        expect(requestedUrls, contains('/sections/41'));

        // Tap Next (§ 42)
        await tester.tap(find.byKey(const Key('next_section_button')));
        await tester.pumpAndSettle();

        expect(find.text('BNS § 42'), findsOneWidget);

        // Tap Next (§ 43)
        await tester.tap(find.byKey(const Key('next_section_button')));
        await tester.pumpAndSettle();

        // Verify navigated to Section 43
        expect(find.text('BNS § 43'), findsOneWidget);
        expect(find.text('Heading for Section 43'), findsOneWidget);
        expect(find.text('Text content of Section 43...'), findsOneWidget);
        expect(find.text('Previous (§ 42)'), findsOneWidget);
        expect(find.text('Next (§ 44)'), findsOneWidget);
        expect(requestedUrls, contains('/sections/43'));
      },
    );

    testWidgets(
      'boundary handling: Previous disabled at Section 1, Next disabled at Section 358',
      (tester) async {
        final mockClient = MockClient((request) async {
          final path = request.url.path;
          if (path == '/sections/1') {
            return utf8Response('''
            {
              "section_number": 1,
              "heading_en": "First Section Heading",
              "text_en": "First section text...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/1/language/en') {
            return utf8Response('''
            {
              "section_number": 1,
              "language": "en",
              "heading": "First Section Heading",
              "text": "First section text..."
            }
            ''', 200);
          }
          if (path == '/sections/358') {
            return utf8Response('''
            {
              "section_number": 358,
              "heading_en": "Last Section Heading",
              "text_en": "Last section text...",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/358/language/en') {
            return utf8Response('''
            {
              "section_number": 358,
              "language": "en",
              "heading": "Last Section Heading",
              "text": "Last section text..."
            }
            ''', 200);
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);
        final repository = SectionRepository(apiClient: apiClient);

        // Test Section 1
        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(sectionNumber: 1, repository: repository),
          ),
        );
        await tester.pumpAndSettle();

        final prevButtonSection1 = tester.widget<OutlinedButton>(
          find.byKey(const Key('previous_section_button')),
        );
        final nextButtonSection1 = tester.widget<OutlinedButton>(
          find.byKey(const Key('next_section_button')),
        );

        expect(prevButtonSection1.onPressed, isNull);
        expect(nextButtonSection1.onPressed, isNotNull);
        expect(find.text('Previous'), findsOneWidget);
        expect(find.text('Next (§ 2)'), findsOneWidget);

        // Test Section 358
        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 358,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final prevButtonSection358 = tester.widget<OutlinedButton>(
          find.byKey(const Key('previous_section_button')),
        );
        final nextButtonSection358 = tester.widget<OutlinedButton>(
          find.byKey(const Key('next_section_button')),
        );

        expect(prevButtonSection358.onPressed, isNotNull);
        expect(nextButtonSection358.onPressed, isNull);
        expect(find.text('Previous (§ 357)'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      },
    );

    testWidgets(
      'retains selected language across navigation and shows fallback when untranslated',
      (tester) async {
        final mockClient = MockClient((request) async {
          final path = request.url.path;

          if (path == '/sections/10') {
            return utf8Response('''
            {
              "section_number": 10,
              "heading_en": "Section 10 English",
              "text_en": "Text 10 English",
              "heading_te": "సెక్షన్ 10 తెలుగు",
              "text_te": "పాఠం 10 తెలుగు",
              "translation_status": "translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/10/language/en') {
            return utf8Response('''
            {
              "section_number": 10,
              "language": "en",
              "heading": "Section 10 English",
              "text": "Text 10 English"
            }
            ''', 200);
          }
          if (path == '/sections/10/language/te') {
            return utf8Response('''
            {
              "section_number": 10,
              "language": "te",
              "heading": "సెక్షన్ 10 తెలుగు",
              "text": "పాఠం 10 తెలుగు",
              "translation_status": "translated"
            }
            ''', 200);
          }
          if (path == '/sections/11') {
            return utf8Response('''
            {
              "section_number": 11,
              "heading_en": "Section 11 English",
              "text_en": "Text 11 English",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/11/language/te') {
            return utf8Response('''
            {
              "section_number": 11,
              "language": "te",
              "heading": "",
              "text": "",
              "translation_status": "not_translated"
            }
            ''', 200);
          }
          if (path == '/sections/11/language/en') {
            return utf8Response('''
            {
              "section_number": 11,
              "language": "en",
              "heading": "Section 11 English",
              "text": "Text 11 English"
            }
            ''', 200);
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);
        final repository = SectionRepository(apiClient: apiClient);

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 10,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Telugu on Section 10
        await tester.tap(find.text('తెలుగు (Telugu)'));
        await tester.pumpAndSettle();

        expect(find.text('సెక్షన్ 10 తెలుగు'), findsOneWidget);

        // Tap Next (§ 11) while Telugu is selected
        await tester.tap(find.byKey(const Key('next_section_button')));
        await tester.pumpAndSettle();

        // Section 11 has untranslated Telugu: verify fallback UI is shown
        expect(find.text('BNS § 11'), findsOneWidget);
        expect(
          find.text(
            'Telugu translation is not yet available for this section.',
          ),
          findsOneWidget,
        );
        expect(find.text('View English Provision'), findsOneWidget);

        // Tap View English Provision
        await tester.tap(find.text('View English Provision'));
        await tester.pumpAndSettle();

        expect(find.text('Section 11 English'), findsOneWidget);
        expect(find.text('Text 11 English'), findsOneWidget);
      },
    );

    testWidgets('failed navigation displays error state and allows retry', (
      tester,
    ) async {
      int attempt = 0;

      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/sections/20') {
          return utf8Response('''
            {
              "section_number": 20,
              "heading_en": "Section 20 English",
              "text_en": "Text 20",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
        }
        if (path == '/sections/20/language/en') {
          return utf8Response('''
            {
              "section_number": 20,
              "language": "en",
              "heading": "Section 20 English",
              "text": "Text 20"
            }
            ''', 200);
        }
        if (path == '/sections/21') {
          attempt++;
          if (attempt == 1) {
            return http.Response('Server Error', 500);
          }
          return utf8Response('''
            {
              "section_number": 21,
              "heading_en": "Section 21 Recovered",
              "text_en": "Text 21 Recovered",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
        }
        if (path == '/sections/21/language/en') {
          return utf8Response('''
            {
              "section_number": 21,
              "language": "en",
              "heading": "Section 21 Recovered",
              "text": "Text 21 Recovered"
            }
            ''', 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      final repository = SectionRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SectionDetailScreen(sectionNumber: 20, repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Next (§ 21) -> Fails on attempt 1
      await tester.tap(find.byKey(const Key('next_section_button')));
      await tester.pumpAndSettle();

      // Verify error view with Retry button
      expect(find.text('Unable to Load Provisions'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry -> Attempt 2 succeeds
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify Section 21 successfully recovered
      expect(find.text('BNS § 21'), findsOneWidget);
      expect(find.text('Section 21 Recovered'), findsOneWidget);
      expect(find.text('Text 21 Recovered'), findsOneWidget);
    });

    testWidgets(
      'rapid navigation drops stale responses when requests complete out of order',
      (tester) async {
        final slowCompleter = Completer<http.Response>();

        final mockClient = MockClient((request) async {
          final path = request.url.path;

          if (path == '/sections/50') {
            return utf8Response('''
            {
              "section_number": 50,
              "heading_en": "Section 50 Heading",
              "text_en": "Section 50 text",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/50/language/en') {
            return utf8Response('''
            {
              "section_number": 50,
              "language": "en",
              "heading": "Section 50 Heading",
              "text": "Section 50 text"
            }
            ''', 200);
          }
          if (path == '/sections/49' || path == '/sections/49/language/en') {
            // Simulated delayed slow response
            return slowCompleter.future;
          }
          if (path == '/sections/51') {
            return utf8Response('''
            {
              "section_number": 51,
              "heading_en": "Section 51 Heading",
              "text_en": "Section 51 text",
              "heading_te": "",
              "text_te": "",
              "translation_status": "not_translated",
              "source": "India Code",
              "updated_at": ""
            }
            ''', 200);
          }
          if (path == '/sections/51/language/en') {
            return utf8Response('''
            {
              "section_number": 51,
              "language": "en",
              "heading": "Section 51 Heading",
              "text": "Section 51 text"
            }
            ''', 200);
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(client: mockClient, config: testConfig);
        final repository = SectionRepository(apiClient: apiClient);

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 50,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Trigger navigation to Section 49 (which is slow/delayed)
        final state = tester.state<SectionDetailScreenState>(
          find.byType(SectionDetailScreen),
        );
        state.navigateToSectionForTesting(49);
        await tester.pump();

        // 2. Before 49 completes, trigger navigation to Section 51 (fast)
        state.navigateToSectionForTesting(51);
        await tester.pumpAndSettle();

        // Section 51 should be rendered now
        expect(find.text('BNS § 51'), findsOneWidget);
        expect(find.text('Section 51 Heading'), findsOneWidget);

        // 3. Now complete the delayed response for Section 49
        slowCompleter.complete(
          utf8Response('''
          {
            "section_number": 49,
            "heading_en": "Stale Section 49 Heading",
            "text_en": "Stale Section 49 text",
            "heading_te": "",
            "text_te": "",
            "translation_status": "not_translated",
            "source": "India Code",
            "updated_at": ""
          }
          ''', 200),
        );
        await tester.pumpAndSettle();

        // Verify that Section 51 is STILL displayed and stale Section 49 was dropped
        expect(find.text('BNS § 51'), findsOneWidget);
        expect(find.text('Section 51 Heading'), findsOneWidget);
        expect(find.text('Stale Section 49 Heading'), findsNothing);
      },
    );
  });
}
