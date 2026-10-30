import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/theme/app_colors.dart';
import 'package:lexindia_frontend/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:lexindia_frontend/features/bookmarks/models/bookmarked_section.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SectionDetailScreen Bookmark Integration Widget Tests', () {
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
    late SectionRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      bookmarkController = BookmarkController(storageService: storageService);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/sections/42') {
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
        if (request.url.path == '/sections/42/language/en') {
          return utf8Response('''
          {
            "section_number": 42,
            "language": "en",
            "heading": "Acts done by several persons in furtherance of common intention",
            "text": "When a criminal act is done by several persons..."
          }
          ''', 200);
        }
        if (request.url.path == '/sections/43') {
          return utf8Response('''
          {
            "section_number": 43,
            "heading_en": "When such an act is criminal by reason of its being done with a criminal knowledge or intention",
            "text_en": "Whenever an act, which is criminal only by reason...",
            "heading_te": "",
            "text_te": "",
            "translation_status": "not_translated",
            "source": "India Code"
          }
          ''', 200);
        }
        if (request.url.path == '/sections/43/language/en') {
          return utf8Response('''
          {
            "section_number": 43,
            "language": "en",
            "heading": "When such an act is criminal...",
            "text": "Whenever an act, which is criminal only by reason..."
          }
          ''', 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, config: testConfig);
      repository = SectionRepository(apiClient: apiClient);
    });

    testWidgets('displays outlined bookmark icon when section is not saved', (
      tester,
    ) async {
      await bookmarkController.initialize();
      expect(bookmarkController.isBookmarked(42), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: SectionDetailScreen(
            sectionNumber: 42,
            repository: repository,
            bookmarkController: bookmarkController,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Bookmark button should show outline icon with tooltip 'Bookmark section'
      final outlineFinder = find.byIcon(Icons.bookmark_outline);
      expect(outlineFinder, findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byTooltip('Bookmark section'), findsOneWidget);
    });

    testWidgets(
      'displays filled antique-gold bookmark icon when section is already saved',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 42,
              headingEn: 'Common intention',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });
        expect(bookmarkController.isBookmarked(42), isTrue);

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify filled bookmark icon with antiqueGold color in AppBar
        final filledFinder = find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.bookmark),
        );
        expect(filledFinder, findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark_outline),
          ),
          findsNothing,
        );
        expect(find.byTooltip('Remove bookmark'), findsOneWidget);

        final iconWidget = tester.widget<Icon>(filledFinder);
        expect(iconWidget.color, AppColors.antiqueGold);
      },
    );

    testWidgets(
      'tapping bookmark icon on unsaved section saves it and shows confirmation',
      (tester) async {
        await bookmarkController.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap to save
        await tester.tap(find.byTooltip('Bookmark section'));
        await tester.pump();
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify icon flipped to filled gold in AppBar
        final appBarBookmarkFinder = find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.bookmark),
        );
        expect(appBarBookmarkFinder, findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark_outline),
          ),
          findsNothing,
        );
        expect(bookmarkController.isBookmarked(42), isTrue);

        // Verify success snackbar message while visible
        expect(find.text('BNS § 42 saved to bookmarks'), findsOneWidget);

        // Let snackbar dismiss cleanly
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'tapping bookmark icon on saved section removes it and shows removal feedback',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 42,
              headingEn: 'Common intention',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark),
          ),
          findsOneWidget,
        );

        // Tap to remove
        await tester.tap(find.byTooltip('Remove bookmark'));
        await tester.pump();
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify icon flipped to outline
        final appBarOutlineFinder = find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.bookmark_outline),
        );
        expect(appBarOutlineFinder, findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark),
          ),
          findsNothing,
        );
        expect(bookmarkController.isBookmarked(42), isFalse);

        // Verify removal snackbar message
        expect(find.text('BNS § 42 removed from bookmarks'), findsOneWidget);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'surfaces error snackbar when persistence fails and preserves unbookmarked state',
      (tester) async {
        final failingStorage = FailingMockStorageService();
        final errorController = BookmarkController(
          storageService: failingStorage,
        );
        await tester.runAsync(() => errorController.initialize());

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              bookmarkController: errorController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap to bookmark
        await tester.tap(find.byTooltip('Bookmark section'));
        await tester.pump();
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify error snackbar surfaced
        expect(
          find.textContaining('Failed to update bookmark'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);

        // Verify in-memory state remained unbookmarked and icon did not flip to saved
        final appBarOutlineFinder = find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.bookmark_outline),
        );
        expect(appBarOutlineFinder, findsOneWidget);
        expect(errorController.isBookmarked(42), isFalse);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'navigating between sections updates the bookmark icon for destination section',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          // Section 43 is pre-bookmarked; Section 42 is NOT bookmarked
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 43,
              headingEn: 'When such an act is criminal...',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // At Section 42: Not bookmarked (outline)
        expect(find.text('BNS § 42'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark_outline),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark),
          ),
          findsNothing,
        );

        // Tap Next Section to go to 43
        final nextButtonFinder = find.byKey(const Key('next_section_button'));
        expect(nextButtonFinder, findsOneWidget);
        await tester.tap(nextButtonFinder);
        await tester.pumpAndSettle();

        // At Section 43: Already bookmarked (filled gold)
        expect(find.text('BNS § 43'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark_outline),
          ),
          findsNothing,
        );

        // Tap Previous Section to go back to 42
        final prevButtonFinder = find.byKey(
          const Key('previous_section_button'),
        );
        expect(prevButtonFinder, findsOneWidget);
        await tester.tap(prevButtonFinder);
        await tester.pumpAndSettle();

        // Back at Section 42: Still not bookmarked (outline)
        expect(find.text('BNS § 42'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark_outline),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'bookmark button is disabled while section details are loading',
      (tester) async {
        await bookmarkController.initialize();

        // Delayed network response to verify loading state
        final detailCompleter = Completer<http.Response>();
        final langCompleter = Completer<http.Response>();
        final delayedClient = MockClient((request) {
          if (request.url.path == '/sections/42') {
            return detailCompleter.future;
          }
          if (request.url.path == '/sections/42/language/en') {
            return langCompleter.future;
          }
          return Future.value(http.Response('Not Found', 404));
        });
        final delayedRepo = SectionRepository(
          apiClient: ApiClient(client: delayedClient, config: testConfig),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: delayedRepo,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        // Pump initial frame - still loading
        await tester.pump();
        expect(find.text('Loading section provision...'), findsOneWidget);

        final bookmarkBtn = tester.widget<IconButton>(
          find.byKey(const Key('bookmark_action_button')),
        );
        expect(bookmarkBtn.onPressed, isNull);

        // Complete responses
        detailCompleter.complete(
          utf8Response('''
        {
          "section_number": 42,
          "heading_en": "Heading",
          "text_en": "Text",
          "heading_te": "",
          "text_te": "",
          "translation_status": "not_translated",
          "source": "India Code"
        }
        ''', 200),
        );
        langCompleter.complete(
          utf8Response('''
        {
          "section_number": 42,
          "language": "en",
          "heading": "Heading",
          "text": "Text"
        }
        ''', 200),
        );

        await tester.pumpAndSettle();

        final enabledBookmarkBtn = tester.widget<IconButton>(
          find.byKey(const Key('bookmark_action_button')),
        );
        expect(enabledBookmarkBtn.onPressed, isNotNull);
      },
    );
  });
}

class FailingMockStorageService extends LocalStorageService {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<bool> setString(String key, String value) async {
    throw const StorageException('Disk is write-protected');
  }
}
