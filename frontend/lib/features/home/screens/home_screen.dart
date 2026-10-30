import 'package:flutter/material.dart';
import '../../../core/language/language_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../bookmarks/controllers/bookmark_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../sections/screens/section_detail_screen.dart';
import '../../sections/services/section_repository.dart';

/// Primary functional Home Dashboard for LexIndia-AI.
///
/// Features:
/// - Compact application identity and legal disclaimer.
/// - Prominent search bar navigating directly to Browse with prefilled query.
/// - Quick shortcut to browse all 358 BNS sections.
/// - Recently viewed provisions (up to 5 unique items, most recent first).
/// - Saved provisions summary with exact singular/plural counts and direct navigation.
/// - Clean first-launch guidance when history or bookmarks are empty.
/// - Operates fully offline using cached local controller state.
class HomeScreen extends StatefulWidget {
  final BookmarkController? bookmarkController;
  final HistoryController? historyController;
  final SectionRepository? sectionRepository;
  final LanguageController? languageController;
  final void Function(String query)? onSearchSubmitted;
  final VoidCallback? onBrowsePressed;
  final VoidCallback? onSavedPressed;

  const HomeScreen({
    super.key,
    this.bookmarkController,
    this.historyController,
    this.sectionRepository,
    this.languageController,
    this.onSearchSubmitted,
    this.onBrowsePressed,
    this.onSavedPressed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late final BookmarkController _bookmarkController;
  late final HistoryController _historyController;
  bool _ownsBookmarkController = false;
  bool _ownsHistoryController = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookmarkController != null) {
      _bookmarkController = widget.bookmarkController!;
      _ownsBookmarkController = false;
    } else {
      _bookmarkController = BookmarkController();
      _ownsBookmarkController = true;
    }
    if (!_bookmarkController.isInitialized) {
      if (_ownsBookmarkController) {
        _bookmarkController.initialize();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_bookmarkController.isInitialized) {
            _bookmarkController.initialize();
          }
        });
      }
    }

    if (widget.historyController != null) {
      _historyController = widget.historyController!;
      _ownsHistoryController = false;
    } else {
      _historyController = HistoryController();
      _ownsHistoryController = true;
    }
    if (!_historyController.isInitialized) {
      if (_ownsHistoryController) {
        _historyController.initialize();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_historyController.isInitialized) {
            _historyController.initialize();
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookmarkController != widget.bookmarkController &&
        widget.bookmarkController != null) {
      if (_ownsBookmarkController) {
        _bookmarkController.dispose();
      }
      _bookmarkController = widget.bookmarkController!;
      _ownsBookmarkController = false;
      if (!_bookmarkController.isInitialized) {
        _bookmarkController.initialize();
      }
    }

    if (oldWidget.historyController != widget.historyController &&
        widget.historyController != null) {
      if (_ownsHistoryController) {
        _historyController.dispose();
      }
      _historyController = widget.historyController!;
      _ownsHistoryController = false;
      if (!_historyController.isInitialized) {
        _historyController.initialize();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    if (_ownsBookmarkController) {
      _bookmarkController.dispose();
    }
    if (_ownsHistoryController) {
      _historyController.dispose();
    }
    super.dispose();
  }

  void _handleSearchSubmit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _searchFocusNode.unfocus();
    if (widget.onSearchSubmitted != null) {
      widget.onSearchSubmitted!(trimmed);
    } else if (widget.onBrowsePressed != null) {
      widget.onBrowsePressed!();
    }
  }

  void _openSectionDetail(int sectionNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SectionDetailScreen(
          sectionNumber: sectionNumber,
          repository: widget.sectionRepository ?? SectionRepository(),
          bookmarkController: _bookmarkController,
          historyController: _historyController,
          languageController: widget.languageController,
        ),
      ),
    );
  }

  String _formatSavedCount(int count) {
    if (count == 0) {
      return 'No saved provisions';
    } else if (count == 1) {
      return '1 provision saved';
    } else {
      return '$count provisions saved';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LexIndia-AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.antiqueGold.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'BNS 2023',
                  style: TextStyle(
                    color: AppColors.antiqueGoldLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_bookmarkController, _historyController]),
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. App Identity & Legal Introduction Card
                _buildWelcomeHeader(theme, isDark),
                const SizedBox(height: 20),

                // 2. Prominent Search Bar
                _buildSearchBar(theme, isDark),
                const SizedBox(height: 16),

                // 3. Quick Browse Shortcut Card
                _buildBrowseShortcut(theme, isDark),
                const SizedBox(height: 24),

                // 4. Recently Viewed Provisions Section (max 5)
                _buildRecentSection(theme, isDark),
                const SizedBox(height: 24),

                // 5. Saved Provisions Summary Card
                _buildSavedSection(theme, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.gavel,
                    color: isDark
                        ? AppColors.antiqueGoldLight
                        : AppColors.legalNavy,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BHARATIYA NYAYA SANHITA, 2023',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Legal Reference Application',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'LexIndia-AI is a legal-information reference tool designed for law students, aspirants, and the public to browse and read Bharatiya Nyaya Sanhita (BNS) provisions comfortably in English and Telugu.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Legal information reference only. Not legal advice.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find Legal Provision',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: TextField(
            key: const Key('home_search_input'),
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _handleSearchSubmit,
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
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  final hasText = value.text.isNotEmpty;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasText)
                        IconButton(
                          key: const Key('home_search_clear_button'),
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear search',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      IconButton(
                        key: const Key('home_search_submit_button'),
                        icon: const Icon(Icons.arrow_forward),
                        color: AppColors.antiqueGold,
                        tooltip: 'Search provisions',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () =>
                            _handleSearchSubmit(_searchController.text),
                      ),
                    ],
                  );
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseShortcut(ThemeData theme, bool isDark) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.antiqueGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.menu_book,
            color: AppColors.antiqueGold,
            size: 20,
          ),
        ),
        title: const Text('Browse 358 BNS Sections'),
        subtitle: const Text('Explore all chapters and legal provisions'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: widget.onBrowsePressed,
      ),
    );
  }

  Widget _buildRecentSection(ThemeData theme, bool isDark) {
    final recentItems = _historyController.history.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recently Viewed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (recentItems.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${recentItems.length} recent',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (recentItems.isEmpty)
          Card(
            key: const Key('recent_empty_card'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 28,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No recently viewed provisions',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Provisions you open will appear here for quick access.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        if (widget.onBrowsePressed != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: widget.onBrowsePressed,
                            child: const Text('Browse Provisions'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: recentItems.map((item) {
              final hasTelugu =
                  item.headingTe != null && item.headingTe!.trim().isNotEmpty;

              return Card(
                key: Key('recent_section_card_${item.sectionNumber}'),
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openSectionDetail(item.sectionNumber),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.antiqueGold.withValues(alpha: 0.2)
                                : AppColors.legalNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.antiqueGold.withValues(alpha: 0.5)
                                  : AppColors.legalNavy.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'BNS SECTION ${item.sectionNumber}',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.antiqueGoldLight
                                  : AppColors.legalNavy,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.headingEn,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasTelugu) ...[
                                const SizedBox(height: 3),
                                Text(
                                  item.headingTe!.trim(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.antiqueGoldLight
                                        : AppColors.legalNavy,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSavedSection(ThemeData theme, bool isDark) {
    final bookmarks = _bookmarkController.bookmarks;
    final count = bookmarks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Saved Provisions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0 && widget.onSavedPressed != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                key: const Key('home_view_all_saved_button'),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('View All'),
                onPressed: widget.onSavedPressed,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Card(
          key: const Key('home_saved_summary_card'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: count == 0
                ? Row(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 28,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatSavedCount(0),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap the bookmark icon on any section while reading to save it here for quick reference.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.antiqueGold.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bookmark,
                              color: AppColors.antiqueGold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatSavedCount(count),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Access your pinned provisions anytime offline.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onSavedPressed != null)
                            FilledButton.tonal(
                              key: const Key('home_open_saved_button'),
                              onPressed: widget.onSavedPressed,
                              child: const Text('Open'),
                            ),
                        ],
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: bookmarks.take(4).map((b) {
                            return ActionChip(
                              key: Key('saved_preview_chip_${b.sectionNumber}'),
                              avatar: const Icon(
                                Icons.bookmark,
                                size: 13,
                                color: AppColors.antiqueGold,
                              ),
                              label: Text(
                                '§ ${b.sectionNumber}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              tooltip:
                                  'Open Section ${b.sectionNumber}: ${b.headingEn}',
                              onPressed: () =>
                                  _openSectionDetail(b.sectionNumber),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
