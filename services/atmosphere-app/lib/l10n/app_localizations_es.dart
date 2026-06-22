// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get calcTitle => 'Calculadora ISA · Atmósfera Estándar';

  @override
  String get calcAltitudeLabel => 'Altitud geopotencial';

  @override
  String get calcAltitudeHelper =>
      'numérico; se normaliza a ft y se valida 0–36.089 ft';

  @override
  String get calcUnitLabel => 'Unidad';

  @override
  String get calcUnitHelper => 'opciones m / ft · default ft';

  @override
  String get calcUnitMeters => 'm';

  @override
  String get calcUnitFeet => 'ft';

  @override
  String get calcTableStepDisabled => 'Paso de tabla — disponible en FG-3';

  @override
  String get calcTableStepA11y => 'Ajustar paso de tabla';

  @override
  String get calcCalculate => 'Calcular';

  @override
  String get calcCalculating => 'Calculando…';

  @override
  String get calcFormulas => 'Fórmulas de conversión';

  @override
  String get calcFormulasA11y => 'Abrir fórmulas de conversión';

  @override
  String get formulasTitle => 'Fórmulas de conversión';

  @override
  String get formulasIntro =>
      'Referencia estática · SI ↔ imperial y m ↔ ft. No calcula.';

  @override
  String get formulasListLabel => 'Por magnitud';

  @override
  String get formulasItemAltitude => 'Altitud — 1 ft = 0,3048 m';

  @override
  String get formulasItemTemperature => 'Temperatura — °R = K × 1,8';

  @override
  String get formulasItemPressure => 'Presión — 1 lbf/ft² (psf) = 47,8803 Pa';

  @override
  String get formulasItemDensity => 'Densidad — 1 slug/ft³ = 515,379 kg/m³';

  @override
  String get formulasItemDynamicViscosity =>
      'Viscosidad dinámica — 1 slug/(ft·s) = 47,8803 Pa·s';

  @override
  String get formulasItemKinematicViscosity =>
      'Viscosidad cinemática — 1 ft²/s = 0,092903 m²/s';

  @override
  String get formulasItemSpeedOfSound =>
      'Velocidad del sonido — 1 ft/s = 0,3048 m/s';

  @override
  String get formulasRelativesNote =>
      'Relativos (θ, δ, σ, a/a₀, μ/μ₀): adimensionales, sin conversión.';

  @override
  String get formulasClose => 'Cerrar';

  @override
  String get formulasCloseA11y => 'Cerrar fórmulas';

  @override
  String get calcLoading => 'Calculando parámetros…';

  @override
  String get calcEmptyState =>
      'Ingresá una altitud y calculá para ver los parámetros ISA.';

  @override
  String get calcOutOfRange =>
      'Altitud fuera de rango: el modelo cubre 0–36.089 ft (≈ 0–11.000 m). Corregí el valor.';

  @override
  String get calcInvalidInput =>
      'La entrada no es válida. Revisá el valor ingresado.';

  @override
  String get calcConnectionError =>
      'No se pudo conectar con la API. Tu entrada se conservó — reintentá.';

  @override
  String get calcNotANumber => 'Ingresá un número';

  @override
  String get calcFieldOutOfRange => 'Fuera de rango (0–36.089 ft)';

  @override
  String get calcFieldInvalidInput => 'Valor no válido';

  @override
  String get calcResultsTitle => 'Resultados por magnitud (SI / imperial)';

  @override
  String get calcResultsAnnotation =>
      'FG-2: solo Analítico. FG-3 agrega columnas Interpolación · Δ · error %';

  @override
  String get calcMagTemperature => 'Temperatura (T)';

  @override
  String get calcMagPressure => 'Presión (P)';

  @override
  String get calcMagDensity => 'Densidad (ρ)';

  @override
  String get calcMagDynamicViscosity => 'Viscosidad dinámica (μ)';

  @override
  String get calcMagKinematicViscosity => 'Viscosidad cinemática (ν)';

  @override
  String get calcMagSpeedOfSound => 'Velocidad del sonido (a)';

  @override
  String get calcRelativesTitle => 'Relativos (adimensionales)';

  @override
  String calcRelatives(
    String theta,
    String delta,
    String sigma,
    String aRatio,
    String muRatio,
  ) {
    return 'θ=$theta · δ=$delta · σ=$sigma · a/a₀=$aRatio · μ/μ₀=$muRatio';
  }

  @override
  String calcAltitudeEcho(String meters, String feet) {
    return 'Altitud: $meters m · $feet ft';
  }

  @override
  String get calcFooter =>
      'El cálculo lo hace la API · valores en SI e imperial · 5 cifras significativas';

  @override
  String get calcResultsTableA11y => 'Tabla de resultados por magnitud';
}
