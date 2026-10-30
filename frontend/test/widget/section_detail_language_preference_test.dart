import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexindia_frontend/core/config/app_config.dart';
import 'package:lexindia_frontend/core/language/language_controller.dart';
import 'package:lexindia_frontend/core/network/api_client.dart';
import 'package:lexindia_frontend/core/storage/local_storage_service.dart';
import 'package:lexindia_frontend/core/storage/storage_keys.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SectionDetailScreen Language Preference Integration Widget Tests', () {
    const testConfig = AppConfig(baseUrl: 'http://testserver:8000');

    late LocalStorageService storageService;
    late LanguageController languageController;

    http.Response utf8Response(String body, int statusCode) {
      return http.Response.bytes(
        utf8.encode(body),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      languageController = LanguageController(storageService: storageService);
    });

    testWidgets(
      'opens in English when LanguageController defaultLanguage is English',
      (tester) async {
        await tester.runAsync(() async {
          await languageController.initialize();
        });

        final mockClient = MockClient((request) async {
          if (request.url.path == '/sections/42') {
            return utf8Response('''
            {
              "section_number": 42,
              "chapter_number": 2,
              "heading_en": "Acts done by several persons",
              "text_en": "When a criminal act is done by several persons in furtherance of common intention...",
              "heading_te": "ఉమ్మడి ఉద్దేశం",
              "text_te": "తెలుగు వచనం...",
              "translation_status": "translated",
              "source": "India Code BNS Gazette",
              "updated_at": "2026-10-22 08:00:00"
            }
            ''', 200);
          } else if (request.url.path == '/sections/42/language/en') {
            return utf8Response('''
            {
              "section_number": 42,
              "language": "en",
              "heading": "Acts done by several persons",
              "text": "When a criminal act is done by several persons in furtherance of common intention..."
            }
            ''', 200);
          }
          return http.Response('Not Found', 404);
        });

        final repository = SectionRepository(
          apiClient: ApiClient(client: mockClient, config: testConfig),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              languageController: languageController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<SectionDetailScreenState>(
          find.byType(SectionDetailScreen),
        );
        expect(state.currentLanguageForTesting, 'en');
        expect(find.text('BNS § 42'), findsOneWidget);
        expect(find.text('Acts done by several persons'), findsWidgets);
      },
    );

    testWidgets(
      'opens in Telugu when LanguageController defaultLanguage is Telugu',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.defaultLanguage: 'te',
        });
        await tester.runAsync(() async {
          await languageController.initialize();
        });
        expect(languageController.defaultLanguage, 'te');

        final mockClient = MockClient((request) async {
          if (request.url.path == '/sections/42') {
            return utf8Response('''
            {
              "section_number": 42,
              "chapter_number": 2,
              "heading_en": "Acts done by several persons",
              "text_en": "When a criminal act is done by several persons in furtherance of common intention...",
              "heading_te": "ఉమ్మడి ఉద్దేశంతో పలువురు వ్యక్తులు చేసిన చర్యలు",
              "text_te": "ఉమ్మడి ఉద్దేశాన్ని నెరవేర్చడంలో పలువురు వ్యక్తులు నేరపూరిత చర్య చేసినప్పుడు...",
              "translation_status": "draft",
              "source": "India Code BNS Gazette",
              "updated_at": "2026-10-22 08:00:00"
            }
            ''', 200);
          } else if (request.url.path == '/sections/42/language/te') {
            return utf8Response('''
            {
              "section_number": 42,
              "language": "te",
              "heading": "ఉమ్మడి ఉద్దేశంతో పలువురు వ్యక్తులు చేసిన చర్యలు",
              "text": "ఉమ్మడి ఉద్దేశాన్ని నెరవేర్చడంలో పలువురు వ్యక్తులు నేరపూరిత చర్య చేసినప్పుడు...",
              "translation_status": "draft"
            }
            ''', 200);
          }
          return http.Response('Not Found', 404);
        });

        final repository = SectionRepository(
          apiClient: ApiClient(client: mockClient, config: testConfig),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              languageController: languageController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<SectionDetailScreenState>(
          find.byType(SectionDetailScreen),
        );
        expect(state.currentLanguageForTesting, 'te');
        expect(
          find.text('ఉమ్మడి ఉద్దేశంతో పలువురు వ్యక్తులు చేసిన చర్యలు'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'explicitly switching language on screen does not change global defaultLanguage',
      (tester) async {
        await tester.runAsync(() async {
          await languageController.initialize();
        });
        expect(languageController.defaultLanguage, 'en');

        final mockClient = MockClient((request) async {
          if (request.url.path == '/sections/42') {
            return utf8Response('''
            {
              "section_number": 42,
              "chapter_number": 2,
              "heading_en": "Acts done by several persons",
              "text_en": "English text...",
              "heading_te": "ఉమ్మడి ఉద్దేశం",
              "text_te": "తెలుగు పాఠ్యం...",
              "translation_status": "translated",
              "source": "India Code BNS Gazette",
              "updated_at": "2026-10-22 08:00:00"
            }
            ''', 200);
          } else if (request.url.path == '/sections/42/language/en') {
            return utf8Response('''
            {
              "section_number": 42,
              "language": "en",
              "heading": "Acts done by several persons",
              "text": "English text..."
            }
            ''', 200);
          } else if (request.url.path == '/sections/42/language/te') {
            return utf8Response('''
            {
              "section_number": 42,
              "language": "te",
              "heading": "ఉమ్మడి ఉద్దేశంతో పలువురు వ్యక్తులు చేసిన చర్యలు",
              "text": "తెలుగు పాఠ్యం...",
              "translation_status": "translated"
            }
            ''', 200);
          }
          return http.Response('Not Found', 404);
        });

        final repository = SectionRepository(
          apiClient: ApiClient(client: mockClient, config: testConfig),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 42,
              repository: repository,
              languageController: languageController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Telugu on this screen using 'తెలుగు (Telugu)' button
        await tester.tap(find.text('తెలుగు (Telugu)'));
        await tester.pumpAndSettle();

        final state = tester.state<SectionDetailScreenState>(
          find.byType(SectionDetailScreen),
        );
        expect(state.currentLanguageForTesting, 'te');

        // Global default reading language remains English
        expect(languageController.defaultLanguage, 'en');
        expect(
          await storageService.getString(StorageKeys.defaultLanguage),
          isNull,
        );
      },
    );
  });
}
