import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/network/api_exceptions.dart';
import 'package:lexindia_frontend/features/sections/models/bns_section.dart';

void main() {
  group('BnsSectionSummary', () {
    test('parses successfully from standard backend JSON', () {
      final json = {
        'section_number': 1,
        'heading_en': 'Short title',
        'text_en': '1. Short title and commencement.',
        'heading_te': 'సంక్షిప్త శీర్షిక',
        'text_te': '1. సంక్షిప్త శీర్షిక మరియు ప్రారంభం.',
        'translation_status': 'translated',
      };

      final section = BnsSectionSummary.fromJson(json);

      expect(section.sectionNumber, 1);
      expect(section.headingEn, 'Short title');
      expect(section.textEn, '1. Short title and commencement.');
      expect(section.headingTe, 'సంక్షిప్త శీర్షిక');
      expect(section.textTe, '1. సంక్షిప్త శీర్షిక మరియు ప్రారంభం.');
      expect(section.translationStatus, 'translated');
      expect(section.source, isNull);
      expect(section.hasValidTelugu, isTrue);
      expect(section.getHeading('te'), 'సంక్షిప్త శీర్షిక');
      expect(section.getHeading('en'), 'Short title');
    });

    test('handles untranslated section appropriately', () {
      final json = {
        'section_number': 250,
        'heading_en': 'Taking gift',
        'text_en': 'Whoever accepts...',
        'heading_te': '',
        'text_te': '',
        'translation_status': 'not_translated',
      };

      final section = BnsSectionSummary.fromJson(json);

      expect(section.sectionNumber, 250);
      expect(section.hasValidTelugu, isFalse);
      // Falls back to English heading when Telugu is empty
      expect(section.getHeading('te'), 'Taking gift');
    });

    test(
      'throws MalformedResponseException when section_number is missing',
      () {
        final json = {'heading_en': 'Missing number'};

        expect(
          () => BnsSectionSummary.fromJson(json),
          throwsA(isA<MalformedResponseException>()),
        );
      },
    );

    test('serializes to JSON correctly', () {
      const section = BnsSectionSummary(
        sectionNumber: 42,
        headingEn: 'Right of defence',
        textEn: 'When harm other than death...',
        headingTe: 'ఆత్మ రక్షణ',
        textTe: 'మరణం తప్ప...',
        translationStatus: 'translated',
        source: 'India Code',
      );

      final json = section.toJson();
      expect(json['section_number'], 42);
      expect(json['source'], 'India Code');
    });
  });

  group('BnsSectionDetail', () {
    test('parses full record with source and updated_at', () {
      final json = {
        'section_number': 1,
        'heading_en': 'Short title',
        'text_en': 'Full legal text',
        'heading_te': 'సంక్షిప్త శీర్షిక',
        'text_te': 'పూర్తి చట్ట వచనం',
        'translation_status': 'translated',
        'source': 'India Code - Bharatiya Nyaya Sanhita, 2023',
        'updated_at': '2026-10-21 13:04:26',
      };

      final detail = BnsSectionDetail.fromJson(json);

      expect(detail.sectionNumber, 1);
      expect(detail.source, 'India Code - Bharatiya Nyaya Sanhita, 2023');
      expect(detail.updatedAt, '2026-10-21 13:04:26');
      expect(detail.toJson()['updated_at'], '2026-10-21 13:04:26');
    });
  });

  group('BnsLanguageSection', () {
    test('parses English response', () {
      final json = {
        'section_number': 1,
        'language': 'en',
        'heading': 'Short title',
        'text': 'English legal provision text.',
      };

      final langSection = BnsLanguageSection.fromJson(json);

      expect(langSection.sectionNumber, 1);
      expect(langSection.language, 'en');
      expect(langSection.heading, 'Short title');
      expect(langSection.text, 'English legal provision text.');
      expect(langSection.translationStatus, isNull);
      expect(langSection.hasContent, isTrue);
      expect(langSection.isAvailableTelugu, isFalse);
    });

    test('parses translated Telugu response', () {
      final json = {
        'section_number': 1,
        'language': 'te',
        'heading': 'సంక్షిప్త శీర్షిక',
        'text': 'తెలుగు చట్ట వచనం.',
        'translation_status': 'translated',
      };

      final langSection = BnsLanguageSection.fromJson(json);

      expect(langSection.sectionNumber, 1);
      expect(langSection.language, 'te');
      expect(langSection.translationStatus, 'translated');
      expect(langSection.isAvailableTelugu, isTrue);
      expect(langSection.isMissingTelugu, isFalse);
    });

    test(
      'correctly identifies untranslated Telugu response (HTTP 200 with empty text)',
      () {
        final json = {
          'section_number': 250,
          'language': 'te',
          'heading': '',
          'text': '',
          'translation_status': 'not_translated',
        };

        final langSection = BnsLanguageSection.fromJson(json);

        expect(langSection.sectionNumber, 250);
        expect(langSection.language, 'te');
        expect(langSection.translationStatus, 'not_translated');
        expect(langSection.hasContent, isFalse);
        expect(langSection.isAvailableTelugu, isFalse);
        expect(langSection.isMissingTelugu, isTrue);
      },
    );

    test('throws MalformedResponseException on missing required keys', () {
      final json = {'heading': 'Missing section_number'};

      expect(
        () => BnsLanguageSection.fromJson(json),
        throwsA(isA<MalformedResponseException>()),
      );
    });
  });

  group('PaginatedSectionsResponse', () {
    test('parses valid paginated JSON', () {
      final json = {
        'total': 358,
        'page': 1,
        'page_size': 20,
        'total_pages': 18,
        'sections': [
          {
            'section_number': 1,
            'heading_en': 'Section 1',
            'text_en': 'Text 1',
            'heading_te': 'విభాగం 1',
            'text_te': 'వచనం 1',
            'translation_status': 'translated',
          },
        ],
      };

      final response = PaginatedSectionsResponse.fromJson(json);

      expect(response.total, 358);
      expect(response.page, 1);
      expect(response.pageSize, 20);
      expect(response.totalPages, 18);
      expect(response.sections.length, 1);
      expect(response.sections.first.sectionNumber, 1);
      expect(response.hasNextPage, isTrue);
      expect(response.hasPreviousPage, isFalse);
      expect(response.isEmpty, isFalse);
    });

    test('handles empty results (e.g. search with 0 matches)', () {
      final json = {
        'total': 0,
        'page': 1,
        'page_size': 20,
        'total_pages': 0,
        'sections': [],
      };

      final response = PaginatedSectionsResponse.fromJson(json);

      expect(response.total, 0);
      expect(response.totalPages, 0);
      expect(response.sections, isEmpty);
      expect(response.isEmpty, isTrue);
      expect(response.hasNextPage, isFalse);
    });

    test('throws MalformedResponseException if missing pagination keys', () {
      final json = {'total': 10, 'sections': []};

      expect(
        () => PaginatedSectionsResponse.fromJson(json),
        throwsA(isA<MalformedResponseException>()),
      );
    });
  });

  group('TranslationProgress', () {
    test('parses progress JSON and calculates percentages correctly', () {
      final json = {
        'total_sections': 358,
        'translated_sections': 206,
        'remaining_sections': 152,
      };

      final progress = TranslationProgress.fromJson(json);

      expect(progress.totalSections, 358);
      expect(progress.translatedSections, 206);
      expect(progress.remainingSections, 152);
      expect(progress.percentageTranslated, closeTo(57.54, 0.05));
    });

    test('throws MalformedResponseException if keys are missing', () {
      final json = {'total_sections': 358};

      expect(
        () => TranslationProgress.fromJson(json),
        throwsA(isA<MalformedResponseException>()),
      );
    });
  });
}
