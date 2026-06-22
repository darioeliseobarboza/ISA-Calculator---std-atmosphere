import 'package:atmosphere_app/shared/models/altitude_unit.dart';

/// Magnitud absoluta en sus dos sistemas de unidades (ADR-002).
///
/// `{ "si": number, "imperial": number }`.
class MagnitudeValue {
  const MagnitudeValue({required this.si, required this.imperial});

  final num si;
  final num imperial;

  factory MagnitudeValue.fromJson(Map<String, dynamic> json) =>
      MagnitudeValue(si: json['si'] as num, imperial: json['imperial'] as num);

  @override
  bool operator ==(Object other) =>
      other is MagnitudeValue && other.si == si && other.imperial == imperial;

  @override
  int get hashCode => Object.hash(si, imperial);
}

/// Altitud eco-devuelta en ambas unidades (ADR-002): `{ "m": number, "ft": number }`.
class AltitudeValue {
  const AltitudeValue({required this.meters, required this.feet});

  final num meters;
  final num feet;

  factory AltitudeValue.fromJson(Map<String, dynamic> json) =>
      AltitudeValue(meters: json['m'] as num, feet: json['ft'] as num);

  @override
  bool operator ==(Object other) =>
      other is AltitudeValue && other.meters == meters && other.feet == feet;

  @override
  int get hashCode => Object.hash(meters, feet);
}

/// Resultado atmosférico de un método (`analytical` en FG-2).
///
/// Seis magnitudes absolutas (`{si, imperial}`) + cinco relativos adimensionales
/// (number único). Nombres de campo exactos del contrato (ADR-001/002).
class AtmosphericResult {
  const AtmosphericResult({
    required this.method,
    required this.temperature,
    required this.pressure,
    required this.density,
    required this.dynamicViscosity,
    required this.kinematicViscosity,
    required this.speedOfSound,
    required this.theta,
    required this.delta,
    required this.sigma,
    required this.speedOfSoundRatio,
    required this.viscosityRatio,
  });

  /// `analytical` | `interpolation` (en FG-2 siempre `analytical`).
  final String method;

  // Absolutas (SI / imperial).
  final MagnitudeValue temperature;
  final MagnitudeValue pressure;
  final MagnitudeValue density;
  final MagnitudeValue dynamicViscosity;
  final MagnitudeValue kinematicViscosity;
  final MagnitudeValue speedOfSound;

  // Relativos (adimensionales).
  final num theta;
  final num delta;
  final num sigma;
  final num speedOfSoundRatio;
  final num viscosityRatio;

  factory AtmosphericResult.fromJson(
    Map<String, dynamic> json,
  ) => AtmosphericResult(
    method: json['method'] as String,
    temperature: MagnitudeValue.fromJson(
      json['temperature'] as Map<String, dynamic>,
    ),
    pressure: MagnitudeValue.fromJson(json['pressure'] as Map<String, dynamic>),
    density: MagnitudeValue.fromJson(json['density'] as Map<String, dynamic>),
    dynamicViscosity: MagnitudeValue.fromJson(
      json['dynamicViscosity'] as Map<String, dynamic>,
    ),
    kinematicViscosity: MagnitudeValue.fromJson(
      json['kinematicViscosity'] as Map<String, dynamic>,
    ),
    speedOfSound: MagnitudeValue.fromJson(
      json['speedOfSound'] as Map<String, dynamic>,
    ),
    theta: json['theta'] as num,
    delta: json['delta'] as num,
    sigma: json['sigma'] as num,
    speedOfSoundRatio: json['speedOfSoundRatio'] as num,
    viscosityRatio: json['viscosityRatio'] as num,
  );
}

/// Eco de la entrada en la respuesta: `{ geopotentialAltitude: {m,ft}, altitudeUnit }`.
class CalculationInput {
  const CalculationInput({
    required this.geopotentialAltitude,
    required this.altitudeUnit,
  });

  final AltitudeValue geopotentialAltitude;
  final AltitudeUnit altitudeUnit;

  factory CalculationInput.fromJson(Map<String, dynamic> json) =>
      CalculationInput(
        geopotentialAltitude: AltitudeValue.fromJson(
          json['geopotentialAltitude'] as Map<String, dynamic>,
        ),
        altitudeUnit: AltitudeUnit.fromWire(json['altitudeUnit'] as String),
      );
}

/// Respuesta `200` del cálculo (recorte FG-2: `input` + `results.analytical`).
///
/// `results.interpolation`, `comparison` y `table` se omiten en FG-2 — quedan
/// `null` y el parseo NO debe fallar por su ausencia (contrato escalonado
/// aditivo; los campos llegan en FG-3 sin breaking change).
class CalculationResponse {
  const CalculationResponse({
    required this.input,
    required this.analytical,
    this.interpolation,
  });

  final CalculationInput input;

  /// Resultado analítico (`results.analytical`), siempre presente en FG-2.
  final AtmosphericResult analytical;

  /// Resultado de interpolación (`results.interpolation`) — `null` en FG-2.
  final AtmosphericResult? interpolation;

  factory CalculationResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    final interpolationJson = results['interpolation'];
    return CalculationResponse(
      input: CalculationInput.fromJson(json['input'] as Map<String, dynamic>),
      analytical: AtmosphericResult.fromJson(
        results['analytical'] as Map<String, dynamic>,
      ),
      interpolation: interpolationJson == null
          ? null
          : AtmosphericResult.fromJson(
              interpolationJson as Map<String, dynamic>,
            ),
    );
  }
}
