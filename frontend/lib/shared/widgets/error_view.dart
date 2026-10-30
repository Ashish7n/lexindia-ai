import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable error presentation widget with optional retry action.
/// Displays clear user-facing messages without exposing raw exceptions or stack traces.
class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryButtonText;
  final IconData icon;

  const ErrorView({
    super.key,
    this.title = 'Unable to Load Provisions',
    required this.message,
    this.onRetry,
    this.retryButtonText = 'Retry',
    this.icon = Icons.cloud_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.statusError, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('error_view_retry_button'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryButtonText),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: isDark
                      ? AppColors.antiqueGoldLight
                      : AppColors.legalNavy,
                  foregroundColor: isDark
                      ? AppColors.darkBackground
                      : AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
