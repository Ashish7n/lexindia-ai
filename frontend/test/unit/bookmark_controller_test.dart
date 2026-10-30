import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/storage/storage_keys.dart';
import 'package:lexindia_frontend/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:lexindia_frontend/features/bookmarks/models/bookmarked_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BookmarkController Unit Tests', () {
    late LocalStorageService storageService;
    late BookmarkController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      controller = BookmarkController(storageService: storageService);
    });

    test(
      'empty storage produces empty bookmark collection after initialization',
      () async {
        await controller.initialize();
        expect(controller.isInitialized, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.bookmarks, isEmpty);
        expect(controller.errorMessage, isNull);
        expect(controller.isBookmarked(1), isFalse);
      },
    );

    test(
      'adding a new bookmark updates state and persists to storage',
      () async {
        await controller.initialize();

        final bookmark = BookmarkedSection(
          sectionNumber: 42,
          headingEn: 'Common intention',
          headingTe: 'ఉమ్మడి ఉద్దేశం',
          bookmarkedAt: DateTime.parse('2026-10-22T08:00:00Z'),
        );

        bool notified = false;
        controller.addListener(() => notified = true);

        await controller.addBookmark(bookmark);

        expect(notified, isTrue);
        expect(controller.isBookmarked(42), isTrue);
        expect(controller.bookmarks.length, 1);
        expect(controller.bookmarks.first.sectionNumber, 42);

        // Verify persistence in LocalStorageService
        final raw = await storageService.getString(StorageKeys.bookmarks);
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as List;
        expect(decoded.length, 1);
        expect(decoded.first['section_number'], 42);
      },
    );

    test('toggling an existing bookmark removes it', () async {
      await controller.initialize();

      final bookmark = BookmarkedSection(
        sectionNumber: 10,
        headingEn: 'Gender',
        bookmarkedAt: DateTime.now(),
      );

      await controller.addBookmark(bookmark);
      expect(controller.isBookmarked(10), isTrue);

      final isSavedNow = await controller.toggleBookmark(bookmark);
      expect(isSavedNow, isFalse);
      expect(controller.isBookmarked(10), isFalse);
      expect(controller.bookmarks, isEmpty);

      // Verify persisted empty array
      final raw = await storageService.getString(StorageKeys.bookmarks);
      final decoded = jsonDecode(raw!) as List;
      expect(decoded, isEmpty);
    });

    test('toggling an unsaved bookmark adds it', () async {
      await controller.initialize();

      final bookmark = BookmarkedSection(
        sectionNumber: 100,
        headingEn: 'Culpable homicide',
        bookmarkedAt: DateTime.now(),
      );

      expect(controller.isBookmarked(100), isFalse);
      final isSavedNow = await controller.toggleBookmark(bookmark);
      expect(isSavedNow, isTrue);
      expect(controller.isBookmarked(100), isTrue);
      expect(controller.bookmarks.first.sectionNumber, 100);
    });

    test(
      'duplicate entries for the same section number are prevented',
      () async {
        await controller.initialize();

        final b1 = BookmarkedSection(
          sectionNumber: 42,
          headingEn: 'Common intention v1',
          bookmarkedAt: DateTime.parse('2026-10-22T08:00:00Z'),
        );
        final b2 = BookmarkedSection(
          sectionNumber: 42,
          headingEn: 'Common intention v2',
          bookmarkedAt: DateTime.parse('2026-10-22T09:00:00Z'),
        );

        await controller.addBookmark(b1);
        await controller.addBookmark(b2);

        expect(controller.bookmarks.length, 1);
        expect(controller.bookmarks.first.headingEn, 'Common intention v1');
      },
    );

    test(
      'bookmark state survives controller recreation using same storage',
      () async {
        await controller.initialize();

        final bookmark = BookmarkedSection(
          sectionNumber: 302,
          headingEn: 'Punishment for murder',
          bookmarkedAt: DateTime.parse('2026-10-22T10:00:00Z'),
        );
        await controller.addBookmark(bookmark);

        // Recreate controller using the same storage instance
        final newController = BookmarkController(
          storageService: storageService,
        );
        expect(newController.isInitialized, isFalse);

        await newController.initialize();
        expect(newController.isInitialized, isTrue);
        expect(newController.isBookmarked(302), isTrue);
        expect(newController.bookmarks.length, 1);
        expect(newController.bookmarks.first.sectionNumber, 302);
      },
    );

    test(
      'defensively handles completely invalid JSON string without crashing',
      () async {
        await storageService.setString(
          StorageKeys.bookmarks,
          '{not_a_valid_json',
        );

        await controller.initialize();
        expect(controller.isInitialized, isTrue);
        expect(controller.bookmarks, isEmpty);
        expect(controller.isBookmarked(1), isFalse);
      },
    );

    test(
      'defensively handles non-list JSON payload without crashing',
      () async {
        await storageService.setString(
          StorageKeys.bookmarks,
          '{"key": "value"}',
        );

        await controller.initialize();
        expect(controller.isInitialized, isTrue);
        expect(controller.bookmarks, isEmpty);
      },
    );

    test(
      'preserves valid entries when individual item in list is malformed',
      () async {
        final mixedData = [
          {
            'section_number': 42,
            'heading_en': 'Valid Section 42',
            'bookmarked_at': '2026-10-22T08:00:00.000Z',
          },
          {
            'corrupted_field': 'invalid',
            // missing section_number and heading_en
          },
          {
            'section_number': 100,
            'heading_en': 'Valid Section 100',
            'bookmarked_at': '2026-10-22T09:00:00.000Z',
          },
        ];
        await storageService.setString(
          StorageKeys.bookmarks,
          jsonEncode(mixedData),
        );

        await controller.initialize();
        expect(controller.bookmarks.length, 2);
        expect(controller.isBookmarked(42), isTrue);
        expect(controller.isBookmarked(100), isTrue);
        expect(controller.bookmarks[0].sectionNumber, 42);
        expect(controller.bookmarks[1].sectionNumber, 100);
      },
    );

    test(
      'rolls back in-memory state and surfaces error when persistence fails',
      () async {
        // Create a mock storage service that fails on setString
        final failingStorage = FailingMockStorageService();
        final errorController = BookmarkController(
          storageService: failingStorage,
        );
        await errorController.initialize();

        final bookmark = BookmarkedSection(
          sectionNumber: 99,
          headingEn: 'Test failure',
          bookmarkedAt: DateTime.now(),
        );

        await expectLater(
          () => errorController.addBookmark(bookmark),
          throwsA(isA<StorageException>()),
        );

        // Verify in-memory state was rolled back
        expect(errorController.isBookmarked(99), isFalse);
        expect(errorController.bookmarks, isEmpty);
        expect(
          errorController.errorMessage,
          contains('Failed to save bookmark'),
        );
      },
    );

    test(
      'rapid consecutive write operations execute sequentially without corruption',
      () async {
        await controller.initialize();

        final b1 = BookmarkedSection(
          sectionNumber: 1,
          headingEn: 'Sec 1',
          bookmarkedAt: DateTime.now(),
        );
        final b2 = BookmarkedSection(
          sectionNumber: 2,
          headingEn: 'Sec 2',
          bookmarkedAt: DateTime.now(),
        );
        final b3 = BookmarkedSection(
          sectionNumber: 3,
          headingEn: 'Sec 3',
          bookmarkedAt: DateTime.now(),
        );

        // Trigger rapid consecutive adds concurrently
        await Future.wait([
          controller.addBookmark(b1),
          controller.addBookmark(b2),
          controller.addBookmark(b3),
        ]);

        expect(controller.bookmarks.length, 3);
        expect(controller.isBookmarked(1), isTrue);
        expect(controller.isBookmarked(2), isTrue);
        expect(controller.isBookmarked(3), isTrue);
      },
    );
  });
}

class FailingMockStorageService extends LocalStorageService {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<bool> setString(String key, String value) async {
    throw const StorageException('Simulated disk write failure');
  }
}
