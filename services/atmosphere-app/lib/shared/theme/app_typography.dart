import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Estilos de texto de la app. Los widgets consumen estos tokens en lugar de
/// construir `TextStyle` inline (convención `theming`).
abstract final class AppTypography {
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );
}
