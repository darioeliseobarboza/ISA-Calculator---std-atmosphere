import 'package:atmosphere_app/l10n/app_localizations.dart';
import 'package:atmosphere_app/shared/models/altitude_unit.dart';
import 'package:atmosphere_app/shared/theme/app_colors.dart';
import 'package:atmosphere_app/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Campo de altitud + selector de unidad (m/ft). La validación de **formato
/// numérico** es client-side (bloquea el envío); el **rango** lo valida la API.
class AltitudeInput extends StatelessWidget {
  const AltitudeInput({
    super.key,
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    required this.onSubmitted,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final AltitudeUnit unit;
  final ValueChanged<AltitudeUnit> onUnitChanged;
  final VoidCallback onSubmitted;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            key: const Key('altitude-field'),
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              labelText: l10n.calcAltitudeLabel,
              helperText: l10n.calcAltitudeHelper,
              helperMaxLines: 2,
              errorText: errorText,
              errorMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<AltitudeUnit>(
            key: const Key('unit-dropdown'),
            initialValue: unit,
            decoration: InputDecoration(
              labelText: l10n.calcUnitLabel,
              helperText: l10n.calcUnitHelper,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: AltitudeUnit.meters,
                child: Text(l10n.calcUnitMeters),
              ),
              DropdownMenuItem(
                value: AltitudeUnit.feet,
                child: Text(l10n.calcUnitFeet),
              ),
            ],
            onChanged: enabled
                ? (value) {
                    if (value != null) onUnitChanged(value);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

/// Botón de paso de tabla — **deshabilitado** en FG-2 (el paso solo aplica a la
/// interpolación, FG-3). Presente para no cambiar el layout entre FG-2 y FG-3.
class TableStepControl extends StatelessWidget {
  const TableStepControl({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      key: const Key('table-step-control'),
      onPressed: null, // deshabilitado (recorte FG-2)
      icon: Semantics(
        label: l10n.calcTableStepA11y,
        child: const Icon(Icons.settings),
      ),
      label: Text(
        l10n.calcTableStepDisabled,
        style: const TextStyle(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
