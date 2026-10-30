import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/features/history/models/history_item.dart';
import 'package:lexindia_frontend/features/sections/models/bns_section.dart';

void main() {
  group('HistoryItem Unit Tests', () {
    final fixedTimestamp = DateTime.parse('2026-10-22T08:00:00.000Z');

    test('valid serialization and deserialization round-trip with Telugu', () {
      final original = HistoryItem(
        sectionNumber: 42,
        headingEn:
            'Acts done by several persons in furtherance of common intention',
        headingTe: 'ఉమ్మడి ఉద్దేశంతో అనేక వ్యక్తులు చేసిన చర్యలు',
        lastViewedAt: fixedTimestamp,
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
      expect(json['last_viewed_at'], '2026-10-22T08:00:00.000Z');
      // Verify no statutory body text is stored in history metadata
      expect(json.containsKey('text_en'), isFalse);
      expect(json.containsKey('text_te'), isFalse);

      final deserialized = HistoryItem.fromJson(json);
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
      final original = HistoryItem(
        sectionNumber: 101,
        headingEn: 'Murder',
        headingTe: null,
        lastViewedAt: fixedTimestamp,
      );

      final json = original.toJson();
      expect(json['section_number'], 101);
      expect(json['heading_en'], 'Murder');
      expect(json.containsKey('heading_te'), isFalse);
      expect(json['last_viewed_at'], '2026-10-22T08:00:00.000Z');

      final deserialized = HistoryItem.fromJson(json);
      expect(deserialized, equals(original));
      expect(deserialized.hasTelugu, isFalse);
      expect(deserialized.getHeading('te'), 'Murder'); // Falls back to English
      expect(deserialized.getHeading('en'), 'Murder');
    });

    test('handles empty and whitespace Telugu headings gracefully as null', () {
      final jsonWithEmptyTe = {
        'section_number': 5,
        'heading_en': 'Title',
        'heading_te': '   ',
        'last_viewed_at': fixedTimestamp.toIso8601String(),
      };

      final item = HistoryItem.fromJson(jsonWithEmptyTe);
      expect(item.headingTe, isNull);
      expect(item.hasTelugu, isFalse);
    });

    test('creates history item from BnsSectionDetail factory', () {
      const detail = BnsSectionDetail(
        sectionNumber: 12,
        headingEn: 'Public servant',
        textEn: 'The words public servant denote...',
        headingTe: 'ప్రజా సేవకుడు',
        textTe: 'ప్రజా సేవకుడు అనగా...',
        translationStatus: 'translated',
        source: 'India Code',
      );

      final item = HistoryItem.fromDetail(detail, lastViewedAt: fixedTimestamp);
      expect(item.sectionNumber, 12);
      expect(item.headingEn, 'Public servant');
      expect(item.headingTe, 'ప్రజా సేవకుడు');
      expect(item.lastViewedAt, fixedTimestamp);
    });

    test('creates history item from BnsSectionSummary factory', () {
      const summary = BnsSectionSummary(
        sectionNumber: 30,
        headingEn: 'Judge',
        textEn: 'The word judge denotes...',
        headingTe: '',
        textTe: '',
        translationStatus: 'not_translated',
      );

      final item = HistoryItem.fromSummary(
        summary,
        lastViewedAt: fixedTimestamp,
      );
      expect(item.sectionNumber, 30);
      expect(item.headingEn, 'Judge');
      expect(item.headingTe, isNull);
      expect(item.lastViewedAt, fixedTimestamp);
    });

    group('Malformed JSON defense tests', () {
      test('throws FormatException when section_number is missing', () {
        final badJson = {
          'heading_en': 'Valid',
          'last_viewed_at': fixedTimestamp.toIso8601String(),
        };
        expect(() => HistoryItem.fromJson(badJson), throwsFormatException);
      });

      test('throws FormatException when section_number is non-numeric', () {
        final badJson = {
          'section_number': 'not-a-number',
          'heading_en': 'Valid',
          'last_viewed_at': fixedTimestamp.toIso8601String(),
        };
        expect(() => HistoryItem.fromJson(badJson), throwsFormatException);
      });

      test('throws FormatException when heading_en is missing', () {
        final badJson = {
          'section_number': 42,
          'last_viewed_at': fixedTimestamp.toIso8601String(),
        };
        expect(() => HistoryItem.fromJson(badJson), throwsFormatException);
      });

      test('throws FormatException when heading_en is empty string', () {
        final badJson = {
          'section_number': 42,
          'heading_en': '   ',
          'last_viewed_at': fixedTimestamp.toIso8601String(),
        };
        expect(() => HistoryItem.fromJson(badJson), throwsFormatException);
      });

      test('throws FormatException when last_viewed_at is missing', () {
        final badJson = {'section_number': 42, 'heading_en': 'Valid'};
        expect(() => HistoryItem.fromJson(badJson), throwsFormatException);
      });

      test(
        'throws FormatException when last_viewed_at is invalid date string',
        () {
          final badJson = {
            'section_number': 42,
            'heading_en': 'Valid',
            'last_viewed_at': 'not-a-date',
          };
          expect(() => HistoryItem.fromJson(badJson), throwsFormatException);
        },
      );
    });
  });
}
