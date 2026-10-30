import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Language selection control allowing users to switch between English ('en') and Telugu ('te').
class LanguageSelector extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;
  final bool isLoading;

  const LanguageSelector({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _buildOption(
            context: context,
            label: 'English',
            code: 'en',
            isSelected: currentLanguage == 'en',
            isDark: isDark,
          ),
          _buildOption(
            context: context,
            label: 'తెలుగు (Telugu)',
            code: 'te',
            isSelected: currentLanguage == 'te',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required String code,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: isLoading ? null : () => onLanguageChanged(code),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.antiqueGoldLight : AppColors.legalNavy)
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
