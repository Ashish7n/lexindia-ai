import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/storage/storage_keys.dart';
import 'package:lexindia_frontend/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeController Persistence and State Unit Tests', () {
    late LocalStorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
    });

    test('default theme mode is System when storage is empty', () async {
      final controller = ThemeController(storageService: storageService);
      expect(controller.themeMode, ThemeMode.system);
      expect(controller.isSystemMode, isTrue);
      expect(controller.isLightMode, isFalse);
      expect(controller.isDarkMode, isFalse);

      await controller.initialize();

      expect(controller.themeMode, ThemeMode.system);
      expect(controller.isSystemMode, isTrue);
      expect(controller.isInitialized, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('restores saved Light mode from storage', () async {
      SharedPreferences.setMockInitialValues({StorageKeys.themeMode: 'light'});
      final controller = ThemeController(storageService: storageService);

      await controller.initialize();

      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isLightMode, isTrue);
      expect(controller.isDarkMode, isFalse);
      expect(controller.isSystemMode, isFalse);
    });

    test('restores saved Dark mode from storage', () async {
      SharedPreferences.setMockInitialValues({StorageKeys.themeMode: 'dark'});
      final controller = ThemeController(storageService: storageService);

      await controller.initialize();

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
      expect(controller.isLightMode, isFalse);
      expect(controller.isSystemMode, isFalse);
    });

    test('restores saved System mode from storage', () async {
      SharedPreferences.setMockInitialValues({StorageKeys.themeMode: 'system'});
      final controller = ThemeController(storageService: storageService);

      await controller.initialize();

      expect(controller.themeMode, ThemeMode.system);
      expect(controller.isSystemMode, isTrue);
    });

    test(
      'malformed or invalid stored value safely defaults to System',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.themeMode: 'invalid_mode_xyz',
        });
        final controller = ThemeController(storageService: storageService);

        await controller.initialize();

        expect(controller.themeMode, ThemeMode.system);
        expect(controller.isSystemMode, isTrue);
        expect(controller.errorMessage, isNull);
      },
    );

    test(
      'setThemeMode updates in-memory state and notifies immediately',
      () async {
        final controller = ThemeController(storageService: storageService);
        await controller.initialize();

        bool notified = false;
        controller.addListener(() => notified = true);

        await controller.setThemeMode(ThemeMode.dark);

        expect(notified, isTrue);
        expect(controller.themeMode, ThemeMode.dark);
        expect(controller.isDarkMode, isTrue);

        final stored = await storageService.getString(StorageKeys.themeMode);
        expect(stored, 'dark');
      },
    );

    test(
      'setting the same theme mode does not perform redundant write',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.themeMode: 'light',
        });
        final controller = ThemeController(storageService: storageService);
        await controller.initialize();

        bool notified = false;
        controller.addListener(() => notified = true);

        await controller.setThemeMode(ThemeMode.light);

        expect(notified, isFalse);
      },
    );

    test(
      'explicit user selection before initialize() completes is preserved',
      () async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.themeMode: 'light',
        });
        final controller = ThemeController(storageService: storageService);

        // User actively sets Dark before initialize resolves
        await controller.setThemeMode(ThemeMode.dark);

        await controller.initialize();

        expect(controller.themeMode, ThemeMode.dark);
        expect(controller.isDarkMode, isTrue);
      },
    );

    test(
      'storage write failure is handled gracefully without crashing',
      () async {
        final failingStorage = FailingStorageService();
        final controller = ThemeController(storageService: failingStorage);
        await controller.initialize();

        bool notified = false;
        controller.addListener(() => notified = true);

        await controller.setThemeMode(ThemeMode.dark);

        // In-memory state updated and listeners notified despite write failure
        expect(notified, isTrue);
        expect(controller.themeMode, ThemeMode.dark);
        expect(controller.errorMessage, isNotNull);
      },
    );
  });
}

class FailingStorageService extends LocalStorageService {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<bool> setString(String key, String value) async {
    throw const StorageException('Disk full simulation');
  }
}
