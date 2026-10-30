import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/language/language_controller.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../bookmarks/controllers/bookmark_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../sections/models/bns_section.dart';
import '../../sections/screens/section_detail_screen.dart';
import '../../sections/services/section_repository.dart';
import '../../sections/widgets/section_card.dart';

/// Interactive Browse and Search screen for Bharatiya Nyaya Sanhita (BNS) provisions.
/// Connected to live FastAPI backend with server-side pagination, 300ms debounced search,
/// exact-numeric query preservation, and stale response protection.
class BrowseScreen extends StatefulWidget {
  final SectionRepository? repository;
  final BookmarkController? bookmarkController;
  final HistoryController? historyController;
  final LanguageController? languageController;
  final String? initialQuery;

  const BrowseScreen({
    super.key,
    this.repository,
    this.bookmarkController,
    this.historyController,
    this.languageController,
    this.initialQuery,
  });

  @override
  State<BrowseScreen> createState() => BrowseScreenState();
}

class BrowseScreenState extends State<BrowseScreen> {
  late final SectionRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;

  // Stale-response protection token
  int _activeRequestGeneration = 0;

  bool _isLoading = true;
  String? _errorMessage;

  PaginatedSectionsResponse? _response;
  String _currentQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SectionRepository();
    final query = widget.initialQuery?.trim() ?? '';
    if (query.isNotEmpty) {
      _searchController.text = query;
      _currentQuery = query;
    }
    _fetchSections(page: 1, query: _currentQuery);
  }

  @override
  void didUpdateWidget(covariant BrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != null &&
        widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery!.trim() != _currentQuery) {
      setSearchQuery(widget.initialQuery!);
    }
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    _searchController.text = trimmed;
    _debounceTimer?.cancel();
    _currentPage = 1;
    _currentQuery = trimmed;
    _fetchSections(page: 1, query: trimmed);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _executeSearch(text);
    });
  }

  void _executeSearch(String query) {
    final trimmed = query.trim();
    if (trimmed == _currentQuery && !_isLoading && _response != null) return;

    _currentPage = 1;
    _currentQuery = trimmed;
    _fetchSections(page: 1, query: trimmed);
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    _currentPage = 1;
    _currentQuery = '';
    _fetchSections(page: 1, query: '');
  }

  Future<void> _fetchSections({
    required int page,
    required String query,
  }) async {
    final generation = ++_activeRequestGeneration;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.getSections(
        page: page,
        pageSize: _pageSize,
        search: query.isNotEmpty ? query : null,
      );

      if (!mounted || generation != _activeRequestGeneration) return;

      setState(() {
        _response = response;
        _currentPage = page;
        _isLoading = false;
      });

      // Reset scroll position to top of list after page load
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } on NetworkException catch (e) {
      if (!mounted || generation != _activeRequestGeneration) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      if (_response != null) {
        _showErrorSnackBar(
          e.message,
          () => _fetchSections(page: page, query: query),
        );
      }
    } on ApiException catch (e) {
      if (!mounted || generation != _activeRequestGeneration) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      if (_response != null) {
        _showErrorSnackBar(
          e.message,
          () => _fetchSections(page: page, query: query),
        );
      }
    } catch (e) {
      if (!mounted || generation != _activeRequestGeneration) return;
      const message =
          'Unable to connect to the legal database. Please verify the backend is running.';
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
      if (_response != null) {
        _showErrorSnackBar(
          message,
          () => _fetchSections(page: page, query: query),
        );
      }
    }
  }

  void _showErrorSnackBar(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.statusError,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (_isLoading) return;
    if (page < 1 || (_response != null && page > _response!.totalPages)) return;
    _fetchSections(page: page, query: _currentQuery);
  }

  void _openSectionDetail(int sectionNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SectionDetailScreen(
          sectionNumber: sectionNumber,
          repository: _repository,
          bookmarkController: widget.bookmarkController,
          historyController: widget.historyController,
          languageController: widget.languageController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse BNS', overflow: TextOverflow.ellipsis),
        actions: [
          if (_response != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.antiqueGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.antiqueGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${_response!.total} Sections',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.antiqueGoldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Header Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _executeSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                    'Search section number or keyword (e.g. 1, 42, theft)...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        key: const Key('browse_search_clear_button'),
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear search',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          // Main Section List / State View
          Expanded(child: _buildListContent(theme, isDark)),

          // Pagination Bar (pinned to bottom when data is available)
          if (_response != null && _response!.totalPages > 1 && !_isLoading)
            _buildPaginationBar(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildListContent(ThemeData theme, bool isDark) {
    if (_isLoading && _response == null) {
      return const LoadingView(message: 'Fetching BNS legal provisions...');
    }

    if (_errorMessage != null && _response == null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: () => _fetchSections(page: _currentPage, query: _currentQuery),
      );
    }

    if (_response != null && _response!.isEmpty) {
      return EmptyState(
        title: 'No Matching Provisions Found',
        message: _currentQuery.isNotEmpty
            ? 'No sections matched "$_currentQuery". You can search by section number (e.g. 1, 42) or keyword (e.g. murder, theft).'
            : 'No BNS sections are currently available.',
        actionLabel: 'Clear Search',
        onAction: _clearSearch,
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _response?.sections.length ?? 0,
          itemBuilder: (context, index) {
            final section = _response!.sections[index];
            return SectionCard(
              section: section,
              onTap: () => _openSectionDetail(section.sectionNumber),
            );
          },
        ),
        if (_isLoading)
          Container(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: 0.5,
            ),
            child: const LoadingView(message: 'Updating search results...'),
          ),
      ],
    );
  }

  Widget _buildPaginationBar(ThemeData theme, bool isDark) {
    final response = _response!;
    final canGoBack = response.hasPreviousPage;
    final canGoForward = response.hasNextPage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            // Previous Page Button
            Tooltip(
              message: canGoBack
                  ? 'Go to previous page (${_currentPage - 1})'
                  : 'Already on first page',
              child: OutlinedButton.icon(
                key: const Key('browse_previous_page_button'),
                onPressed: canGoBack ? () => _goToPage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),

            // Page Indicator Text
            Text(
              'Page ${response.page} of ${response.totalPages}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            // Next Page Button
            Tooltip(
              message: canGoForward
                  ? 'Go to next page (${_currentPage + 1})'
                  : 'Already on last page',
              child: OutlinedButton.icon(
                key: const Key('browse_next_page_button'),
                onPressed: canGoForward
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Next'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
