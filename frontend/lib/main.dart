import 'package:flutter/material.dart';
import 'app.dart';
import 'core/language/language_controller.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  final languageController = LanguageController();

  await Future.wait([
    themeController.initialize(),
    languageController.initialize(),
  ]);

  runApp(
    LexIndiaApp(
      themeController: themeController,
      languageController: languageController,
    ),
  );
}
