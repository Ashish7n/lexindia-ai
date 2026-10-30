import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/language/language_controller.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../models/bns_section.dart';
import '../services/section_repository.dart';
import '../widgets/language_selector.dart';
import '../../bookmarks/controllers/bookmark_controller.dart';
import '../../bookmarks/models/bookmarked_section.dart';
import '../../history/controllers/history_controller.dart';
import '../../history/models/history_item.dart';

/// Screen displaying the full legal provision text, language switching,
/// translation verification status, source provenance, copy capabilities,
/// and sequential Previous/Next BNS section navigation.
class SectionDetailScreen extends StatefulWidget {
  final int sectionNumber;
  final SectionRepository? repository;
  final BookmarkController? bookmarkController;
  final HistoryController? historyController;
  final LanguageController? languageController;
  final String? initialLanguage;
  final int minSectionNumber;
  final int maxSectionNumber;

  const SectionDetailScreen({
    super.key,
    required this.sectionNumber,
    this.repository,
    this.bookmarkController,
    this.historyController,
    this.languageController,
    this.initialLanguage,
    this.minSectionNumber = 1,
    this.maxSectionNumber = 358,
  });

  @override
  State<SectionDetailScreen> createState() => SectionDetailScreenState();
}

class SectionDetailScreenState extends State<SectionDetailScreen> {
  late final SectionRepository _repository;
  late final BookmarkController _bookmarkController;
  bool _ownsBookmarkController = false;

  late final HistoryController _historyController;
  bool _ownsHistoryController = false;
  final ScrollController _scrollController = ScrollController();

  late int _currentSectionNumber;
  int? _pendingSectionNumber;
  late String _currentLanguage;
  bool _isLoading = true;
  String _loadingMessage = 'Loading section provision...';
  String? _errorMessage;

  BnsSectionDetail? _detail;
  BnsLanguageSection? _languageSection;

  // Stale response protection tokens
  int _languageRequestId = 0;
  int _navigationRequestId = 0;

  @override
  void initState() {
    super.initState();
    _currentSectionNumber = widget.sectionNumber;
    _currentLanguage =
        widget.initialLanguage ??
        widget.languageController?.defaultLanguage ??
        'en';
    _repository = widget.repository ?? SectionRepository();

    if (widget.bookmarkController != null) {
      _bookmarkController = widget.bookmarkController!;
      _ownsBookmarkController = false;
    } else {
      _bookmarkController = BookmarkController();
      _ownsBookmarkController = true;
    }
    _bookmarkController.addListener(_onBookmarkChanged);
    if (!_bookmarkController.isInitialized) {
      _bookmarkController.initialize();
    }

    if (widget.historyController != null) {
      _historyController = widget.historyController!;
      _ownsHistoryController = false;
    } else {
      _historyController = HistoryController();
      _ownsHistoryController = true;
    }
    if (!_historyController.isInitialized) {
      _historyController.initialize();
    }

    _loadInitialData();
  }

