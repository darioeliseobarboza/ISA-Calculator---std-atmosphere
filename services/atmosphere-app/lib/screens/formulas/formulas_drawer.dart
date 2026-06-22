import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Overlay O-01 — "Fórmulas de conversión" (panel lateral / drawer).
///
/// Contenido **estático** (CA-2): no consume `POST /v1/calculate` ni ningún
/// provider de red, no depende de conectividad y no tiene estados de
/// loading/error/empty (solo el estado `default` del wireframe). Muestra, por
/// magnitud, la fórmula/factor de conversión (altitud m↔ft; T, P, ρ, μ, ν, a en
/// SI↔imperial) y deja constancia de que los relativos son adimensionales.
///
/// No es una ruta: se monta como panel lateral (overlay) sobre la pantalla de
/// cálculo (P-01) y se cierra invocando [onClose] (convención `navigation`).
class FormulasDrawer extends StatelessWidget {
  const FormulasDrawer({required this.onClose, super.key});

  /// Cierra el drawer. Se inyecta para no acoplar el widget a un mecanismo de
  /// cierre concreto (lo decide la pantalla que lo monta).
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final items = <String>[
      l10n.formulasItemAltitude,
      l10n.formulasItemTemperature,
      l10n.formulasItemPressure,
      l10n.formulasItemDensity,
      l10n.formulasItemDynamicViscosity,
      l10n.formulasItemKinematicViscosity,
      l10n.formulasItemSpeedOfSound,
    ];

    return Material(
      key: const Key('formulas-drawer'),
      color: AppColors.surface,
      elevation: 16,
      child: Semantics(
        container: true,
        label: l10n.formulasTitle,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // Header e Intro fijos arriba; la lista de fórmulas hace scroll en el
            // medio; el botón "Cerrar" queda fijo al pie y siempre visible (orden
            // de foco header → lista → Cerrar).
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1 · header-formulas
                Text(l10n.formulasTitle, style: AppTypography.title),
                const SizedBox(height: AppSpacing.sm),
                // 2 · Intro (caption)
                Text(
                  l10n.formulasIntro,
                  style: AppTypography.body.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // 3 · Lista fórmulas (label + items por magnitud) — scrollable.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.formulasListLabel, style: AppTypography.body),
                        const SizedBox(height: AppSpacing.sm),
                        Column(
                          key: const Key('formulas-list'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in items) ...[
                              Text(item, style: AppTypography.body),
                              if (item != items.last)
                                const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // 4 · Nota relativos (caption)
                        Text(
                          l10n.formulasRelativesNote,
                          style: AppTypography.body.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // 5 · Cerrar (secondary) — fijo al pie.
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('formulas-close-button'),
                    onPressed: onClose,
                    icon: Semantics(
                      label: l10n.formulasCloseA11y,
                      button: true,
                      child: const Icon(Icons.close),
                    ),
                    label: Text(l10n.formulasClose),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
