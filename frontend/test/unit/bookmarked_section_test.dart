import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/features/bookmarks/models/bookmarked_section.dart';
import 'package:lexindia_frontend/features/sections/models/bns_section.dart';

void main() {
  group('BookmarkedSection Unit Tests', () {
    final fixedTimestamp = DateTime.parse('2026-10-22T08:00:00.000Z');

    test('valid serialization and deserialization round-trip with Telugu', () {
      final original = BookmarkedSection(
        sectionNumber: 42,
        headingEn:
            'Acts done by several persons in furtherance of common intention',
        headingTe: 'ఉమ్మడి ఉద్దేశంతో అనేక వ్యక్తులు చేసిన చర్యలు',
        bookmarkedAt: fixedTimestamp,
      );

      final json = original.toJson();
      expect(json['section_number'], 42);
      expect(
        json['heading_en'],
        'Acts done by several persons in furtherance of common intention',
      );
      expect(
        json['heading_te'],
        'ఉమ్మడి ఉద్దేశంతో అనేక వ్యక్తులు చేసిన చర్యలు',
      );
      expect(json['bookmarked_at'], '2026-10-22T08:00:00.000Z');
      // Verify no statutory body text is stored in bookmark metadata
      expect(json.containsKey('text_en'), isFalse);
      expect(json.containsKey('text_te'), isFalse);

      final deserialized = BookmarkedSection.fromJson(json);
      expect(deserialized, equals(original));
      expect(deserialized.hasTelugu, isTrue);
      expect(
        deserialized.getHeading('te'),
        'ఉమ్మడి ఉద్దేశంతో అనేక వ్యక్తులు చేసిన చర్యలు',
      );
      expect(
        deserialized.getHeading('en'),
        'Acts done by several persons in furtherance of common intention',
      );
    });

    test('valid round-trip with absent Telugu heading', () {
      final original = BookmarkedSection(
        sectionNumber: 101,
        headingEn: 'Murder',
        headingTe: null,
        bookmarkedAt: fixedTimestamp,
      );

      final json = original.toJson();
      expect(json['section_number'], 101);
      expect(json['heading_en'], 'Murder');
      expect(json.containsKey('heading_te'), isFalse);
      expect(json['bookmarked_at'], '2026-10-22T08:00:00.000Z');

      final deserialized = BookmarkedSection.fromJson(json);
      expect(deserialized, equals(original));
      expect(deserialized.hasTelugu, isFalse);
      expect(deserialized.headingTe, isNull);
      // Fallback to English when Telugu is requested but absent
      expect(deserialized.getHeading('te'), 'Murder');
      expect(deserialized.getHeading('en'), 'Murder');
    });

    test('handles empty and whitespace Telugu headings gracefully as null', () {
      final jsonEmpty = {
        'section_number': 15,
        'heading_en': 'Some English Heading',
        'heading_te': '   ',
        'bookmarked_at': fixedTimestamp.toIso8601String(),
      };

      final deserialized = BookmarkedSection.fromJson(jsonEmpty);
      expect(deserialized.headingTe, isNull);
      expect(deserialized.hasTelugu, isFalse);
      expect(deserialized.getHeading('te'), 'Some English Heading');
    });

    test('creates bookmark from BnsSectionDetail factory', () {
      const detail = BnsSectionDetail(
        sectionNumber: 42,
        headingEn: ' Heading En with spaces ',
        textEn: 'Very long legal text that should not be in bookmark...',
        headingTe: ' Heading Te with spaces ',
        textTe: 'తెలుగు వచనం...',
        translationStatus: 'translated',
        source: 'India Code',
      );

      final bookmark = BookmarkedSection.fromDetail(
        detail,
        bookmarkedAt: fixedTimestamp,
      );
      expect(bookmark.sectionNumber, 42);
      expect(bookmark.headingEn, 'Heading En with spaces');
      expect(bookmark.headingTe, 'Heading Te with spaces');
      expect(bookmark.bookmarkedAt, fixedTimestamp);

      // Verify no full legal text is held
      final json = bookmark.toJson();
      expect(json.containsKey('text_en'), isFalse);
      expect(json.containsKey('text_te'), isFalse);
    });

    test('creates bookmark from BnsSectionSummary factory', () {
      const summary = BnsSectionSummary(
        sectionNumber: 10,
        headingEn: 'Gender',
        textEn: 'Full legal text...',
        headingTe: '',
        textTe: '',
        translationStatus: 'not_translated',
      );

      final bookmark = BookmarkedSection.fromSummary(
        summary,
        bookmarkedAt: fixedTimestamp,
      );
      expect(bookmark.sectionNumber, 10);
      expect(bookmark.headingEn, 'Gender');
      expect(bookmark.headingTe, isNull);
      expect(bookmark.hasTelugu, isFalse);
    });

    group('Malformed JSON defense tests', () {
      test('throws FormatException when section_number is missing', () {
        final json = {
          'heading_en': 'Heading',
          'bookmarked_at': fixedTimestamp.toIso8601String(),
        };
        expect(() => BookmarkedSection.fromJson(json), throwsFormatException);
      });

      test('throws FormatException when section_number is non-numeric', () {
        final json = {
          'section_number': 'not_a_number',
          'heading_en': 'Heading',
          'bookmarked_at': fixedTimestamp.toIso8601String(),
        };
        expect(() => BookmarkedSection.fromJson(json), throwsFormatException);
      });

      test('throws FormatException when heading_en is missing', () {
        final json = {
          'section_number': 42,
          'bookmarked_at': fixedTimestamp.toIso8601String(),
        };
        expect(() => BookmarkedSection.fromJson(json), throwsFormatException);
      });

      test('throws FormatException when heading_en is empty string', () {
        final json = {
          'section_number': 42,
          'heading_en': '   ',
          'bookmarked_at': fixedTimestamp.toIso8601String(),
        };
        expect(() => BookmarkedSection.fromJson(json), throwsFormatException);
      });

      test('throws FormatException when bookmarked_at is missing', () {
        final json = {'section_number': 42, 'heading_en': 'Heading'};
        expect(() => BookmarkedSection.fromJson(json), throwsFormatException);
      });

      test(
        'throws FormatException when bookmarked_at is invalid date string',
        () {
          final json = {
            'section_number': 42,
            'heading_en': 'Heading',
            'bookmarked_at': 'invalid_date_format',
          };
          expect(() => BookmarkedSection.fromJson(json), throwsFormatException);
        },
      );
    });
  });
}
