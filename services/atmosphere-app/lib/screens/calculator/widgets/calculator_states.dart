import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:atmosphere_app/shared/widgets/app_alert.dart';
import 'package:flutter/material.dart';

/// Empty-state inicial: guía al usuario a ingresar una altitud.
class CalculatorEmptyState extends StatelessWidget {
  const CalculatorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const Key('empty-state'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        children: [
          const Icon(
            Icons.calculate_outlined,
            color: AppColors.onSurfaceVariant,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.calcEmptyState,
              style: AppTypography.body.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loader de resultados con mensaje contextual ("Calculando parámetros…").
class CalculatorLoader extends StatelessWidget {
  const CalculatorLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const Key('results-loader'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(l10n.calcLoading, style: AppTypography.body),
        ],
      ),
    );
  }
}

/// Alerta de validación (400 outOfRange).
class ValidationAlert extends StatelessWidget {
  const ValidationAlert({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppAlert(
      key: const Key('validation-alert'),
      message: l10n.calcOutOfRange,
    );
  }
}

/// Alerta de sistema / sin conexión (conserva la entrada).
class SystemAlert extends StatelessWidget {
  const SystemAlert({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppAlert(
      key: const Key('system-alert'),
      message: l10n.calcConnectionError,
      icon: Icons.wifi_off,
    );
  }
}
