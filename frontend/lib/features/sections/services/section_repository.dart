import '../../../core/network/api_client.dart';

import '../models/bns_section.dart';

/// Repository isolating all FastAPI BNS legal section network calls from the UI layer.
class SectionRepository {
  final ApiClient _apiClient;

  SectionRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Fetches a paginated list of BNS sections with optional search query.
  /// Server enforces: `page >= 1`, `1 <= pageSize <= 100`.
  /// Numeric search terms execute exact section number match on backend;
  /// text search executes case-insensitive substring search.
  Future<PaginatedSectionsResponse> getSections({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'Page must be 1 or greater');
    }
    if (pageSize < 1 || pageSize > 100) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'Page size must be between 1 and 100',
      );
    }

    final queryParams = <String, dynamic>{'page': page, 'page_size': pageSize};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    return _apiClient.get<PaginatedSectionsResponse>(
      '/sections/',
      queryParameters: queryParams,
      fromJson: (json) =>
          PaginatedSectionsResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches the full section record including source provenance and timestamps.
  /// Throws [NotFoundException] if the section does not exist.
  Future<BnsSectionDetail> getSectionDetail(int sectionNumber) async {
    if (sectionNumber < 1) {
      throw ArgumentError.value(
        sectionNumber,
        'sectionNumber',
        'Section number must be 1 or greater',
      );
    }

    return _apiClient.get<BnsSectionDetail>(
      '/sections/$sectionNumber',
      fromJson: (json) =>
          BnsSectionDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches legal provision text rendered in a specific language ('en' or 'te').
  /// Throws [BadRequestException] if an unsupported language is requested.
  /// Throws [NotFoundException] if the section does not exist.
  /// Note: Untranslated Telugu returns HTTP 200 with empty text and `not_translated` status.
  Future<BnsLanguageSection> getSectionByLanguage(
    int sectionNumber,
    String language,
  ) async {
    if (sectionNumber < 1) {
      throw ArgumentError.value(
        sectionNumber,
        'sectionNumber',
        'Section number must be 1 or greater',
      );
    }

    final lang = language.trim().toLowerCase();
    if (lang != 'en' && lang != 'te') {
      throw ArgumentError.value(
        language,
        'language',
        "Supported languages are 'en' (English) or 'te' (Telugu)",
      );
    }

    return _apiClient.get<BnsLanguageSection>(
      '/sections/$sectionNumber/language/$lang',
      fromJson: (json) =>
          BnsLanguageSection.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches current BNS translation progress counts from SQLite backend.
  Future<TranslationProgress> getTranslationProgress() async {
    return _apiClient.get<TranslationProgress>(
      '/sections/translation/progress',
      fromJson: (json) =>
          TranslationProgress.fromJson(json as Map<String, dynamic>),
    );
  }
}
