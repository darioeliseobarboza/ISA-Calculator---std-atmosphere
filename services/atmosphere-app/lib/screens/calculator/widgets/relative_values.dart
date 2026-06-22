import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/shared/format/number_format.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Sección de relativos adimensionales (θ, δ, σ, a/a₀, μ/μ₀).
class RelativeValues extends StatelessWidget {
  const RelativeValues({super.key, required this.result});

  final AtmosphericResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final line = l10n.calcRelatives(
      formatSigFigs(result.theta),
      formatSigFigs(result.delta),
      formatSigFigs(result.sigma),
      formatSigFigs(result.speedOfSoundRatio),
      formatSigFigs(result.viscosityRatio),
    );
    return Column(
      key: const Key('relative-values'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.calcRelativesTitle, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(line, style: AppTypography.body),
      ],
    );
  }
}
