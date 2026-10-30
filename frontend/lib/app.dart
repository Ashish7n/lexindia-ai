import 'package:flutter/material.dart';
import 'core/language/language_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/bookmarks/controllers/bookmark_controller.dart';
import 'features/history/controllers/history_controller.dart';
import 'features/sections/services/section_repository.dart';
import 'navigation/main_navigation.dart';

/// Root application widget for LexIndia-AI.
/// Reactive to system, light, and dark theme changes via ThemeController.
class LexIndiaApp extends StatelessWidget {
  final ThemeController themeController;
  final LanguageController? languageController;
  final SectionRepository? sectionRepository;
  final BookmarkController? bookmarkController;
  final HistoryController? historyController;

  const LexIndiaApp({
    super.key,
    required this.themeController,
    this.languageController,
    this.sectionRepository,
    this.bookmarkController,
    this.historyController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'LexIndia-AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          home: MainNavigation(
            themeController: themeController,
            languageController: languageController,
            sectionRepository: sectionRepository,
            bookmarkController: bookmarkController,
            historyController: historyController,
          ),
        );
      },
    );
  }
}
