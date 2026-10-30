import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalStorageService Unit Tests', () {
    late LocalStorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
    });

    test('reading a key that does not exist returns null', () async {
      final value = await storageService.getString('non_existent_key');
      expect(value, isNull);
    });

    test('writing and reading a string works', () async {
      final writeResult = await storageService.setString(
        'test_key',
        'test_value',
      );
      expect(writeResult, isTrue);

      final readValue = await storageService.getString('test_key');
      expect(readValue, 'test_value');
    });

    test('updating an existing key returns the latest value', () async {
      await storageService.setString('update_key', 'initial_value');
      expect(await storageService.getString('update_key'), 'initial_value');

      await storageService.setString('update_key', 'updated_value');
      expect(await storageService.getString('update_key'), 'updated_value');
    });

    test('removing a key removes only that key and preserves others', () async {
      await storageService.setString('key_a', 'value_a');
      await storageService.setString('key_b', 'value_b');

      final removeResult = await storageService.remove('key_a');
      expect(removeResult, isTrue);

      expect(await storageService.getString('key_a'), isNull);
      expect(await storageService.getString('key_b'), 'value_b');
    });

    test('removing a missing key is handled safely without throwing', () async {
      final result = await storageService.remove('never_existed_key');
      expect(result, isTrue);
    });

    test('containsKey correctly reports existence and absence', () async {
      expect(await storageService.containsKey('presence_key'), isFalse);

      await storageService.setString('presence_key', 'exists');
      expect(await storageService.containsKey('presence_key'), isTrue);

      await storageService.remove('presence_key');
      expect(await storageService.containsKey('presence_key'), isFalse);
    });

    test(
      'clearKeys removes only specified keys while preserving others',
      () async {
        await storageService.setString(
          StorageKeys.bookmarks,
          '[{"section": 1}]',
        );
        await storageService.setString(
          StorageKeys.recentHistory,
          '[{"section": 1}]',
        );
        await storageService.setString(StorageKeys.themeMode, 'dark');

        await storageService.clearKeys([
          StorageKeys.bookmarks,
          StorageKeys.recentHistory,
        ]);

        expect(await storageService.getString(StorageKeys.bookmarks), isNull);
        expect(
          await storageService.getString(StorageKeys.recentHistory),
          isNull,
        );
        expect(await storageService.getString(StorageKeys.themeMode), 'dark');
      },
    );

    test(
      'constructor accepts injected SharedPreferences instance for tests',
      () async {
        SharedPreferences.setMockInitialValues({
          'injected_key': 'injected_val',
        });
        final prefs = await SharedPreferences.getInstance();
        final injectedStorage = LocalStorageService(preferences: prefs);

        expect(await injectedStorage.getString('injected_key'), 'injected_val');
      },
    );
  });

  group('StorageKeys Constants Tests', () {
    test('storage keys are centralized, non-empty, and unique', () {
      final keys = [
        StorageKeys.bookmarks,
        StorageKeys.recentHistory,
        StorageKeys.themeMode,
        StorageKeys.defaultLanguage,
      ];

      // Verify no duplicates
      expect(keys.toSet().length, keys.length);

      // Verify all keys are registered in allKeys set
      for (final key in keys) {
        expect(StorageKeys.allKeys.contains(key), isTrue);
        expect(key.isNotEmpty, isTrue);
        expect(key.startsWith('lexindia_'), isTrue);
      }
    });
  });
}
