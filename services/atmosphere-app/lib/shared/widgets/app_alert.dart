import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Banner de alerta reusable (DS Gap: no hay component spec del surface, se
/// construye sobre los tokens de `theming`). Variant `error` por ahora.
///
/// Comunica el estado con icono + color + texto (no solo color — a11y). Usa
/// `aria-live` equivalente vía `Semantics(liveRegion: true)`.
class AppAlert extends StatelessWidget {
  const AppAlert({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          border: Border.all(color: AppColors.error),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(color: AppColors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
