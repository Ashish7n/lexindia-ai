import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexindia_frontend/core/theme/app_theme.dart';
import 'package:lexindia_frontend/features/settings/screens/about_screen.dart';

void main() {
  group('AboutScreen Widget Tests', () {
    testWidgets(
      'renders application identity, version, and verified metadata',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
        await tester.pumpAndSettle();

        expect(find.text('About LexIndia-AI'), findsOneWidget);
        expect(find.text('LexIndia-AI'), findsOneWidget);
        expect(find.text('Version v0.1.0'), findsOneWidget);
        expect(find.text('Statutory Source Material'), findsOneWidget);
        expect(
          find.text('Bharatiya Nyaya Sanhita, 2023 (Act No. 45 of 2023)'),
          findsOneWidget,
        );
        expect(find.text('Notice on Telugu Translations'), findsOneWidget);
        expect(find.text('Legal Information Disclaimer'), findsOneWidget);
      },
    );

    testWidgets('back button pops the screen', (tester) async {
      bool popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                    popped = true;
                  },
                  child: const Text('Open About'),
                ),
              );
            },
          ),
        ),
      );

      // Open AboutScreen
      await tester.tap(find.text('Open About'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(const Key('about_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsNothing);
      expect(popped, isTrue);
    });

    testWidgets('renders correctly in Light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const AboutScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Notice on Telugu Translations'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in Dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const AboutScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Notice on Telugu Translations'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow viewport (320px) does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const AboutScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('LexIndia-AI'), findsOneWidget);
      expect(find.text('Legal Information Disclaimer'), findsOneWidget);
    });
  });
}
