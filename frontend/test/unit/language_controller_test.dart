import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/language/language_controller.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LanguageController Persistence and State Unit Tests', () {
    late LocalStorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
    });

    test('default reading language is English when storage is empty', () async {
      final controller = LanguageController(storageService: storageService);
      expect(controller.defaultLanguage, LanguageController.english);
      expect(controller.isEnglish, isTrue);
      expect(controller.isTelugu, isFalse);

      await controller.initialize();

      expect(controller.defaultLanguage, LanguageController.english);
      expect(controller.isEnglish, isTrue);
      expect(controller.isInitialized, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('restores saved English language from storage', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.defaultLanguage: 'en',
      });
      final controller = LanguageController(storageService: storageService);

      await controller.initialize();

      expect(controller.defaultLanguage, 'en');
      expect(controller.isEnglish, isTrue);
      expect(controller.isTelugu, isFalse);
    });

    test('restores saved Telugu language from storage', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.defaultLanguage: 'te',
      });
      final controller = LanguageController(storageService: storageService);

      await controller.initialize();

      expect(controller.defaultLanguage, 'te');
      expect(controller.isTelugu, isTrue);
      expect(controller.isEnglish, isFalse);
    });

    test(
      'unsupported or invalid stored language safely defaults to English',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.defaultLanguage:
              'hi', // Hindi is not in MVP BNS translations
        });
        final controller = LanguageController(storageService: storageService);

        await controller.initialize();

        expect(controller.defaultLanguage, 'en');
        expect(controller.isEnglish, isTrue);
        expect(controller.errorMessage, isNull);
      },
    );

    test(
      'setDefaultLanguage updates state, notifies, and persists to storage',
      () async {
        final controller = LanguageController(storageService: storageService);
        await controller.initialize();

        bool notified = false;
        controller.addListener(() => notified = true);

        await controller.setDefaultLanguage(LanguageController.telugu);

        expect(notified, isTrue);
        expect(controller.defaultLanguage, 'te');
        expect(controller.isTelugu, isTrue);

        final stored = await storageService.getString(
          StorageKeys.defaultLanguage,
        );
        expect(stored, 'te');
      },
    );

    test(
      'setting the same language does not perform redundant writes',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.defaultLanguage: 'te',
        });
        final controller = LanguageController(storageService: storageService);
        await controller.initialize();

        bool notified = false;
        controller.addListener(() => notified = true);

        await controller.setDefaultLanguage('te');

        expect(notified, isFalse);
      },
    );

    test(
      'unsupported language code is safely ignored without state change',
      () async {
        final controller = LanguageController(storageService: storageService);
        await controller.initialize();

        bool notified = false;
        controller.addListener(() => notified = true);

        await controller.setDefaultLanguage('fr');

        expect(notified, isFalse);
        expect(controller.defaultLanguage, 'en');
      },
    );

    test(
      'explicit user selection before initialize() completes is preserved',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.defaultLanguage: 'en',
        });
        final controller = LanguageController(storageService: storageService);

        // User actively sets Telugu before initialize resolves
        await controller.setDefaultLanguage('te');

        await controller.initialize();

        expect(controller.defaultLanguage, 'te');
        expect(controller.isTelugu, isTrue);
      },
    );

    test(
      'storage write failure is handled gracefully without crashing',
      () async {
        final failingStorage = FailingLangStorageService();
        final controller = LanguageController(storageService: failingStorage);
        await controller.initialize();

        bool notified = false;
        controller.addListener(() => notified = true);

        await controller.setDefaultLanguage('te');

        expect(notified, isTrue);
        expect(controller.defaultLanguage, 'te');
        expect(controller.errorMessage, isNotNull);
      },
    );
  });
}

class FailingLangStorageService extends LocalStorageService {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<bool> setString(String key, String value) async {
    throw const StorageException('Disk error simulation');
  }
}
