/// Unidad de la altitud geopotencial de entrada (ADR-002).
///
/// El valor de wire es `m` / `ft` (no el índice del enum). El default del
/// contrato es [ft]. Se (de)serializa por su [wire] para no depender del orden
/// de declaración (modelos a mano — variante aceptada por `models-serialization`
/// para modelos chicos, consistente con los modelos de S-002).
enum AltitudeUnit {
  meters('m'),
  feet('ft');

  const AltitudeUnit(this.wire);

  /// Valor textual usado en el JSON (`m` o `ft`).
  final String wire;

  /// Parsea el valor de wire (`m`/`ft`) al enum. Lanza si es desconocido.
  static AltitudeUnit fromWire(String value) {
    return AltitudeUnit.values.firstWhere(
      (u) => u.wire == value,
      orElse: () => throw ArgumentError('unknown altitudeUnit: $value'),
    );
  }
}
