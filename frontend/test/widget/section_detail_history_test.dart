import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:lexindia_frontend/features/history/controllers/history_controller.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SectionDetailScreen History Integration Widget Tests', () {
    const testConfig = AppConfig(baseUrl: 'http://testserver:8000');

    http.Response utf8Response(String body, int statusCode) {
      return http.Response.bytes(
        utf8.encode(body),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    late LocalStorageService storageService;
    late HistoryController historyController;
    late BookmarkController bookmarkController;
    late SectionRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      historyController = HistoryController(storageService: storageService);
      bookmarkController = BookmarkController(storageService: storageService);

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
        if (path == '/sections/42/language/te') {
          return utf8Response('''
          {
            "section_number": 42,
            "language": "te",
            "heading": "ఉమ్మడి ఉద్దేశంతో అనేక వ్యక్తులు చేసిన చర్యలు",
            "text": "ఒక నేరపూరిత చర్య...",
            "translation_status": "translated"
          }
          ''', 200);
        }
        if (path == '/sections/43') {
          return utf8Response('''
          {
            "section_number": 43,
            "heading_en": "When such an act is criminal by reason of its being done with a criminal knowledge or intention",
            "text_en": "Whenever an act, which is criminal only by reason...",
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

    testWidgets('successfully opened section is recorded in history', (
      tester,
    ) async {
      await historyController.initialize();
      expect(historyController.history, isEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: SectionDetailScreen(
            sectionNumber: 42,
            repository: repository,
            historyController: historyController,
            bookmarkController: bookmarkController,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(historyController.history.length, 1);
      final item = historyController.history.first;
      expect(item.sectionNumber, 42);
      expect(
        item.headingEn,
        'Acts done by several persons in furtherance of common intention',
      );
      expect(item.headingTe, 'ఉమ్మడి ఉద్దేశంతో అనేక వ్యక్తులు చేసిన చర్యలు');
    });

    testWidgets(
      'navigating to next section records the destination section in history',
      (tester) async {
        await historyController.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              historyController: historyController,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(historyController.history.length, 1);
        expect(historyController.history[0].sectionNumber, 42);

        // Tap Next (§ 43)
        await tester.tap(find.text('Next (§ 43)'));
        await tester.pumpAndSettle();

        expect(historyController.history.length, 2);
        expect(historyController.history[0].sectionNumber, 43);
        expect(historyController.history[1].sectionNumber, 42);
      },
    );

    testWidgets(
      'navigating back to an existing section promotes it to top without duplicates',
      (tester) async {
        await historyController.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              historyController: historyController,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(historyController.history[0].sectionNumber, 42);

        // Navigate to 43
        await tester.tap(find.text('Next (§ 43)'));
        await tester.pumpAndSettle();
        expect(historyController.history[0].sectionNumber, 43);
        expect(historyController.history[1].sectionNumber, 42);

        // Navigate back to 42 using Previous button
        await tester.tap(find.text('Previous (§ 42)'));
        await tester.pumpAndSettle();

        // 42 must be promoted to the top, still total 2 items
        expect(historyController.history.length, 2);
        expect(historyController.history[0].sectionNumber, 42);
        expect(historyController.history[1].sectionNumber, 43);
      },
    );

    testWidgets(
      'switching display language does not create duplicate history entries',
      (tester) async {
        await historyController.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              historyController: historyController,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(historyController.history.length, 1);

        // Switch to Telugu
        await tester.tap(find.text('తెలుగు (Telugu)'));
        await tester.pumpAndSettle();

        // History count should remain 1
        expect(historyController.history.length, 1);
        expect(historyController.history[0].sectionNumber, 42);

        // Switch back to English
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        // History count still remains 1
        expect(historyController.history.length, 1);
        expect(historyController.history[0].sectionNumber, 42);
      },
    );

    testWidgets(
      'failed section load does not record nonexistent section in history',
      (tester) async {
        await historyController.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 999, // 404 in mock
              repository: repository,
              historyController: historyController,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error view is shown
        expect(
          find.text('Section 999 was not found in the BNS database.'),
          findsOneWidget,
        );
        // History should remain empty
        expect(historyController.history, isEmpty);
      },
    );

    testWidgets(
      'history persistence failure does not crash the reading screen',
      (tester) async {
        final failingStorage = FailingHistoryMockStorageService();
        final failingHistoryController = HistoryController(
          storageService: failingStorage,
        );
        await failingHistoryController.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              historyController: failingHistoryController,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Screen still renders legal text and heading without crashing
        expect(find.text('BNS § 42'), findsOneWidget);
        expect(
          find.text(
            'Acts done by several persons in furtherance of common intention',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'existing bookmark functionality operates correctly alongside history',
      (tester) async {
        await historyController.initialize();
        await bookmarkController.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              historyController: historyController,
              bookmarkController: bookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check history recorded
        expect(historyController.history.length, 1);
        expect(historyController.history[0].sectionNumber, 42);

        // Bookmark the section
        await tester.tap(find.byKey(const Key('bookmark_action_button')));
        await tester.pump();
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(bookmarkController.isBookmarked(42), isTrue);
        expect(find.text('BNS § 42 saved to bookmarks'), findsOneWidget);

        // Let snackbar dismiss cleanly
        await tester.pump(const Duration(seconds: 4));

        // History state unchanged
        expect(historyController.history.length, 1);
        expect(historyController.history[0].sectionNumber, 42);
      },
    );
  });
}

class FailingHistoryMockStorageService extends LocalStorageService {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<bool> setString(String key, String value) async {
    throw const StorageException('Disk write failure');
  }
}
