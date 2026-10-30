import '../../../core/network/api_exceptions.dart';

/// Summary representation of a Bharatiya Nyaya Sanhita (BNS) section,
/// matching the records returned by `GET /sections/`.
class BnsSectionSummary {
  final int sectionNumber;
  final String headingEn;
  final String textEn;
  final String headingTe;
  final String textTe;
  final String translationStatus;
  final String? source;

  const BnsSectionSummary({
    required this.sectionNumber,
    required this.headingEn,
    required this.textEn,
    required this.headingTe,
    required this.textTe,
    required this.translationStatus,
    this.source,
  });

  /// True if marked translated and actual Telugu content exists in both heading and text.
  bool get hasValidTelugu =>
      translationStatus == 'translated' &&
      headingTe.trim().isNotEmpty &&
      textTe.trim().isNotEmpty;

  /// Returns the appropriate heading based on the language requested ('te' or 'en').
  /// Falls back to English if Telugu content is unavailable.
  String getHeading(String language) {
    if (language.toLowerCase() == 'te' && headingTe.trim().isNotEmpty) {
      return headingTe;
    }
    return headingEn;
  }

  factory BnsSectionSummary.fromJson(Map<String, dynamic> json) {
    final rawNumber = json['section_number'];
    if (rawNumber == null) {
      throw const MalformedResponseException(
        'Missing required field: section_number',
      );
    }

    final int number;
    if (rawNumber is int) {
      number = rawNumber;
    } else {
      number =
          int.tryParse(rawNumber.toString()) ??
          (throw MalformedResponseException(
            'Invalid section_number format: $rawNumber',
          ));
    }

    return BnsSectionSummary(
      sectionNumber: number,
      headingEn: json['heading_en'] as String? ?? '',
      textEn: json['text_en'] as String? ?? '',
      headingTe: json['heading_te'] as String? ?? '',
      textTe: json['text_te'] as String? ?? '',
      translationStatus:
          json['translation_status'] as String? ?? 'not_translated',
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_number': sectionNumber,
      'heading_en': headingEn,
      'text_en': textEn,
      'heading_te': headingTe,
      'text_te': textTe,
      'translation_status': translationStatus,
      if (source != null) 'source': source,
    };
  }
}

/// Detailed BNS section representation matching `GET /sections/{section_number}`.
/// Includes provenance source and updated_at timestamp.
class BnsSectionDetail extends BnsSectionSummary {
  final String? updatedAt;

  const BnsSectionDetail({
    required super.sectionNumber,
    required super.headingEn,
    required super.textEn,
    required super.headingTe,
    required super.textTe,
    required super.translationStatus,
    super.source,
    this.updatedAt,
  });

  factory BnsSectionDetail.fromJson(Map<String, dynamic> json) {
    final summary = BnsSectionSummary.fromJson(json);

    return BnsSectionDetail(
      sectionNumber: summary.sectionNumber,
      headingEn: summary.headingEn,
      textEn: summary.textEn,
      headingTe: summary.headingTe,
      textTe: summary.textTe,
      translationStatus: summary.translationStatus,
      source: json['source'] as String? ?? summary.source,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (updatedAt != null) {
      map['updated_at'] = updatedAt;
    }
    return map;
  }
}

/// Representation of a section viewed in a specific language ('en' or 'te'),
/// matching `GET /sections/{section_number}/language/{language}`.
class BnsLanguageSection {
  final int sectionNumber;
  final String language;
  final String heading;
  final String text;
  final String? translationStatus;

  const BnsLanguageSection({
    required this.sectionNumber,
    required this.language,
    required this.heading,
    required this.text,
    this.translationStatus,
  });

  /// True if the text or heading has non-empty content.
  bool get hasContent => heading.trim().isNotEmpty || text.trim().isNotEmpty;

  /// True if this represents a valid, non-empty Telugu translation.
  bool get isAvailableTelugu =>
      language == 'te' && translationStatus == 'translated' && hasContent;

  /// True if Telugu was requested but the section has not yet been translated.
  bool get isMissingTelugu =>
      language == 'te' && (translationStatus != 'translated' || !hasContent);

  factory BnsLanguageSection.fromJson(Map<String, dynamic> json) {
    final rawNumber = json['section_number'];
    final rawLanguage = json['language'];

    if (rawNumber == null || rawLanguage == null) {
      throw const MalformedResponseException(
        'Missing section_number or language in language endpoint response',
      );
    }

    final int number = rawNumber is int
        ? rawNumber
        : int.tryParse(rawNumber.toString()) ??
              (throw MalformedResponseException(
                'Invalid section_number: $rawNumber',
              ));

    return BnsLanguageSection(
      sectionNumber: number,
      language: rawLanguage.toString(),
      heading: json['heading'] as String? ?? '',
      text: json['text'] as String? ?? '',
      translationStatus: json['translation_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_number': sectionNumber,
      'language': language,
      'heading': heading,
      'text': text,
      if (translationStatus != null) 'translation_status': translationStatus,
    };
  }
}

/// Paginated wrapper for section listings matching `GET /sections/`.
class PaginatedSectionsResponse {
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final List<BnsSectionSummary> sections;

  const PaginatedSectionsResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.sections,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
  bool get isEmpty => total == 0 || sections.isEmpty;

  factory PaginatedSectionsResponse.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('total') ||
        !json.containsKey('page') ||
        !json.containsKey('page_size') ||
        !json.containsKey('total_pages') ||
        !json.containsKey('sections')) {
      throw const MalformedResponseException(
        'Response missing required pagination keys',
      );
    }

    final rawSections = json['sections'];
    if (rawSections is! List) {
      throw const MalformedResponseException(
        'Field "sections" must be a JSON array',
      );
    }

    final sectionsList = rawSections
        .map((item) => BnsSectionSummary.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedSectionsResponse(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 0,
      sections: sectionsList,
    );
  }
}

/// Progress statistics matching `GET /sections/translation/progress`.
class TranslationProgress {
  final int totalSections;
  final int translatedSections;
  final int remainingSections;

  const TranslationProgress({
    required this.totalSections,
    required this.translatedSections,
    required this.remainingSections,
  });

  double get fractionTranslated =>
      totalSections > 0 ? translatedSections / totalSections : 0.0;

  double get percentageTranslated => fractionTranslated * 100.0;

  factory TranslationProgress.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('total_sections') ||
        !json.containsKey('translated_sections') ||
        !json.containsKey('remaining_sections')) {
      throw const MalformedResponseException(
        'Missing keys in translation progress response',
      );
    }

    return TranslationProgress(
      totalSections: json['total_sections'] as int? ?? 0,
      translatedSections: json['translated_sections'] as int? ?? 0,
      remainingSections: json['remaining_sections'] as int? ?? 0,
    );
  }
}
