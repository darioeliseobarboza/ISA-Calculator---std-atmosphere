import 'package:atmosphere_app/shared/models/altitude_unit.dart';

/// Request del cálculo (`POST /v1/calculate`, recorte FG-2).
///
/// El body es `{ geopotentialAltitude, altitudeUnit }`. **No** incluye
/// `tableStep` (solo aplica a la interpolación, FG-3 — API Context). El default
/// de `altitudeUnit` es `ft` (ADR-002). Identificadores JSON en inglés camelCase
/// (ADR-001).
class CalculationRequest {
  const CalculationRequest({
    required this.geopotentialAltitude,
    this.altitudeUnit = AltitudeUnit.feet,
  });

  /// Altitud geopotencial en la unidad de [altitudeUnit].
  final num geopotentialAltitude;

  /// Unidad de la altitud (`m`/`ft`), default `ft`.
  final AltitudeUnit altitudeUnit;

  /// Serializa a `{ "geopotentialAltitude": <num>, "altitudeUnit": "m"|"ft" }`.
  /// NO emite `tableStep` (recorte FG-2).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'geopotentialAltitude': geopotentialAltitude,
    'altitudeUnit': altitudeUnit.wire,
  };

  @override
  bool operator ==(Object other) =>
      other is CalculationRequest &&
      other.geopotentialAltitude == geopotentialAltitude &&
      other.altitudeUnit == altitudeUnit;

  @override
  int get hashCode => Object.hash(geopotentialAltitude, altitudeUnit);
}
