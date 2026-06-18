import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Construye el [ThemeData] de la app a partir de los tokens. Se construye una
/// sola vez y se pasa a `MaterialApp.router` (convención `theming`).
abstract final class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppTypography.headline,
        titleMedium: AppTypography.title,
        bodyMedium: AppTypography.body,
      ),
    );
  }
}
