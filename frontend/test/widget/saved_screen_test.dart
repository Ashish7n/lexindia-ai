import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/storage/storage_keys.dart';
import 'package:lexindia_frontend/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:lexindia_frontend/features/bookmarks/models/bookmarked_section.dart';
import 'package:lexindia_frontend/features/saved/screens/saved_screen.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';
import 'package:lexindia_frontend/shared/widgets/empty_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SavedScreen Widget Tests', () {
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
        return Future.value(http.Response('Not Found', 404));
      });

      repository = SectionRepository(
        apiClient: ApiClient(client: mockClient, config: testConfig),
      );
    });

    Widget createTestApp({
      BookmarkController? controller,
      SectionRepository? repo,
      VoidCallback? onBrowsePressed,
    }) {
      return MaterialApp(
        home: SavedScreen(
          bookmarkController: controller ?? bookmarkController,
          sectionRepository: repo ?? repository,
          onBrowsePressed: onBrowsePressed,
        ),
      );
    }

    testWidgets(
      'renders heading and correct count for single saved provision',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 42,
              headingEn: 'Acts done in furtherance of common intention',
              headingTe: 'ఉమ్మడి ఉద్దేశంతో చేసిన చర్యలు',
              bookmarkedAt: DateTime.parse('2026-10-21T10:00:00Z'),
            ),
          );
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Saved Sections'), findsOneWidget);
        expect(find.text('1 provision saved'), findsWidgets);
        expect(find.text('BNS § 42'), findsOneWidget);
        expect(
          find.text('Acts done in furtherance of common intention'),
          findsOneWidget,
        );
        expect(find.text('ఉమ్మడి ఉద్దేశంతో చేసిన చర్యలు'), findsOneWidget);
      },
    );

    testWidgets(
      'renders multiple bookmarks with correct plural count and recency ordering',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 41,
              headingEn: 'Act done by a person by reason of mistake of fact',
              bookmarkedAt: DateTime.parse('2026-10-21T09:00:00Z'),
            ),
          );
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 42,
              headingEn: 'Acts done in furtherance of common intention',
              bookmarkedAt: DateTime.parse('2026-10-21T10:00:00Z'),
            ),
          );
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 43,
              headingEn:
                  'When such an act is criminal by reason of its being done',
              bookmarkedAt: DateTime.parse('2026-10-21T11:00:00Z'),
            ),
          );
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('3 provisions saved'), findsWidgets);

        // Section 43 was added last, so it appears first in the list
        final cards = find.byType(Card);
        expect(cards, findsNWidgets(3));

        expect(
          find.descendant(of: cards.at(0), matching: find.text('BNS § 43')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: cards.at(1), matching: find.text('BNS § 42')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: cards.at(2), matching: find.text('BNS § 41')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'missing Telugu heading falls back cleanly to English without error',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 15,
              headingEn: 'Definition of India',
              headingTe: null, // Untranslated
              bookmarkedAt: DateTime.parse('2026-10-21T10:00:00Z'),
            ),
          );
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('BNS § 15'), findsOneWidget);
        expect(find.text('Definition of India'), findsOneWidget);
      },
    );

    testWidgets(
      'long legal headings render without layout overflow on constrained widths',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 100,
              headingEn:
                  'An extremely long legal section heading describing comprehensive offenses '
                  'against public tranquility, lawful assembly, riots, affrays, and related '
                  'statutory liabilities under the new code with multifaceted statutory criteria.',
              headingTe:
                  'చాలా పొడవైన చట్టపరమైన శీర్షిక ప్రజా ప్రశాంతత మరియు చట్టబద్ధమైన సభలకు వ్యతిరేకంగా నేరాలను వివరిస్తుంది',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('BNS § 100'), findsOneWidget);
      },
    );

    testWidgets('empty bookmark collection displays the EmptyState', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await bookmarkController.initialize();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No Bookmarks Yet'), findsOneWidget);
      expect(find.textContaining('No saved sections yet'), findsOneWidget);
      expect(find.text('Browse BNS Sections'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets(
      'browse button in EmptyState triggers onBrowsePressed callback',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
        });
        bool browsePressed = false;

        await tester.pumpWidget(
          createTestApp(onBrowsePressed: () => browsePressed = true),
        );
        await tester.pumpAndSettle();

        final browseButton = find.text('Browse BNS Sections');
        expect(browseButton, findsOneWidget);
        await tester.tap(browseButton);
        await tester.pump();

        expect(browsePressed, isTrue);
      },
    );

    testWidgets(
      'removing the last bookmark returns the screen to the EmptyState',
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

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('BNS § 42'), findsOneWidget);
        expect(find.byType(EmptyState), findsNothing);

        // Tap remove button
        final removeButton = find.byKey(const Key('remove_bookmark_42'));
        expect(removeButton, findsOneWidget);
        await tester.tap(removeButton);
        await tester.pump();
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();

        // Verify EmptyState is now visible
        expect(find.byType(EmptyState), findsOneWidget);
        expect(find.text('No Bookmarks Yet'), findsOneWidget);
        expect(find.text('BNS § 42'), findsNothing);

        // Verify removal confirmation SnackBar
        expect(find.text('BNS § 42 removed from saved'), findsOneWidget);

        // Allow snackbar to dismiss cleanly
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'removing a bookmark calls controller and updates list and count',
      (tester) async {
        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 41,
              headingEn: 'Mistake of fact',
              bookmarkedAt: DateTime.now(),
            ),
          );
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 42,
              headingEn: 'Common intention',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('2 provisions saved'), findsWidgets);
        expect(find.text('BNS § 42'), findsOneWidget);
        expect(find.text('BNS § 41'), findsOneWidget);

        // Remove section 42
        await tester.tap(find.byKey(const Key('remove_bookmark_42')));
        await tester.pump();
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();

        expect(find.text('BNS § 42'), findsNothing);
        expect(find.text('BNS § 41'), findsOneWidget);
        expect(find.text('1 provision saved'), findsWidgets);
        expect(find.text('BNS § 42 removed from saved'), findsOneWidget);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'storage failure on removal displays error feedback without success message and preserves state',
      (tester) async {
        final failingStorage = FailingMockStorageService();
        final errorController = BookmarkController(
          storageService: failingStorage,
        );

        // Pre-populate directly in memory
        await tester.runAsync(() async {
          await errorController.initialize();
        });

        // Add to in-memory directly for testing rollback upon removal
        failingStorage.allowNext = true;
        await tester.runAsync(() async {
          await errorController.addBookmark(
            BookmarkedSection(
              sectionNumber: 42,
              headingEn: 'Common intention',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });
        failingStorage.allowNext = false; // Next write will fail

        await tester.pumpWidget(createTestApp(controller: errorController));
        await tester.pumpAndSettle();

        expect(find.text('BNS § 42'), findsOneWidget);

        // Attempt removal which fails
        await tester.tap(find.byKey(const Key('remove_bookmark_42')));
        await tester.pump();
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Must NOT show success message
        expect(find.text('BNS § 42 removed from saved'), findsNothing);

        // Must show error message with Retry action
        expect(
          find.textContaining('Failed to remove bookmark'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);

        // State must be preserved (rolled back)
        expect(find.text('BNS § 42'), findsOneWidget);
        expect(errorController.isBookmarked(42), isTrue);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'tapping a bookmark card opens SectionDetailScreen for the correct section',
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

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap on Section 42 card (not the remove icon)
        await tester.tap(find.text('Common intention'));
        await tester.pumpAndSettle();

        // Verify SectionDetailScreen opened
        expect(find.byType(SectionDetailScreen), findsOneWidget);
        expect(find.text('BNS § 42'), findsWidgets);
        // Section is bookmarked, so filled icon should be present
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.bookmark),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'bookmark changes made externally update Saved screen reactively',
      (tester) async {
        await bookmarkController.initialize();

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(EmptyState), findsOneWidget);

        // Add a bookmark externally
        await tester.runAsync(() async {
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 99,
              headingEn: 'External section',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });

        await tester.pump();

        // SavedScreen should reactively rebuild
        expect(find.byType(EmptyState), findsNothing);
        expect(find.text('BNS § 99'), findsOneWidget);
        expect(find.text('External section'), findsOneWidget);
        expect(find.text('1 provision saved'), findsWidgets);
      },
    );

    testWidgets(
      'renders persisted bookmark metadata without contacting backend',
      (tester) async {
        final offlineClient = MockClient((request) {
          throw Exception('Backend should not be contacted by SavedScreen');
        });
        final offlineRepo = SectionRepository(
          apiClient: ApiClient(client: offlineClient, config: testConfig),
        );

        await tester.runAsync(() async {
          await bookmarkController.initialize();
          await bookmarkController.addBookmark(
            BookmarkedSection(
              sectionNumber: 10,
              headingEn: 'Offline Section Heading',
              headingTe: 'ఆఫ్‌లైన్ శీర్షిక',
              bookmarkedAt: DateTime.now(),
            ),
          );
        });

        // Pump SavedScreen with offline repository
        await tester.pumpWidget(createTestApp(repo: offlineRepo));
        await tester.pumpAndSettle();

        // Screen renders completely offline
        expect(tester.takeException(), isNull);
        expect(find.text('BNS § 10'), findsOneWidget);
        expect(find.text('Offline Section Heading'), findsOneWidget);
        expect(find.text('ఆఫ్‌లైన్ శీర్షిక'), findsOneWidget);
      },
    );

    testWidgets(
      'previously persisted bookmarks appear after controller initialization from storage',
      (tester) async {
        // Pre-populate SharedPreferences before controller initialization
        final rawJson = jsonEncode([
          {
            'section_number': 300,
            'heading_en': 'Murder provision',
            'heading_te': 'హత్య నిబంధన',
            'bookmarked_at': '2026-10-21T12:00:00.000Z',
          },
        ]);
        SharedPreferences.setMockInitialValues({
          StorageKeys.bookmarks: rawJson,
        });

        final freshStorage = LocalStorageService();
        final freshController = BookmarkController(
          storageService: freshStorage,
        );

        await tester.runAsync(() async {
          await freshController.initialize();
        });

        await tester.pumpWidget(createTestApp(controller: freshController));
        await tester.pumpAndSettle();

        expect(find.text('BNS § 300'), findsOneWidget);
        expect(find.text('Murder provision'), findsOneWidget);
        expect(find.text('హత్య నిబంధన'), findsOneWidget);
        expect(find.text('1 provision saved'), findsWidgets);
      },
    );
  });
}

class FailingMockStorageService extends LocalStorageService {
  bool allowNext = false;

  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<bool> setString(String key, String value) async {
    if (allowNext) {
      return true;
    }
    throw const StorageException('Disk is write-protected');
  }
}