  void _onBookmarkChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant SectionDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookmarkController != widget.bookmarkController) {
      oldWidget.bookmarkController?.removeListener(_onBookmarkChanged);
      if (widget.bookmarkController != null) {
        _bookmarkController = widget.bookmarkController!;
        _ownsBookmarkController = false;
      } else {
        _bookmarkController = BookmarkController();
        _ownsBookmarkController = true;
      }
      _bookmarkController.addListener(_onBookmarkChanged);
      if (!_bookmarkController.isInitialized) {
        _bookmarkController.initialize();
      }
    }
    if (oldWidget.historyController != widget.historyController) {
      if (widget.historyController != null) {
        _historyController = widget.historyController!;
        _ownsHistoryController = false;
      } else {
        _historyController = HistoryController();
        _ownsHistoryController = true;
      }
      if (!_historyController.isInitialized) {
        _historyController.initialize();
      }
    }
    if (oldWidget.sectionNumber != widget.sectionNumber) {
      _currentSectionNumber = widget.sectionNumber;
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _bookmarkController.removeListener(_onBookmarkChanged);
    if (_ownsBookmarkController) {
      _bookmarkController.dispose();
    }
    if (_ownsHistoryController) {
      _historyController.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _loadingMessage = 'Loading section provision...';
    await _fetchSectionData(_currentSectionNumber, isInitial: true);
  }

  Future<void> _fetchSectionData(
    int sectionNumber, {
    bool isInitial = false,
  }) async {
    final requestId = ++_navigationRequestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pendingSectionNumber = sectionNumber;
      if (isInitial) {
        _loadingMessage = 'Loading section provision...';
      } else {
        _loadingMessage = 'Loading Section $sectionNumber provision...';
      }
    });

    try {
      // Fetch full detail for provenance source and updated_at
      final detail = await _repository.getSectionDetail(sectionNumber);
      // Fetch provision in currently selected language
      final langSection = await _repository.getSectionByLanguage(
        sectionNumber,
        _currentLanguage,
      );

      if (!mounted || requestId != _navigationRequestId) return;

      setState(() {
        _currentSectionNumber = sectionNumber;
        _pendingSectionNumber = null;
        _detail = detail;
        _languageSection = langSection;
        _isLoading = false;
        _errorMessage = null;
      });

      // Record viewing history for successfully loaded section
      _recordHistoryVisit(detail);

      // Reset scroll position to top of new section
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
    } on NotFoundException {
      if (!mounted || requestId != _navigationRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Section $sectionNumber was not found in the BNS database.';
      });
    } on NetworkException catch (e) {
      if (!mounted || requestId != _navigationRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _navigationRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted || requestId != _navigationRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'An unexpected error occurred while loading section $sectionNumber.';
      });
    }
  }

  Future<void> _navigateToSection(int targetSection) async {
    if (targetSection < widget.minSectionNumber ||
        targetSection > widget.maxSectionNumber) {
      return;
    }
    await _fetchSectionData(targetSection);
  }

  @visibleForTesting
  Future<void> navigateToSectionForTesting(int targetSection) async {
    await _navigateToSection(targetSection);
  }

  @visibleForTesting
  bool get isLoadingForTesting => _isLoading;

  @visibleForTesting
  String? get errorMessageForTesting => _errorMessage;

  @visibleForTesting
  BnsSectionDetail? get detailForTesting => _detail;

  @visibleForTesting
  HistoryController get historyControllerForTesting => _historyController;

  @visibleForTesting
  String get currentLanguageForTesting => _currentLanguage;

  Future<void> _onLanguageChanged(String language) async {
    if (_currentLanguage == language) return;

    final requestId = ++_languageRequestId;
    setState(() {
      _currentLanguage = language;
      _isLoading = true;
      _loadingMessage = 'Updating language provision...';
      _errorMessage = null;
    });

    try {
      final langSection = await _repository.getSectionByLanguage(
        _currentSectionNumber,
        language,
      );

      if (!mounted || requestId != _languageRequestId) return;

      setState(() {
        _languageSection = langSection;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _languageRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted || requestId != _languageRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load $language version. Please try again.';
      });
    }
  }

  void _copyToClipboard() {
    final heading = _languageSection?.heading ?? _detail?.headingEn ?? '';
    final text = _languageSection?.text ?? _detail?.textEn ?? '';

    final copyText =
        '''
Bharatiya Nyaya Sanhita, 2023
Section $_currentSectionNumber: $heading

$text

[Source: ${_detail?.source ?? 'India Code'}]
'''
            .trim();

    Clipboard.setData(ClipboardData(text: copyText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text('BNS § $_currentSectionNumber copied to clipboard'),
          ],
        ),
        backgroundColor: AppColors.legalNavy,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleBookmark() async {
    final detail = _detail;
    if (detail == null) return;

    final bookmark = BookmarkedSection.fromDetail(detail);

    try {
      final isNowSaved = await _bookmarkController.toggleBookmark(bookmark);
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isNowSaved ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isNowSaved
                      ? 'BNS § ${detail.sectionNumber} saved to bookmarks'
                      : 'BNS § ${detail.sectionNumber} removed from bookmarks',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.legalNavy,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to update bookmark: $e')),
            ],
          ),
          backgroundColor: AppColors.statusError,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _toggleBookmark,
          ),
        ),
      );
    }
  }

  Future<void> _recordHistoryVisit(BnsSectionDetail detail) async {
    try {
      final historyItem = HistoryItem.fromDetail(detail);
      await _historyController.recordVisit(historyItem);
    } catch (_) {
      // Non-fatal: persistence failure should not disrupt legal provision reading
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSaved = _bookmarkController.isBookmarked(_currentSectionNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text('BNS § $_currentSectionNumber'),
        actions: [
          IconButton(
            key: const Key('bookmark_action_button'),
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_outline,
              color: isSaved ? AppColors.antiqueGold : null,
            ),
            tooltip: isSaved ? 'Remove bookmark' : 'Bookmark section',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: (_isLoading || _errorMessage != null || _detail == null)
                ? null
                : _toggleBookmark,
          ),
          IconButton(
            key: const Key('copy_action_button'),
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy provision',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: (_isLoading || _errorMessage != null)
                ? null
                : _copyToClipboard,
          ),
        ],
      ),
      body: _buildBody(theme, isDark),
      bottomNavigationBar: _buildBottomNavigation(theme, isDark),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return LoadingView(message: _loadingMessage);
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: () => _fetchSectionData(
          _pendingSectionNumber ?? _currentSectionNumber,
          isInitial: _detail == null,
        ),
      );
    }

    final isUntranslatedTelugu =
        _currentLanguage == 'te' &&
        (_languageSection?.isMissingTelugu ??
            (_detail?.hasValidTelugu != true));

    return Column(
      children: [
        // Top Toolbar: Language Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Select Language:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              LanguageSelector(
                currentLanguage: _currentLanguage,
                isLoading: _isLoading,
                onLanguageChanged: _onLanguageChanged,
              ),
            ],
          ),
        ),

        // Main Provision Body
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Untranslated Telugu Notice
                if (isUntranslatedTelugu) ...[
                  _buildUntranslatedNotice(theme, isDark),
                  const SizedBox(height: 20),
                ] else if (_currentLanguage == 'te') ...[
                  // Translated Telugu Disclaimer Notice
                  _buildTranslationDisclaimerTag(theme, isDark),
                  const SizedBox(height: 16),
                ],

                // Provision Heading
                Text(
                  _getDisplayHeading(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.legalNavy,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 16),

                // Full Legal Text
                if (!isUntranslatedTelugu)
                  SelectableText(
                    _getDisplayText(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.65,
                      letterSpacing: 0.15,
                    ),
                  ),

                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 16),

                // Source & Provenance Metadata Card
                _buildProvenanceCard(theme, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(ThemeData theme, bool isDark) {
    final canGoPrevious =
        !_isLoading &&
        _detail != null &&
        _currentSectionNumber > widget.minSectionNumber;
    final canGoNext =
        !_isLoading &&
        _detail != null &&
        _currentSectionNumber < widget.maxSectionNumber;
    final prevSection = _currentSectionNumber - 1;
    final nextSection = _currentSectionNumber + 1;

    return Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Previous Section Button
              Expanded(
                child: Tooltip(
                  message: canGoPrevious
                      ? 'Go to previous section BNS § $prevSection'
                      : 'No previous section',
                  child: OutlinedButton.icon(
                    key: const Key('previous_section_button'),
                    onPressed: canGoPrevious
                        ? () => _navigateToSection(prevSection)
                        : null,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(
                      canGoPrevious ? 'Previous (§ $prevSection)' : 'Previous',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Next Section Button
              Expanded(
                child: Tooltip(
                  message: canGoNext
                      ? 'Go to next section BNS § $nextSection'
                      : 'No next section',
                  child: OutlinedButton.icon(
                    key: const Key('next_section_button'),
                    onPressed: canGoNext
                        ? () => _navigateToSection(nextSection)
                        : null,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      canGoNext ? 'Next (§ $nextSection)' : 'Next',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayHeading() {
    if (_currentLanguage == 'te' &&
        _languageSection != null &&
        _languageSection!.heading.trim().isNotEmpty) {
      return _languageSection!.heading.trim();
    }
    return _detail?.headingEn.trim() ?? 'Section $_currentSectionNumber';
  }

  String _getDisplayText() {
    if (_currentLanguage == 'te' &&
        _languageSection != null &&
        _languageSection!.text.trim().isNotEmpty) {
      return _languageSection!.text.trim();
    }
    return _detail?.textEn.trim() ?? '';
  }

  Widget _buildUntranslatedNotice(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.antiqueGold.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.antiqueGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Telugu translation is not yet available for this section.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The official English text is available and verified from the source Act. You can switch back to English to read the legal provision.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _onLanguageChanged('en'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('View English Provision'),
            style: FilledButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.antiqueGoldLight
                  : AppColors.legalNavy,
              foregroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationDisclaimerTag(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.antiqueGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.antiqueGold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.gavel_outlined,
            size: 16,
            color: AppColors.antiqueGold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Telugu reference translation (Draft / Informational reference only).',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.antiqueGoldLight
                    : AppColors.legalNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvenanceCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: AppColors.antiqueGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'STATUTORY PROVENANCE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.antiqueGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _detail?.source ?? 'India Code — Bharatiya Nyaya Sanhita, 2023',
              style: theme.textTheme.bodySmall,
            ),
            if (_detail?.updatedAt != null &&
                _detail!.updatedAt!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Database record updated: ${_detail!.updatedAt}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
