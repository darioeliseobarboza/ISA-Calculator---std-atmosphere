import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/shared/format/number_format.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:atmosphere_app/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Badge con la altitud de entrada eco-devuelta en `{m, ft}` (ADR-002).
class AltitudeEcho extends StatelessWidget {
  const AltitudeEcho({super.key, required this.altitude});

  final AltitudeValue altitude;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n.calcAltitudeEcho(
      formatAltitude(altitude.meters),
      formatAltitude(altitude.feet),
    );
    return Container(
      key: const Key('altitude-echo'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Text(text, style: AppTypography.body),
    );
  }
}
