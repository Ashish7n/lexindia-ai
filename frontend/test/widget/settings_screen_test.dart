import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/language/language_controller.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/theme/app_theme.dart';
import 'package:lexindia_frontend/core/theme/theme_controller.dart';
import 'package:lexindia_frontend/features/settings/screens/about_screen.dart';
import 'package:lexindia_frontend/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    late LocalStorageService storageService;
    late ThemeController themeController;
    late LanguageController languageController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      themeController = ThemeController(storageService: storageService);
      languageController = LanguageController(storageService: storageService);
    });

    testWidgets('renders Appearance, Reading Preference, and Legal sections', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await themeController.initialize();
        await languageController.initialize();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            themeController: themeController,
            languageController: languageController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      expect(find.text('READING PREFERENCE'), findsOneWidget);
      expect(find.text('English (Default)'), findsOneWidget);
      expect(find.text('తెలుగు (Telugu)'), findsOneWidget);

      expect(find.text('LEGAL & PROVENANCE'), findsOneWidget);
      expect(find.text('About LexIndia-AI'), findsOneWidget);
      expect(find.text('Legal Information Disclaimer'), findsOneWidget);
      expect(find.text('Source Material'), findsOneWidget);
      expect(find.text('Application Version'), findsOneWidget);
    });

    testWidgets('tapping theme mode options updates ThemeController', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await themeController.initialize();
        await languageController.initialize();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            themeController: themeController,
            languageController: languageController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(themeController.themeMode, ThemeMode.system);

      // Tap Dark Mode
      await tester.tap(find.byKey(const Key('theme_radio_dark')));
      await tester.pumpAndSettle();
      expect(themeController.themeMode, ThemeMode.dark);
      expect(themeController.isDarkMode, isTrue);

      // Tap Light Mode
      await tester.tap(find.byKey(const Key('theme_radio_light')));
      await tester.pumpAndSettle();
      expect(themeController.themeMode, ThemeMode.light);
      expect(themeController.isLightMode, isTrue);

      // Tap System Default
      await tester.tap(find.byKey(const Key('theme_radio_system')));
      await tester.pumpAndSettle();
      expect(themeController.themeMode, ThemeMode.system);
    });

    testWidgets('tapping reading language options updates LanguageController', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await themeController.initialize();
        await languageController.initialize();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            themeController: themeController,
            languageController: languageController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(languageController.defaultLanguage, 'en');

      // Tap Telugu option
      await tester.tap(find.byKey(const Key('language_radio_te')));
      await tester.pumpAndSettle();
      expect(languageController.defaultLanguage, 'te');
      expect(languageController.isTelugu, isTrue);

      // Tap English option
      await tester.tap(find.byKey(const Key('language_radio_en')));
      await tester.pumpAndSettle();
      expect(languageController.defaultLanguage, 'en');
      expect(languageController.isEnglish, isTrue);
    });

    testWidgets('tapping About LexIndia-AI navigates to AboutScreen', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await themeController.initialize();
        await languageController.initialize();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            themeController: themeController,
            languageController: languageController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('settings_about_tile')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_about_tile')));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('About LexIndia-AI'), findsOneWidget);
    });

    testWidgets(
      'tapping Legal Disclaimer tile shows dialog with Understood button',
      (tester) async {
        await tester.runAsync(() async {
          await themeController.initialize();
          await languageController.initialize();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              themeController: themeController,
              languageController: languageController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('settings_disclaimer_tile')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_disclaimer_tile')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Understood'), findsOneWidget);

        await tester.tap(find.text('Understood'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('narrow viewport (320px) does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await themeController.initialize();
        await languageController.initialize();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SettingsScreen(
            themeController: themeController,
            languageController: languageController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
