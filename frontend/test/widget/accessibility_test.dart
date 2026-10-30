import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/language/language_controller.dart';
import 'package:lexindia_frontend/core/theme/app_theme.dart';
import 'package:lexindia_frontend/core/theme/theme_controller.dart';
import 'package:lexindia_frontend/features/bookmarks/controllers/bookmark_controller.dart';
import 'package:lexindia_frontend/features/bookmarks/models/bookmarked_section.dart';
import 'package:lexindia_frontend/features/browse/screens/browse_screen.dart';
import 'package:lexindia_frontend/features/home/screens/home_screen.dart';
import 'package:lexindia_frontend/features/saved/screens/saved_screen.dart';
import 'package:lexindia_frontend/features/sections/models/bns_section.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';
import 'package:lexindia_frontend/navigation/main_navigation.dart';
import 'package:lexindia_frontend/shared/widgets/error_view.dart';

class FakeA11ySectionRepository extends Fake implements SectionRepository {
  @override
  Future<PaginatedSectionsResponse> getSections({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    return const PaginatedSectionsResponse(
      total: 358,
      page: 2,
      pageSize: 20,
      totalPages: 18,
      sections: [
        BnsSectionSummary(
          sectionNumber: 21,
          headingEn: 'Special law',
          textEn: 'A special law is a law applicable to a particular subject.',
          headingTe: 'ప్రత్యేక చట్టము',
          textTe: 'ప్రత్యేక చట్టము అనగా నిర్దిష్ట విషయానికి వర్తించే చట్టము.',
          translationStatus: 'translated',
        ),
      ],
    );
  }

  @override
  Future<BnsSectionDetail> getSectionDetail(int sectionNumber) async {
    return BnsSectionDetail(
      sectionNumber: sectionNumber,
      headingEn: 'Special law definition',
      textEn: 'A special law is a law applicable to a particular subject.',
      headingTe: 'ప్రత్యేక చట్టము',
      textTe: 'ప్రత్యేక చట్టము అనగా నిర్దిష్ట విషయానికి వర్తించే చట్టము.',
      translationStatus: 'translated',
      source: 'India Code',
    );
  }

  @override
  Future<BnsLanguageSection> getSectionByLanguage(
    int sectionNumber,
    String language,
  ) async {
    return const BnsLanguageSection(
      sectionNumber: 21,
      language: 'en',
      heading: 'Special law definition',
      text: 'A special law is a law applicable to a particular subject.',
      translationStatus: 'source',
    );
  }
}

class FakeA11yBookmarkController extends Fake implements BookmarkController {
  @override
  bool get isInitialized => true;

  @override
  List<BookmarkedSection> get bookmarks => [
    BookmarkedSection(
      sectionNumber: 21,
      headingEn: 'Special law',
      headingTe: 'ప్రత్యేక చట్టము',
      bookmarkedAt: DateTime(2024, 7, 1),
    ),
  ];

