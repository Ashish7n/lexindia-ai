import 'package:flutter/material.dart';
import '../../../core/language/language_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../bookmarks/controllers/bookmark_controller.dart';
import '../../bookmarks/models/bookmarked_section.dart';
import '../../history/controllers/history_controller.dart';
import '../../sections/screens/section_detail_screen.dart';
import '../../sections/services/section_repository.dart';

/// Screen displaying locally persisted BNS provisions saved by the user.
///
/// Features:
/// - Displays total count and list of saved provisions ordered by recency.
/// - Renders BNS section number, English heading, and Telugu heading (if available).
/// - Allows one-tap removal with rollback error handling and user feedback.
/// - Tap-through to full SectionDetailScreen with shared BookmarkController.
/// - Responsive EmptyState with one-tap action to browse provisions.
/// - Operates fully offline using cached bookmark metadata.
class SavedScreen extends StatefulWidget {
  final BookmarkController? bookmarkController;
  final HistoryController? historyController;
  final SectionRepository? sectionRepository;
  final LanguageController? languageController;
  final VoidCallback? onBrowsePressed;

  const SavedScreen({
    super.key,
    this.bookmarkController,
    this.historyController,
    this.sectionRepository,
    this.languageController,
    this.onBrowsePressed,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late final BookmarkController _bookmarkController;
  late final SectionRepository _repository;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookmarkController != null) {
      _bookmarkController = widget.bookmarkController!;
      _ownsController = false;
    } else {
      _bookmarkController = BookmarkController();
      _ownsController = true;
    }

    if (!_bookmarkController.isInitialized) {
      if (_ownsController) {
        _bookmarkController.initialize();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_bookmarkController.isInitialized) {
            _bookmarkController.initialize();
          }
        });
      }
    }

    _repository = widget.sectionRepository ?? SectionRepository();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _bookmarkController.dispose();
    }
    super.dispose();
  }

  String _formatBookmarkCount(int count) {
    if (count == 1) {
      return '1 provision saved';
    }
    return '$count provisions saved';
  }

  Future<void> _removeBookmark(BookmarkedSection bookmark) async {
    try {
      await _bookmarkController.removeBookmark(bookmark.sectionNumber);
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
              Text('BNS § ${bookmark.sectionNumber} removed from saved'),
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
              Expanded(child: Text('Failed to remove bookmark: $e')),
            ],
          ),
          backgroundColor: AppColors.statusError,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _removeBookmark(bookmark),
          ),
        ),
      );
    }
  }

  void _openSectionDetail(int sectionNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SectionDetailScreen(
          sectionNumber: sectionNumber,
          repository: _repository,
          bookmarkController: _bookmarkController,
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

    return ListenableBuilder(
      listenable: _bookmarkController,
      builder: (context, _) {
        final bookmarks = _bookmarkController.bookmarks;
        final count = bookmarks.length;

        return Scaffold(
          appBar: AppBar(title: const Text('Saved Sections')),
          body: count == 0
              ? EmptyState(
                  icon: Icons.bookmark_outline,
                  title: 'No Bookmarks Yet',
                  message:
                      'No saved sections yet. Browse provisions and tap the bookmark icon on any section to save it here for quick reference.',
                  actionLabel: 'Browse BNS Sections',
                  actionIcon: Icons.menu_book,
                  onAction: widget.onBrowsePressed ?? () {},
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subheader with section count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Saved Provisions',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.legalNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatBookmarkCount(count),
                            key: const Key('saved_count_label'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isDark
                                  ? AppColors.antiqueGoldLight
                                  : AppColors.antiqueGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          final bookmark = bookmarks[index];
                          return _buildBookmarkCard(
                            context: context,
                            theme: theme,
                            isDark: isDark,
                            bookmark: bookmark,
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBookmarkCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required BookmarkedSection bookmark,
  }) {
    final hasTelugu =
        bookmark.headingTe != null && bookmark.headingTe!.trim().isNotEmpty;

    return Card(
      key: Key('saved_card_${bookmark.sectionNumber}'),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSectionDetail(bookmark.sectionNumber),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Section Number Badge & Remove Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
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
                      'BNS § ${bookmark.sectionNumber}',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.antiqueGoldLight
                            : AppColors.legalNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    key: Key('remove_bookmark_${bookmark.sectionNumber}'),
                    icon: Icon(
                      Icons.bookmark_remove_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    tooltip:
                        'Remove Section ${bookmark.sectionNumber} from saved',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => _removeBookmark(bookmark),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // English Heading
              Text(
                bookmark.headingEn.trim().isNotEmpty
                    ? bookmark.headingEn.trim()
                    : 'Section ${bookmark.sectionNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),

              // Telugu Heading (when present)
              if (hasTelugu) ...[
                const SizedBox(height: 6),
                Text(
                  bookmark.headingTe!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.antiqueGoldLight
                        : AppColors.legalNavy,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
