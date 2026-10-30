import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/theme/theme_controller.dart';
import 'package:lexindia_frontend/features/browse/screens/browse_screen.dart';
import 'package:lexindia_frontend/features/home/screens/home_screen.dart';
import 'package:lexindia_frontend/features/saved/screens/saved_screen.dart';
import 'package:lexindia_frontend/features/sections/models/bns_section.dart';
import 'package:lexindia_frontend/features/sections/screens/section_detail_screen.dart';
import 'package:lexindia_frontend/features/sections/services/section_repository.dart';
import 'package:lexindia_frontend/features/settings/screens/about_screen.dart';
import 'package:lexindia_frontend/features/settings/screens/settings_screen.dart';

class FakeResponsiveSectionRepository extends Fake
    implements SectionRepository {
  @override
  Future<PaginatedSectionsResponse> getSections({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    return PaginatedSectionsResponse(
      total: 358,
      page: page,
      pageSize: pageSize,
      totalPages: 18,
      sections: const [
        BnsSectionSummary(
          sectionNumber: 1,
          headingEn:
              'Short title, commencement and application of this Sanhita throughout the territory of India',
          textEn: 'This Act may be called the Bharatiya Nyaya Sanhita, 2023.',
          headingTe:
              'ఈ సంహిత యొక్క సంక్షిప్త నామము, ప్రారంభము మరియు భారతదేశ భూభాగమంతటా వర్తింపు',
          textTe: 'ఈ చట్టాన్ని భారతీయ న్యాయ సంహిత, 2023 అని పిలవవచ్చు.',
          translationStatus: 'translated',
        ),
        BnsSectionSummary(
          sectionNumber: 2,
          headingEn:
              'Definitions and interpretations of critical legal phrases used in the statutory provisions',
          textEn:
              'In this Sanhita, unless the context otherwise requires, the following definitions apply.',
          headingTe: '',
          textTe: '',
          translationStatus: 'not_translated',
        ),
      ],
    );
  }

  @override
  Future<BnsSectionDetail> getSectionDetail(int sectionNumber) async {
    return BnsSectionDetail(
      sectionNumber: sectionNumber,
      headingEn:
          'Punishment for murder and aggravated culpable homicide under Bharatiya Nyaya Sanhita, 2023',
      textEn:
          'Whoever commits murder shall be punished with death or imprisonment for life, and shall also be liable to fine. Detailed statutory provisions follow regarding exceptions and mitigations.',
      headingTe:
          'భారతీయ న్యాయ సంహిత, 2023 క్రింద హత్య మరియు తీవ్ర నేరపూరిత నరహత్యకు శిక్ష',
      textTe:
          'హత్య చేసిన వ్యక్తికి మరణశిక్ష లేదా జీవిత ఖైదు విధించబడుతుంది మరియు జరిమానా కూడా విధించబడుతుంది. మినహాయింపులు మరియు ఉపశమనాలకు సంబంధించిన వివరణాత్మక చట్టబద్ధమైన నిబంధనలు క్రింద ఇవ్వబడ్డాయి.',
      translationStatus: 'translated',
      source: 'India Code — Bharatiya Nyaya Sanhita, 2023 (Act No. 45 of 2023)',
      updatedAt: '2024-07-01T00:00:00Z',
    );
  }

  @override
  Future<BnsLanguageSection> getSectionByLanguage(
    int sectionNumber,
    String language,
  ) async {
    if (language == 'te') {
      return const BnsLanguageSection(
        sectionNumber: 103,
        language: 'te',
        heading:
            'భారతీయ న్యాయ సంహిత, 2023 క్రింద హత్య మరియు తీవ్ర నేరపూరిత నరహత్యకు శిక్ష',
        text:
            'హత్య చేసిన వ్యక్తికి మరణశిక్ష లేదా జీవిత ఖైదు విధించబడుతుంది మరియు జరిమానా కూడా విధించబడుతుంది. మినహాయింపులు మరియు ఉపశమనాలకు సంబంధించిన వివరణాత్మక చట్టబద్ధమైన నిబంధనలు క్రింద ఇవ్వబడ్డాయి.',
        translationStatus: 'translated',
      );
    }
    return const BnsLanguageSection(
      sectionNumber: 103,
      language: 'en',
      heading:
          'Punishment for murder and aggravated culpable homicide under Bharatiya Nyaya Sanhita, 2023',
      text:
          'Whoever commits murder shall be punished with death or imprisonment for life, and shall also be liable to fine. Detailed statutory provisions follow regarding exceptions and mitigations.',
      translationStatus: 'source',
    );
  }
}

void main() {
  group('Responsive Layout & Telugu Rendering Tests', () {
    late FakeResponsiveSectionRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeResponsiveSectionRepository();
    });

    Widget createTestApp(
      Widget child, {
      Size size = const Size(320, 600),
      double textScale = 1.0,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      );
    }

    testWidgets(
      'SectionDetailScreen renders at 320px narrow mobile width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            SectionDetailScreen(sectionNumber: 103, repository: fakeRepo),
            size: const Size(320, 640),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(SectionDetailScreen), findsOneWidget);
        expect(find.text('BNS § 103'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SectionDetailScreen renders Telugu content with 1.5x text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            SectionDetailScreen(
              sectionNumber: 103,
              repository: fakeRepo,
              initialLanguage: 'te',
            ),
            size: const Size(360, 700),
            textScale: 1.5,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('భారతీయ న్యాయ సంహిత'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'BrowseScreen renders at 320px narrow mobile width without pagination overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            BrowseScreen(repository: fakeRepo),
            size: const Size(320, 640),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BrowseScreen), findsOneWidget);
        expect(find.text('Browse BNS'), findsOneWidget);
        expect(find.text('Previous'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'BrowseScreen renders at 320px with 1.5x text scale without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            BrowseScreen(repository: fakeRepo),
            size: const Size(320, 640),
            textScale: 1.5,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BrowseScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'HomeScreen renders at 320px narrow mobile width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(const HomeScreen(), size: const Size(320, 640)),
        );

        await tester.pumpAndSettle();

        expect(find.text('LexIndia-AI'), findsOneWidget);
        expect(find.text('Find Legal Provision'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('SavedScreen renders at 320px width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(const SavedScreen(), size: const Size(320, 640)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Saved Sections'), findsOneWidget);
      expect(find.text('No Bookmarks Yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'AboutScreen and SettingsScreen render at 320px width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            SettingsScreen(themeController: ThemeController()),
            size: const Size(320, 640),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          createTestApp(const AboutScreen(), size: const Size(320, 640)),
        );

        await tester.pumpAndSettle();

        expect(find.text('About LexIndia-AI'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Wide desktop layout (1200px) renders without issues', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          SectionDetailScreen(sectionNumber: 103, repository: fakeRepo),
          size: const Size(1200, 800),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SectionDetailScreen), findsOneWidget);
      expect(find.text('BNS § 103'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
