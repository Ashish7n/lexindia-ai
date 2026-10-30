import '../../sections/models/bns_section.dart';

/// Lightweight representation of a bookmarked Bharatiya Nyaya Sanhita (BNS) section.
///
/// Encapsulates the metadata necessary to display bookmarks locally in the Saved
/// screen and verify bookmark status in Section Details without contacting the backend.
/// Complete statutory provision text is intentionally omitted to conserve local storage.
class BookmarkedSection {
  /// Unique section number representing the stable identifier.
  final int sectionNumber;

  /// Statutory heading in English.
  final String headingEn;

  /// Statutory heading in Telugu, if available.
  final String? headingTe;

  /// Timestamp recording when this section was bookmarked.
  final DateTime bookmarkedAt;

  const BookmarkedSection({
    required this.sectionNumber,
    required this.headingEn,
    this.headingTe,
    required this.bookmarkedAt,
  });

  /// Factory constructor to create a bookmark directly from a loaded [BnsSectionDetail].
  factory BookmarkedSection.fromDetail(
    BnsSectionDetail detail, {
    DateTime? bookmarkedAt,
  }) {
    final te = detail.headingTe.trim();
    return BookmarkedSection(
      sectionNumber: detail.sectionNumber,
      headingEn: detail.headingEn.trim(),
      headingTe: te.isNotEmpty ? te : null,
      bookmarkedAt: bookmarkedAt ?? DateTime.now(),
    );
  }

  /// Factory constructor to create a bookmark from a [BnsSectionSummary].
  factory BookmarkedSection.fromSummary(
    BnsSectionSummary summary, {
    DateTime? bookmarkedAt,
  }) {
    final te = summary.headingTe.trim();
    return BookmarkedSection(
      sectionNumber: summary.sectionNumber,
      headingEn: summary.headingEn.trim(),
      headingTe: te.isNotEmpty ? te : null,
      bookmarkedAt: bookmarkedAt ?? DateTime.now(),
    );
  }

  /// Deserializes a [BookmarkedSection] from a JSON map.
  ///
  /// Throws [FormatException] if required fields are missing, empty, or malformed.
  factory BookmarkedSection.fromJson(Map<String, dynamic> json) {
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

    final rawBookmarkedAt = json['bookmarked_at'];
    if (rawBookmarkedAt == null) {
      throw const FormatException('Missing required field: bookmarked_at');
    }
    final DateTime bookmarkedAt;
    if (rawBookmarkedAt is String) {
      final parsed = DateTime.tryParse(rawBookmarkedAt);
      if (parsed == null) {
        throw FormatException(
          'Invalid date format for bookmarked_at: $rawBookmarkedAt',
        );
      }
      bookmarkedAt = parsed;
    } else {
      throw FormatException('Invalid type for bookmarked_at: $rawBookmarkedAt');
    }

    return BookmarkedSection(
      sectionNumber: number,
      headingEn: rawHeadingEn.trim(),
      headingTe: headingTe,
      bookmarkedAt: bookmarkedAt,
    );
  }

  /// Serializes the bookmark metadata to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'section_number': sectionNumber,
      'heading_en': headingEn,
      if (headingTe != null && headingTe!.trim().isNotEmpty)
        'heading_te': headingTe!.trim(),
      'bookmarked_at': bookmarkedAt.toIso8601String(),
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
      other is BookmarkedSection &&
          runtimeType == other.runtimeType &&
          sectionNumber == other.sectionNumber &&
          headingEn == other.headingEn &&
          headingTe == other.headingTe &&
          bookmarkedAt.isAtSameMomentAs(other.bookmarkedAt);

  @override
  int get hashCode =>
      sectionNumber.hashCode ^
      headingEn.hashCode ^
      headingTe.hashCode ^
      bookmarkedAt.millisecondsSinceEpoch.hashCode;

  @override
  String toString() =>
      'BookmarkedSection(§$sectionNumber, headingEn: "$headingEn", headingTe: "$headingTe", bookmarkedAt: $bookmarkedAt)';
}
