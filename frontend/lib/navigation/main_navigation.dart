import 'package:flutter/material.dart';
import '../core/language/language_controller.dart';
import '../core/theme/theme_controller.dart';
import '../features/bookmarks/controllers/bookmark_controller.dart';
import '../features/browse/screens/browse_screen.dart';
import '../features/history/controllers/history_controller.dart';
import '../features/home/screens/home_screen.dart';
import '../features/saved/screens/saved_screen.dart';
import '../features/sections/services/section_repository.dart';
import '../features/settings/screens/settings_screen.dart';

/// Primary four-destination navigation shell for LexIndia-AI:
/// 1. Home
/// 2. Browse
/// 3. Saved
/// 4. Settings
class MainNavigation extends StatefulWidget {
  final ThemeController themeController;
  final LanguageController? languageController;
  final SectionRepository? sectionRepository;
  final BookmarkController? bookmarkController;
  final HistoryController? historyController;

  const MainNavigation({
    super.key,
    required this.themeController,
    this.languageController,
    this.sectionRepository,
    this.bookmarkController,
    this.historyController,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final BookmarkController _bookmarkController;
  late final HistoryController _historyController;
  late final LanguageController _languageController;
  bool _ownsBookmarkController = false;
  bool _ownsHistoryController = false;
  bool _ownsLanguageController = false;

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

    if (widget.languageController != null) {
      _languageController = widget.languageController!;
      _ownsLanguageController = false;
    } else {
      _languageController = LanguageController();
      _ownsLanguageController = true;
    }
    if (!_languageController.isInitialized) {
      _languageController.initialize();
    }
  }

  @override
  void dispose() {
    if (_ownsBookmarkController) {
      _bookmarkController.dispose();
    }
    if (_ownsHistoryController) {
      _historyController.dispose();
    }
    if (_ownsLanguageController) {
      _languageController.dispose();
    }
    super.dispose();
  }

  String? _browseQuery;
  final GlobalKey<BrowseScreenState> _browseKey =
      GlobalKey<BrowseScreenState>();

  void _openBrowseWithQuery(String query) {
    setState(() {
      _browseQuery = query;
      _currentIndex = 1;
    });
    _browseKey.currentState?.setSearchQuery(query);
  }

  void _onDestinationSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        bookmarkController: _bookmarkController,
        historyController: _historyController,
        sectionRepository: widget.sectionRepository,
        languageController: _languageController,
        onSearchSubmitted: _openBrowseWithQuery,
        onBrowsePressed: () => _onDestinationSelected(1),
        onSavedPressed: () => _onDestinationSelected(2),
      ),
      BrowseScreen(
        key: _browseKey,
        repository: widget.sectionRepository,
        bookmarkController: _bookmarkController,
        historyController: _historyController,
        languageController: _languageController,
        initialQuery: _browseQuery,
      ),
      SavedScreen(
        bookmarkController: _bookmarkController,
        historyController: _historyController,
        sectionRepository: widget.sectionRepository,
        languageController: _languageController,
        onBrowsePressed: () => _onDestinationSelected(1),
      ),
      SettingsScreen(
        themeController: widget.themeController,
        languageController: _languageController,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Home',
            tooltip: 'Home dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Browse',
            tooltip: 'Browse BNS sections',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
            tooltip: 'Saved provisions',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'Settings and preferences',
          ),
        ],
      ),
    );
  }
}
