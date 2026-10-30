import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Screen displaying application metadata, statutory source attribution,
/// Telugu translation limitation notices, and legal disclaimers.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appName = 'LexIndia-AI';
  static const String appVersion = 'v0.1.0';
  static const String statuteName =
      'Bharatiya Nyaya Sanhita, 2023 (Act No. 45 of 2023)';
  static const String sourceAttribution =
      'Parliament of India, Gazette of India Extraordinary, Ministry of Law and Justice, Legislative Department. India Code (indiacode.nic.in).';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About LexIndia-AI'),
        leading: IconButton(
          key: const Key('about_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Settings',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Identity & Version Card
            _buildIdentityCard(theme, isDark),
            const SizedBox(height: 16),

            // 2. Statutory Source Attribution Card
            _buildSourceCard(theme, isDark),
            const SizedBox(height: 16),

            // 3. Translation Notice & Limitation Card
            _buildTranslationNoticeCard(theme, isDark),
            const SizedBox(height: 16),

            // 4. Legal Information Disclaimer Card
            _buildDisclaimerCard(theme, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.gavel,
                    color: isDark
                        ? AppColors.antiqueGoldLight
                        : AppColors.legalNavy,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.antiqueGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.antiqueGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Version $appVersion',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.antiqueGoldLight
                                : AppColors.legalNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'A bilingual legal reference application designed for law students, competitive-examination aspirants, and members of the public to browse and read Bharatiya Nyaya Sanhita (BNS) provisions in English and Telugu.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.source_outlined,
                  color: isDark
                      ? AppColors.antiqueGoldLight
                      : AppColors.legalNavy,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Statutory Source Material',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              statuteName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enacted by the Parliament of India and published in the Gazette of India Extraordinary, Ministry of Law and Justice, Legislative Department. Statutory text indexed from the India Code legislative repository (indiacode.nic.in).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Complete database includes all 358 statutory sections across Chapters I through XX.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationNoticeCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.translate,
                  color: isDark
                      ? AppColors.antiqueGoldLight
                      : AppColors.legalNavy,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Notice on Telugu Translations',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Telugu translations in LexIndia-AI are draft reference texts intended to aid reading comprehension and accessibility. They have NOT been officially certified or gazetted as authorized judicial translations by the Government of India or the Official Languages Wing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5)
                    : AppColors.lightSurfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.antiqueGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Do not cite or rely upon draft Telugu translations as authoritative in any judicial or administrative proceeding. Where a translation is missing or unverified, the authentic English statutory text is displayed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.policy_outlined,
                  color: isDark
                      ? AppColors.antiqueGoldLight
                      : AppColors.legalNavy,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Legal Information Disclaimer',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'LexIndia-AI is an independent informational reference tool developed solely for educational lookup and study. It does NOT constitute legal advice, advocate representation, or statutory counsel.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No attorney-client relationship is formed through the use of this application. Always consult the official Gazette of India or a qualified legal practitioner for statutory decisions or legal counsel.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
