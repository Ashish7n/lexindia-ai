import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/theme/theme_controller.dart';
import 'package:lexindia_frontend/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:lexindia_frontend/features/bookmarks/models/bookmarked_section.dart';
import 'package:lexindia_frontend/features/browse/screens/browse_screen.dart';
import 'package:lexindia_frontend/features/history/controllers/history_controller.dart';
import 'package:lexindia_frontend/features/history/models/history_item.dart';
import 'package:lexindia_frontend/features/home/screens/home_screen.dart';
import 'package:lexindia_frontend/features/saved/screens/saved_screen.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';
import 'package:lexindia_frontend/navigation/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HomeScreen Dashboard Widget Tests', () {
    const testConfig = AppConfig(baseUrl: 'http://testserver:8000');

    http.Response utf8Response(String body, int statusCode) {
      return http.Response.bytes(
        utf8.encode(body),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    late LocalStorageService storageService;
    late BookmarkController bookmarkController;
    late HistoryController historyController;
    late SectionRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      bookmarkController = BookmarkController(storageService: storageService);
      historyController = HistoryController(storageService: storageService);

      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/sections/42') {
          return utf8Response('''
          {
            "section_number": 42,
            "heading_en": "Acts done by several persons in furtherance of common intention",
            "text_en": "When a criminal act is done by several persons...",
            "heading_te": "ఉమ్మడి ఉద్దేశంతో అనేక వ్యక్తులు చేసిన చర్యలు",
            "text_te": "ఒక నేరపూరిత చర్య...",
            "translation_status": "translated",
            "source": "India Code",
            "updated_at": "2026-10-21 12:00:00"
          }
          ''', 200);
        }
        if (path == '/sections/42/language/en') {
          return utf8Response('''
          {
            "section_number": 42,
            "language": "en",
            "heading": "Acts done by several persons in furtherance of common intention",
            "text": "When a criminal act is done by several persons..."
          }
          ''', 200);
        }
        if (path == '/sections') {
          return utf8Response('''
          {
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
            "sections": [
              {
                "section_number": 42,
                "heading_en": "Common intention",
                "text_en": "Act done by several...",
                "heading_te": "",
                "text_te": "",
                "translation_status": "not_translated",
                "source": "India Code"
              }
            ]
          }
          ''', 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      repository = SectionRepository(apiClient: apiClient);
    });

    testWidgets(
      'Home displays title, search field, and clean empty states on first launch',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await historyController.initialize();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              bookmarkController: bookmarkController,
              historyController: historyController,
              sectionRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. App Identity
        expect(find.text('BHARATIYA NYAYA SANHITA, 2023'), findsOneWidget);
        expect(find.text('Legal Reference Application'), findsOneWidget);
        expect(
          find.text('Legal information reference only. Not legal advice.'),
          findsOneWidget,
        );

        // 2. Search Field
        expect(find.byKey(const Key('home_search_input')), findsOneWidget);
        expect(
          find.byKey(const Key('home_search_submit_button')),
          findsOneWidget,
        );

        // 3. Browse Shortcut
        expect(find.text('Browse 358 BNS Sections'), findsOneWidget);

        // 4. Empty States
        expect(find.text('No recently viewed provisions'), findsOneWidget);
        expect(find.text('No saved provisions'), findsOneWidget);
      },
    );

    testWidgets(
      'Recent provisions renders up to 5 items in correct recency order',
      (tester) async {
        await tester.runAsync(() async {
          await historyController.initialize();
          await bookmarkController.initialize();

          // Add 7 items: Section 1 through Section 7
          for (int i = 1; i <= 7; i++) {
            await historyController.recordVisit(
              HistoryItem(
                sectionNumber: i,
                headingEn: 'Section $i Heading',
                headingTe: i % 2 == 0 ? 'సెక్షన్ $i శీర్షిక' : null,
                lastViewedAt: DateTime.now().add(Duration(seconds: i)),
              ),
            );
          }
        });

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              bookmarkController: bookmarkController,
              historyController: historyController,
              sectionRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should display recent count badge '5 recent'
        expect(find.text('5 recent'), findsOneWidget);

        // Most recent 5: 7, 6, 5, 4, 3 with 'BNS SECTION X' badges
        expect(find.byKey(const Key('recent_section_card_7')), findsOneWidget);
        expect(find.text('BNS SECTION 7'), findsOneWidget);
        expect(find.byKey(const Key('recent_section_card_6')), findsOneWidget);
        expect(find.text('BNS SECTION 6'), findsOneWidget);
        expect(find.byKey(const Key('recent_section_card_5')), findsOneWidget);
        expect(find.text('BNS SECTION 5'), findsOneWidget);
        expect(find.byKey(const Key('recent_section_card_4')), findsOneWidget);
        expect(find.text('BNS SECTION 4'), findsOneWidget);
        expect(find.byKey(const Key('recent_section_card_3')), findsOneWidget);
        expect(find.text('BNS SECTION 3'), findsOneWidget);

        // Sections 1 and 2 must not be shown on Home (capped at 5)
        expect(find.byKey(const Key('recent_section_card_2')), findsNothing);
        expect(find.byKey(const Key('recent_section_card_1')), findsNothing);
      },
    );

    testWidgets('Missing Telugu heading falls back to English without crash', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await historyController.initialize();
        await bookmarkController.initialize();

        await historyController.recordVisit(
          HistoryItem(
            sectionNumber: 99,
            headingEn: 'English Only Heading',
            headingTe: null,
            lastViewedAt: DateTime.now(),
          ),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('English Only Heading'), findsOneWidget);
      expect(find.byKey(const Key('recent_section_card_99')), findsOneWidget);
    });

    testWidgets('Saved summary displays correct singular and plural wording', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await bookmarkController.initialize();
        await historyController.initialize();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 0 bookmarks
      expect(find.text('No saved provisions'), findsOneWidget);

      // 1 bookmark
      await tester.runAsync(() async {
        await bookmarkController.addBookmark(
          BookmarkedSection(
            sectionNumber: 42,
            headingEn: 'Common intention',
            bookmarkedAt: DateTime.now(),
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(find.text('1 provision saved'), findsOneWidget);

      // 2 bookmarks
      await tester.runAsync(() async {
        await bookmarkController.addBookmark(
          BookmarkedSection(
            sectionNumber: 43,
            headingEn: 'Criminal knowledge',
            bookmarkedAt: DateTime.now(),
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(find.text('2 provisions saved'), findsOneWidget);
    });

    testWidgets('Narrow viewport does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await bookmarkController.initialize();
        await historyController.initialize();

        await historyController.recordVisit(
          HistoryItem(
            sectionNumber: 100,
            headingEn:
                'A very long English legal heading describing complicated actions and severe statutory liabilities under the Bharatiya Nyaya Sanhita',
            headingTe:
                'భారతీయ న్యాయ సంహిత కింద చాలా పొడవైన చట్టపరమైన శీర్షిక వివరణ మరియు విభాగాలు',
            lastViewedAt: DateTime.now(),
          ),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('recent_section_card_100')), findsOneWidget);
    });

    testWidgets('Submitting search query invokes callback with trimmed text', (
      tester,
    ) async {
      String? searchedQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: repository,
            onSearchSubmitted: (q) => searchedQuery = q,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(
        find.byKey(const Key('home_search_input')),
        '  42  ',
      );
      await tester.tap(find.byKey(const Key('home_search_submit_button')));
      await tester.pumpAndSettle();

      expect(searchedQuery, '42');
    });

    testWidgets('Submitting via keyboard action triggers search callback', (
      tester,
    ) async {
      String? searchedQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: repository,
            onSearchSubmitted: (q) => searchedQuery = q,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('home_search_input')),
        'theft',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(searchedQuery, 'theft');
    });

    testWidgets('Blank search submission does not invoke callback', (
      tester,
    ) async {
      String? searchedQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: repository,
            onSearchSubmitted: (q) => searchedQuery = q,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('home_search_input')), '   ');
      await tester.tap(find.byKey(const Key('home_search_submit_button')));
      await tester.pumpAndSettle();

      expect(searchedQuery, isNull);
    });

    testWidgets('Tapping recent section item opens SectionDetailScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await historyController.initialize();
        await bookmarkController.initialize();

        await historyController.recordVisit(
          HistoryItem(
            sectionNumber: 42,
            headingEn: 'Common intention',
            headingTe: 'ఉమ్మడి ఉద్దేశం',
            lastViewedAt: DateTime.now(),
          ),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure visible in SingleChildScrollView then tap on recent section card 42
      await tester.ensureVisible(
        find.byKey(const Key('recent_section_card_42')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recent_section_card_42')));
      await tester.pumpAndSettle();

      expect(find.byType(SectionDetailScreen), findsOneWidget);
      expect(find.text('BNS § 42'), findsWidgets);
    });

    testWidgets('MainNavigation integration: Search from Home opens Browse', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await bookmarkController.initialize();
        await historyController.initialize();
      });
      final themeController = ThemeController();

      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigation(
            themeController: themeController,
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify currently on Home
      expect(find.byType(HomeScreen), findsOneWidget);

      // Search for '42'
      await tester.enterText(find.byKey(const Key('home_search_input')), '42');
      await tester.tap(find.byKey(const Key('home_search_submit_button')));
      await tester.pumpAndSettle();

      // Should now have navigated to Browse screen with query prefilled
      expect(find.byType(BrowseScreen), findsOneWidget);
      final searchField = tester.widget<TextField>(find.byType(TextField));
      expect(searchField.controller?.text, '42');
    });

    testWidgets(
      'MainNavigation integration: Saved shortcut opens SavedScreen',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await historyController.initialize();

          // Add 1 bookmark
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 42,
              headingEn: 'Common intention',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });
        final themeController = ThemeController();

        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigation(
              themeController: themeController,
              bookmarkController: bookmarkController,
              historyController: historyController,
              sectionRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ensure visible then tap Open button in Saved section
        await tester.ensureVisible(
          find.byKey(const Key('home_open_saved_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('home_open_saved_button')));
        await tester.pumpAndSettle();

        // Should now be on SavedScreen
        expect(find.byType(SavedScreen), findsOneWidget);
        expect(find.text('Saved Sections'), findsOneWidget);
      },
    );

    testWidgets('Home renders offline from cached controller data', (
      tester,
    ) async {
      // Mock that throws network error
      final offlineClient = MockClient((_) async => throw Exception('Offline'));
      final offlineRepo = SectionRepository(
        apiClient: ApiClient(client: offlineClient, config: testConfig),
      );

      await tester.runAsync(() async {
        await bookmarkController.initialize();
        await historyController.initialize();

        await historyController.recordVisit(
          HistoryItem(
            sectionNumber: 50,
            headingEn: 'Offline Section',
            lastViewedAt: DateTime.now(),
          ),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            bookmarkController: bookmarkController,
            historyController: historyController,
            sectionRepository: offlineRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Renders cached recent section without throwing
      expect(find.text('Offline Section'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Recently viewed badges format section numbers as BNS SECTION X',
      (tester) async {
        await tester.runAsync(() async {
          await historyController.initialize();
          await bookmarkController.initialize();

          await historyController.recordVisit(
            HistoryItem(
              sectionNumber: 33,
              headingEn: 'Act done by one person',
              headingTe: null,
              lastViewedAt: DateTime.now().subtract(
                const Duration(seconds: 10),
              ),
            ),
          );
          await historyController.recordVisit(
            HistoryItem(
              sectionNumber: 34,
              headingEn: 'Acts done by several persons',
              headingTe: null,
              lastViewedAt: DateTime.now(),
            ),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              bookmarkController: bookmarkController,
              historyController: historyController,
              sectionRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('BNS SECTION 34'), findsOneWidget);
        expect(find.text('BNS SECTION 33'), findsOneWidget);
        expect(find.textContaining('§ 34'), findsNothing);
        expect(find.textContaining('§ 33'), findsNothing);
      },
    );
  });
}
