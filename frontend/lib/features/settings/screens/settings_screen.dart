import 'package:flutter/material.dart';
import '../../../core/language/language_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import 'about_screen.dart';

/// Screen providing user controls for Theme (System, Light, Dark),
/// default reading language (English, Telugu), and legal/provenance about information.
class SettingsScreen extends StatelessWidget {
  final ThemeController themeController;
  final LanguageController? languageController;

  const SettingsScreen({
    super.key,
    required this.themeController,
    this.languageController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listenables = <Listenable>[
      themeController,
      if (languageController != null) languageController!,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: Listenable.merge(listenables),
        builder: (context, _) {
          final currentThemeMode = themeController.themeMode;
          final currentLanguage =
              languageController?.defaultLanguage ?? LanguageController.english;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Appearance Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    'APPEARANCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.antiqueGold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        key: const Key('theme_radio_system'),
                        title: const Text('System Default'),
                        subtitle: const Text('Follow device system appearance'),
                        secondary: const Icon(Icons.brightness_auto),
                        value: ThemeMode.system,
                        groupValue: currentThemeMode,
                        activeColor: isDark
                            ? AppColors.antiqueGoldLight
                            : AppColors.legalNavy,
                        onChanged: (mode) {
                          if (mode != null) themeController.setThemeMode(mode);
                        },
                      ),
                      const Divider(),
                      RadioListTile<ThemeMode>(
                        key: const Key('theme_radio_light'),
                        title: const Text('Light Mode'),
                        subtitle: const Text('Ivory reading background'),
                        secondary: const Icon(Icons.light_mode_outlined),
                        value: ThemeMode.light,
                        groupValue: currentThemeMode,
                        activeColor: isDark
                            ? AppColors.antiqueGoldLight
                            : AppColors.legalNavy,
                        onChanged: (mode) {
                          if (mode != null) themeController.setThemeMode(mode);
                        },
                      ),
                      const Divider(),
                      RadioListTile<ThemeMode>(
                        key: const Key('theme_radio_dark'),
                        title: const Text('Dark Mode'),
                        subtitle: const Text(
                          'Deep navy background with high contrast',
                        ),
                        secondary: const Icon(Icons.dark_mode_outlined),
                        value: ThemeMode.dark,
                        groupValue: currentThemeMode,
                        activeColor: isDark
                            ? AppColors.antiqueGoldLight
                            : AppColors.legalNavy,
                        onChanged: (mode) {
                          if (mode != null) themeController.setThemeMode(mode);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Default Reading Language Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    'READING PREFERENCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.antiqueGold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        key: const Key('language_radio_en'),
                        title: const Text('English (Default)'),
                        subtitle: const Text(
                          'Primary statutory text as gazetted',
                        ),
                        secondary: const Icon(Icons.language),
                        value: LanguageController.english,
                        groupValue: currentLanguage,
                        activeColor: isDark
                            ? AppColors.antiqueGoldLight
                            : AppColors.legalNavy,
                        onChanged: (lang) {
                          if (lang != null) {
                            languageController?.setDefaultLanguage(lang);
                          }
                        },
                      ),
                      const Divider(),
                      RadioListTile<String>(
                        key: const Key('language_radio_te'),
                        title: const Text('తెలుగు (Telugu)'),
                        subtitle: const Text(
                          'Reference draft translations where available',
                        ),
                        secondary: const Icon(Icons.translate),
                        value: LanguageController.telugu,
                        groupValue: currentLanguage,
                        activeColor: isDark
                            ? AppColors.antiqueGoldLight
                            : AppColors.legalNavy,
                        onChanged: (lang) {
                          if (lang != null) {
                            languageController?.setDefaultLanguage(lang);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Legal & Provenance Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    'LEGAL & PROVENANCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.antiqueGold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        key: const Key('settings_about_tile'),
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About LexIndia-AI'),
                        subtitle: const Text(
                          'Version, source attribution & translation notices',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        key: const Key('settings_disclaimer_tile'),
                        leading: const Icon(Icons.policy_outlined),
                        title: const Text('Legal Information Disclaimer'),
                        subtitle: const Text('Informational reference only'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Legal Information Disclaimer'),
                              content: const SingleChildScrollView(
                                child: Text(
                                  'LexIndia-AI is an independent legal-information reference tool. It does NOT constitute legal advice or formal representation.\n\nTranslations provided are machine-assisted reference drafts and may not reflect authorized judicial Telugu text. Always consult the official Gazette of India or a qualified legal advocate for statutory decisions.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Understood'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      const ListTile(
                        leading: Icon(Icons.source_outlined),
                        title: Text('Source Material'),
                        subtitle: Text(
                          'India Code — Bharatiya Nyaya Sanhita, 2023',
                        ),
                      ),
                      const Divider(),
                      const ListTile(
                        leading: Icon(Icons.verified_outlined),
                        title: Text('Application Version'),
                        subtitle: Text('v0.1.0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
