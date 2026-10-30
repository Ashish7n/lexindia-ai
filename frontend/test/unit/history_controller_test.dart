import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/storage/storage_keys.dart';
import 'package:lexindia_frontend/features/history/controllers/history_controller.dart';
import 'package:lexindia_frontend/features/history/models/history_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HistoryController Unit Tests', () {
    late LocalStorageService storageService;
    late HistoryController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      controller = HistoryController(storageService: storageService);
    });

    test(
      'empty storage produces empty history collection after initialization',
      () async {
        await controller.initialize();
        expect(controller.isInitialized, isTrue);
        expect(controller.history, isEmpty);
        expect(controller.count, 0);
        expect(controller.errorMessage, isNull);
      },
    );

    test(
      'recording a new section updates state and persists to storage',
      () async {
        await controller.initialize();
        final item = HistoryItem(
          sectionNumber: 42,
          headingEn: 'Common intention',
          lastViewedAt: DateTime.parse('2026-10-22T10:00:00Z'),
        );

        await controller.recordVisit(item);

        expect(controller.count, 1);
        expect(controller.history.first.sectionNumber, 42);
        expect(controller.getHistoryItem(42), isNotNull);

        // Verify persistence in LocalStorageService
        final raw = await storageService.getString(StorageKeys.recentHistory);
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as List;
        expect(decoded.length, 1);
        expect(decoded.first['section_number'], 42);
      },
    );

    test(
      're-visiting an existing section moves it to the top with updated timestamp',
      () async {
        await controller.initialize();
        final t1 = DateTime.parse('2026-10-22T08:00:00Z');
        final t2 = DateTime.parse('2026-10-22T09:00:00Z');
        final t3 = DateTime.parse('2026-10-22T10:00:00Z');

        await controller.recordVisit(
          HistoryItem(sectionNumber: 1, headingEn: 'Title 1', lastViewedAt: t1),
        );
        await controller.recordVisit(
          HistoryItem(sectionNumber: 2, headingEn: 'Title 2', lastViewedAt: t2),
        );

        // Initial order: [2, 1]
        expect(controller.history.map((h) => h.sectionNumber).toList(), [2, 1]);

        // Re-visit section 1 with newer timestamp t3
        await controller.recordVisit(
          HistoryItem(sectionNumber: 1, headingEn: 'Title 1', lastViewedAt: t3),
        );

        // New order: [1, 2]
        expect(controller.count, 2);
        expect(controller.history.map((h) => h.sectionNumber).toList(), [1, 2]);
        expect(controller.history.first.lastViewedAt, t3);
      },
    );

    test(
      'duplicate section numbers are strictly prevented in history',
      () async {
        await controller.initialize();
        final now = DateTime.now();

        await controller.recordVisit(
          HistoryItem(
            sectionNumber: 42,
            headingEn: 'Section 42',
            lastViewedAt: now,
          ),
        );
        await controller.recordVisit(
          HistoryItem(
            sectionNumber: 42,
            headingEn: 'Section 42',
            lastViewedAt: now,
          ),
        );

        expect(controller.count, 1);
      },
    );

    test('maximum history limit of 20 items is strictly respected', () async {
      await controller.initialize();
      expect(HistoryController.maxHistoryItems, 20);

      // Record 25 unique sections (1 to 25)
      for (int i = 1; i <= 25; i++) {
        await controller.recordVisit(
          HistoryItem(
            sectionNumber: i,
            headingEn: 'Section $i',
            lastViewedAt: DateTime.now(),
          ),
        );
      }

      // Must be capped at 20
      expect(controller.count, 20);
      expect(controller.history.length, 20);

      // Most recent (25) is first; sections 1..5 were evicted
      expect(controller.history.first.sectionNumber, 25);
      expect(controller.history.last.sectionNumber, 6);
      expect(controller.getHistoryItem(1), isNull);
      expect(controller.getHistoryItem(5), isNull);
      expect(controller.getHistoryItem(6), isNotNull);
    });

    test(
      'history state survives controller recreation using same storage',
      () async {
        await controller.initialize();
        await controller.recordVisit(
          HistoryItem(
            sectionNumber: 42,
            headingEn: 'Common intention',
            headingTe: 'ఉమ్మడి ఉద్దేశం',
            lastViewedAt: DateTime.parse('2026-10-22T10:00:00Z'),
          ),
        );

        // Create new controller with same storage
        final newController = HistoryController(storageService: storageService);
        await newController.initialize();

        expect(newController.count, 1);
        final item = newController.history.first;
        expect(item.sectionNumber, 42);
        expect(item.headingEn, 'Common intention');
        expect(item.headingTe, 'ఉమ్మడి ఉద్దేశం');
      },
    );

    test(
      'defensively handles completely invalid JSON string without crashing',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.recentHistory: '{corrupt json syntax!!}',
        });

        final freshStorage = LocalStorageService();
        final freshController = HistoryController(storageService: freshStorage);

        await freshController.initialize();
        expect(freshController.isInitialized, isTrue);
        expect(freshController.history, isEmpty);
        expect(
          freshController.errorMessage,
          contains('Failed to load history'),
        );
      },
    );

    test(
      'defensively handles non-list JSON payload without crashing',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.recentHistory: jsonEncode({'not_a_list': true}),
        });

        final freshStorage = LocalStorageService();
        final freshController = HistoryController(storageService: freshStorage);

        await freshController.initialize();
        expect(freshController.isInitialized, isTrue);
        expect(freshController.history, isEmpty);
        expect(freshController.errorMessage, isNull);
      },
    );

    test(
      'preserves valid entries when individual item in list is malformed',
      () async {
        final mixedPayload = jsonEncode([
          {
            'section_number': 42,
            'heading_en': 'Valid Section',
            'last_viewed_at': '2026-10-22T08:00:00.000Z',
          },
          {'bad_entry': 'missing required fields'},
          {
            'section_number': 43,
            'heading_en': 'Another Valid Section',
            'last_viewed_at': '2026-10-22T08:05:00.000Z',
          },
        ]);

        SharedPreferences.setMockInitialValues({
          StorageKeys.recentHistory: mixedPayload,
        });

        final freshStorage = LocalStorageService();
        final freshController = HistoryController(storageService: freshStorage);

        await freshController.initialize();
        expect(freshController.isInitialized, isTrue);
        expect(freshController.count, 2);
        expect(freshController.history.map((h) => h.sectionNumber).toList(), [
          42,
          43,
        ]);
      },
    );

    test(
      'rolls back in-memory state and surfaces error when persistence fails',
      () async {
        final failingStorage = FailingMockStorageService();
        final errorController = HistoryController(
          storageService: failingStorage,
        );
        await errorController.initialize();

        final item = HistoryItem(
          sectionNumber: 42,
          headingEn: 'Common intention',
          lastViewedAt: DateTime.now(),
        );

        await expectLater(
          () => errorController.recordVisit(item),
          throwsA(isA<StorageException>()),
        );

        // Verify in-memory state rolled back to empty
        expect(errorController.history, isEmpty);
        expect(
          errorController.errorMessage,
          contains('Failed to record history visit'),
        );
      },
    );

    test(
      'rapid consecutive write operations execute sequentially without corruption',
      () async {
        await controller.initialize();

        // Launch 5 visits concurrently
        await Future.wait([
          controller.recordVisit(
            HistoryItem(
              sectionNumber: 1,
              headingEn: 'S1',
              lastViewedAt: DateTime.now(),
            ),
          ),
          controller.recordVisit(
            HistoryItem(
              sectionNumber: 2,
              headingEn: 'S2',
              lastViewedAt: DateTime.now(),
            ),
          ),
          controller.recordVisit(
            HistoryItem(
              sectionNumber: 3,
              headingEn: 'S3',
              lastViewedAt: DateTime.now(),
            ),
          ),
          controller.recordVisit(
            HistoryItem(
              sectionNumber: 4,
              headingEn: 'S4',
              lastViewedAt: DateTime.now(),
            ),
          ),
          controller.recordVisit(
            HistoryItem(
              sectionNumber: 5,
              headingEn: 'S5',
              lastViewedAt: DateTime.now(),
            ),
          ),
        ]);

        expect(controller.count, 5);
        final raw = await storageService.getString(StorageKeys.recentHistory);
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as List;
        expect(decoded.length, 5);
      },
    );

    test('clearHistory clears all items and persists', () async {
      await controller.initialize();
      await controller.recordVisit(
        HistoryItem(
          sectionNumber: 42,
          headingEn: 'S42',
          lastViewedAt: DateTime.now(),
        ),
      );
      expect(controller.count, 1);

      await controller.clearHistory();
      expect(controller.count, 0);
      expect(controller.history, isEmpty);

      final raw = await storageService.getString(StorageKeys.recentHistory);
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List;
      expect(decoded, isEmpty);
    });
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
