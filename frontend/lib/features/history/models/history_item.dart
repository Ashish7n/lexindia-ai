import '../../sections/models/bns_section.dart';

/// Lightweight representation of a recently viewed Bharatiya Nyaya Sanhita (BNS) section.
///
/// Encapsulates the metadata necessary to display recent history on the Home screen
/// and revisit sections without contacting the backend.
/// Complete statutory provision text is intentionally omitted to conserve local storage.
class HistoryItem {
  /// Unique section number representing the stable identifier.
  final int sectionNumber;

  /// Statutory heading in English.
  final String headingEn;

  /// Statutory heading in Telugu, if available.
  final String? headingTe;

  /// Timestamp recording when this section was last viewed.
  final DateTime lastViewedAt;

  const HistoryItem({
    required this.sectionNumber,
    required this.headingEn,
    this.headingTe,
    required this.lastViewedAt,
  });

  /// Factory constructor to create a history item directly from a loaded [BnsSectionDetail].
  factory HistoryItem.fromDetail(
    BnsSectionDetail detail, {
    DateTime? lastViewedAt,
  }) {
    final te = detail.headingTe.trim();
    return HistoryItem(
      sectionNumber: detail.sectionNumber,
      headingEn: detail.headingEn.trim(),
      headingTe: te.isNotEmpty ? te : null,
      lastViewedAt: lastViewedAt ?? DateTime.now(),
    );
  }

  /// Factory constructor to create a history item from a [BnsSectionSummary].
  factory HistoryItem.fromSummary(
    BnsSectionSummary summary, {
    DateTime? lastViewedAt,
  }) {
    final te = summary.headingTe.trim();
    return HistoryItem(
      sectionNumber: summary.sectionNumber,
      headingEn: summary.headingEn.trim(),
      headingTe: te.isNotEmpty ? te : null,
      lastViewedAt: lastViewedAt ?? DateTime.now(),
    );
  }

  /// Deserializes a [HistoryItem] from a JSON map.
  ///
  /// Throws [FormatException] if required fields are missing, empty, or malformed.
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final rawNumber = json['section_number'];
    if (rawNumber == null) {
      throw const FormatException('Missing required field: section_number');
    }
    final int number;
    if (rawNumber is int) {
      number = rawNumber;
    } else {
      number =
          int.tryParse(rawNumber.toString()) ??
          (throw FormatException('Invalid section_number: $rawNumber'));
    }

    final rawHeadingEn = json['heading_en'];
    if (rawHeadingEn == null ||
        rawHeadingEn is! String ||
        rawHeadingEn.trim().isEmpty) {
      throw const FormatException(
        'Missing or empty required field: heading_en',
      );
    }

    final rawHeadingTe = json['heading_te'];
    String? headingTe;
    if (rawHeadingTe is String && rawHeadingTe.trim().isNotEmpty) {
      headingTe = rawHeadingTe.trim();
    }

    final rawLastViewedAt = json['last_viewed_at'];
    if (rawLastViewedAt == null) {
      throw const FormatException('Missing required field: last_viewed_at');
    }
    final DateTime lastViewedAt;
    if (rawLastViewedAt is String) {
      final parsed = DateTime.tryParse(rawLastViewedAt);
      if (parsed == null) {
        throw FormatException(
          'Invalid date format for last_viewed_at: $rawLastViewedAt',
        );
      }
      lastViewedAt = parsed;
    } else {
      throw FormatException(
        'Invalid type for last_viewed_at: $rawLastViewedAt',
      );
    }

    return HistoryItem(
      sectionNumber: number,
      headingEn: rawHeadingEn.trim(),
      headingTe: headingTe,
      lastViewedAt: lastViewedAt,
    );
  }

  /// Serializes the history item metadata to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'section_number': sectionNumber,
      'heading_en': headingEn,
      if (headingTe != null && headingTe!.trim().isNotEmpty)
        'heading_te': headingTe!.trim(),
      'last_viewed_at': lastViewedAt.toIso8601String(),
    };
  }

  /// Returns the heading in the requested language ('te' or 'en').
  /// Falls back to English if Telugu content is unavailable.
  String getHeading(String language) {
    if (language.toLowerCase() == 'te' &&
        headingTe != null &&
        headingTe!.trim().isNotEmpty) {
      return headingTe!;
    }
    return headingEn;
  }

  /// True if a non-empty Telugu heading is available.
  bool get hasTelugu => headingTe != null && headingTe!.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryItem &&
          runtimeType == other.runtimeType &&
          sectionNumber == other.sectionNumber &&
          headingEn == other.headingEn &&
          headingTe == other.headingTe &&
          lastViewedAt.isAtSameMomentAs(other.lastViewedAt);

  @override
  int get hashCode =>
      sectionNumber.hashCode ^
      headingEn.hashCode ^
      headingTe.hashCode ^
      lastViewedAt.millisecondsSinceEpoch.hashCode;

  @override
  String toString() =>
      'HistoryItem(§$sectionNumber, headingEn: "$headingEn", headingTe: "$headingTe", lastViewedAt: $lastViewedAt)';
}