  @override
  bool isBookmarked(int sectionNumber) => sectionNumber == 21;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  group('Accessibility & Semantics Tests', () {
    late FakeA11ySectionRepository fakeRepo;
    late FakeA11yBookmarkController fakeBookmarkController;

    setUp(() {
      fakeRepo = FakeA11ySectionRepository();
      fakeBookmarkController = FakeA11yBookmarkController();
    });

    testWidgets(
      'SectionDetailScreen has accessible semantic labels and tooltips on action buttons',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SectionDetailScreen(
              sectionNumber: 21,
              repository: fakeRepo,
              bookmarkController: fakeBookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Bookmark button has tooltip
        final bookmarkFinder = find.byKey(const Key('bookmark_action_button'));
        expect(bookmarkFinder, findsOneWidget);
        final bookmarkButton = tester.widget<IconButton>(bookmarkFinder);
        expect(bookmarkButton.tooltip, 'Remove bookmark');

        // Copy button has tooltip and key
        final copyFinder = find.byKey(const Key('copy_action_button'));
        expect(copyFinder, findsOneWidget);
        final copyButton = tester.widget<IconButton>(copyFinder);
        expect(copyButton.tooltip, 'Copy provision');

        // Previous and Next navigation buttons have tooltips and min touch target height >= 48
        final prevFinder = find.byKey(const Key('previous_section_button'));
        expect(prevFinder, findsOneWidget);
        final prevSize = tester.getSize(prevFinder);
        expect(prevSize.height, greaterThanOrEqualTo(48.0));

        final nextFinder = find.byKey(const Key('next_section_button'));
        expect(nextFinder, findsOneWidget);
        final nextSize = tester.getSize(nextFinder);
        expect(nextSize.height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets(
      'BrowseScreen pagination and search clear controls meet accessibility touch target sizing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: BrowseScreen(repository: fakeRepo)),
        );

        await tester.pumpAndSettle();

        // Previous and Next page buttons have minimum height >= 48
        final prevPageFinder = find.byKey(
          const Key('browse_previous_page_button'),
        );
        expect(prevPageFinder, findsOneWidget);
        final prevPageSize = tester.getSize(prevPageFinder);
        expect(prevPageSize.height, greaterThanOrEqualTo(48.0));

        final nextPageFinder = find.byKey(const Key('browse_next_page_button'));
        expect(nextPageFinder, findsOneWidget);
        final nextPageSize = tester.getSize(nextPageFinder);
        expect(nextPageSize.height, greaterThanOrEqualTo(48.0));

        // Type in search bar to show clear button and verify its touch target
        await tester.enterText(find.byType(TextField), 'theft');
        await tester.pumpAndSettle();

        final clearFinder = find.byKey(const Key('browse_search_clear_button'));
        expect(clearFinder, findsOneWidget);
        final clearSize = tester.getSize(clearFinder);
        expect(clearSize.width, greaterThanOrEqualTo(48.0));
        expect(clearSize.height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets(
      'SavedScreen remove bookmark button meets 48x48 touch target requirement',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SavedScreen(
              bookmarkController: fakeBookmarkController,
              sectionRepository: fakeRepo,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final removeFinder = find.byKey(const Key('remove_bookmark_21'));
        expect(removeFinder, findsOneWidget);
        final removeSize = tester.getSize(removeFinder);
        expect(removeSize.width, greaterThanOrEqualTo(48.0));
        expect(removeSize.height, greaterThanOrEqualTo(48.0));

        final removeButton = tester.widget<IconButton>(removeFinder);
        expect(removeButton.tooltip, contains('Remove Section 21'));
      },
    );

    testWidgets(
      'HomeScreen search controls have accessible tooltips and touch targets',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

        await tester.pumpAndSettle();

        // Submit search button has accessible touch target
        final submitFinder = find.byKey(const Key('home_search_submit_button'));
        expect(submitFinder, findsOneWidget);
        final submitSize = tester.getSize(submitFinder);
        expect(submitSize.width, greaterThanOrEqualTo(48.0));
        expect(submitSize.height, greaterThanOrEqualTo(48.0));

        // Enter search text and check clear button
        await tester.enterText(
          find.byKey(const Key('home_search_input')),
          'murder',
        );
        await tester.pumpAndSettle();

        final clearFinder = find.byKey(const Key('home_search_clear_button'));
        expect(clearFinder, findsOneWidget);
        final clearSize = tester.getSize(clearFinder);
        expect(clearSize.width, greaterThanOrEqualTo(48.0));
        expect(clearSize.height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets(
      'ErrorView retry button meets minimum accessible touch target size',
      (tester) async {
        var retryClicked = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorView(
                message: 'Test error message',
                onRetry: () {
                  retryClicked = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final retryFinder = find.byKey(const Key('error_view_retry_button'));
        expect(retryFinder, findsOneWidget);
        final retrySize = tester.getSize(retryFinder);
        expect(retrySize.height, greaterThanOrEqualTo(48.0));

        await tester.tap(retryFinder);
        expect(retryClicked, isTrue);
      },
    );

    testWidgets(
      'MainNavigation destinations expose descriptive tooltips for accessibility',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: MainNavigation(
              themeController: ThemeController(),
              languageController: LanguageController(),
              sectionRepository: fakeRepo,
              bookmarkController: fakeBookmarkController,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify all 4 navigation destinations exist with tooltips
        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.destinations.length, 4);
        final destinations = navBar.destinations.cast<NavigationDestination>();

        expect(destinations[0].tooltip, 'Home dashboard');
        expect(destinations[1].tooltip, 'Browse BNS sections');
        expect(destinations[2].tooltip, 'Saved provisions');
        expect(destinations[3].tooltip, 'Settings and preferences');
      },
    );

    testWidgets(
      'Contrast and theming: renders correctly in both Light and Dark themes',
      (tester) async {
        // Test Light Theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: SectionDetailScreen(
              sectionNumber: 21,
              repository: fakeRepo,
              bookmarkController: fakeBookmarkController,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Test Dark Theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: SectionDetailScreen(
              sectionNumber: 21,
              repository: fakeRepo,
              bookmarkController: fakeBookmarkController,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
