import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/app.dart';
import 'package:lexindia_frontend/core/theme/theme_controller.dart';
import 'package:lexindia_frontend/features/home/screens/home_screen.dart';
import 'package:lexindia_frontend/features/browse/screens/browse_screen.dart';
import 'package:lexindia_frontend/features/saved/screens/saved_screen.dart';
import 'package:lexindia_frontend/features/settings/screens/settings_screen.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';

void main() {
  group('Phase 2 Navigation & Theme Shell Tests', () {
    testWidgets('renders four navigation destinations and switches tabs', (
      tester,
    ) async {
      final themeController = ThemeController();
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"total": 0, "page": 1, "page_size": 20, "total_pages": 0, "sections": []}',
          200,
        );
      });
      final repo = SectionRepository(
        apiClient: ApiClient(
          client: mockClient,
          config: const AppConfig(baseUrl: 'http://testserver:8000'),
        ),
      );

      await tester.pumpWidget(
        LexIndiaApp(themeController: themeController, sectionRepository: repo),
      );
      await tester.pumpAndSettle();

      // 1. Initial screen should be Home
      expect(find.text('LexIndia-AI'), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('BHARATIYA NYAYA SANHITA, 2023'), findsOneWidget);

      // Verify all 4 navigation labels exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // 2. Navigate to Browse
      await tester.tap(find.text('Browse'));
      await tester.pumpAndSettle();
      expect(find.byType(BrowseScreen), findsOneWidget);
      expect(find.text('Browse BNS'), findsOneWidget);

      // 3. Navigate to Saved
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.byType(SavedScreen), findsOneWidget);
      expect(find.text('Saved Sections'), findsOneWidget);
      expect(find.text('No Bookmarks Yet'), findsOneWidget);

      // 4. Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      // 5. Navigate back to Home via shortcut in Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Tap Browse shortcut button in HomeScreen
      await tester.tap(find.text('Browse 358 BNS Sections'));
      await tester.pumpAndSettle();
      expect(find.byType(BrowseScreen), findsOneWidget);
    });

    testWidgets('ThemeController switches theme mode and rebuilds app', (
      tester,
    ) async {
      final themeController = ThemeController();

      final mockClient = MockClient((request) async {
        return http.Response(
          '{"total": 0, "page": 1, "page_size": 20, "total_pages": 0, "sections": []}',
          200,
        );
      });
      final repo = SectionRepository(
        apiClient: ApiClient(
          client: mockClient,
          config: const AppConfig(baseUrl: 'http://testserver:8000'),
        ),
      );

      await tester.pumpWidget(
        LexIndiaApp(themeController: themeController, sectionRepository: repo),
      );
      await tester.pumpAndSettle();

      expect(themeController.themeMode, ThemeMode.system);

      // Switch to Dark
      themeController.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(themeController.isDarkMode, isTrue);

      // Switch to Light
      themeController.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(themeController.isLightMode, isTrue);
    });
  });
}
