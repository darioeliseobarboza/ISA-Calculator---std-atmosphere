import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/shared/format/number_format.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Tabla de las 6 magnitudes absolutas en SI e imperial (doble unidad, NFR-U03).
///
/// Cada fila se anuncia como magnitud + valor SI + valor imperial (a11y). Los
/// valores se formatean con [formatSigFigs] (5 cifras significativas; científica
/// para μ/ν/P/ρ — ADR-005). Los símbolos de unidad son datos (no traducibles).
class ResultsTable extends StatelessWidget {
  const ResultsTable({super.key, required this.result});

  final AtmosphericResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final rows = <_MagnitudeRow>[
      _MagnitudeRow(l10n.calcMagTemperature, result.temperature, 'K', '°R'),
      _MagnitudeRow(l10n.calcMagPressure, result.pressure, 'Pa', 'lbf/ft²'),
      _MagnitudeRow(l10n.calcMagDensity, result.density, 'kg/m³', 'slug/ft³'),
      _MagnitudeRow(
        l10n.calcMagDynamicViscosity,
        result.dynamicViscosity,
        'Pa·s',
        'slug/(ft·s)',
      ),
      _MagnitudeRow(
        l10n.calcMagKinematicViscosity,
        result.kinematicViscosity,
        'm²/s',
        'ft²/s',
      ),
      _MagnitudeRow(
        l10n.calcMagSpeedOfSound,
        result.speedOfSound,
        'm/s',
        'ft/s',
      ),
    ];

    return Column(
      key: const Key('results-table'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.calcResultsTitle, style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: l10n.calcResultsTableA11y,
          container: true,
          child: Column(
            children: rows.map((r) => r.build(context)).toList(growable: false),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.calcResultsAnnotation,
          style: AppTypography.body.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MagnitudeRow {
  const _MagnitudeRow(this.label, this.value, this.siUnit, this.imperialUnit);

  final String label;
  final MagnitudeValue value;
  final String siUnit;
  final String imperialUnit;

  Widget build(BuildContext context) {
    final si = '${formatSigFigs(value.si)} $siUnit';
    final imperial = '${formatSigFigs(value.imperial)} $imperialUnit';
    return Semantics(
      label: '$label: $si · $imperial',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: Text(label, style: AppTypography.body)),
              Expanded(
                flex: 3,
                child: Text(
                  si,
                  style: AppTypography.body,
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: Text(
                  imperial,
                  style: AppTypography.body,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
