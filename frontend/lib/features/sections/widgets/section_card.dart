import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/bns_section.dart';

/// Clean, professional legal provision card used in listings and search results.
class SectionCard extends StatelessWidget {
  final BnsSectionSummary section;
  final VoidCallback onTap;

  const SectionCard({super.key, required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasTelugu = section.hasValidTelugu;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Section Number Badge & Translation Availability Tag
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
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
                      'BNS § ${section.sectionNumber}',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: hasTelugu
                          ? AppColors.statusSuccess.withValues(alpha: 0.12)
                          : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasTelugu ? Icons.translate : Icons.language_outlined,
                          size: 12,
                          color: hasTelugu
                              ? AppColors.statusSuccess
                              : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasTelugu ? 'Telugu' : 'English Only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: hasTelugu
                                ? AppColors.statusSuccess
                                : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // English Heading
              Text(
                section.headingEn.trim().isNotEmpty
                    ? section.headingEn.trim()
                    : 'Section ${section.sectionNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),

              // Telugu Heading (rendered only when actual Telugu content exists)
              if (hasTelugu && section.headingTe.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  section.headingTe.trim(),
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
