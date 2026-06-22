import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Umbrales para decidir notación científica (ADR-005 / NFR-U02). Calibrados
/// contra los valores ejemplo del wireframe `calculadora.md` (fuente de verdad
/// de la UI): P SI `54020` → `5,4020·10⁴`; ρ imperial `0,0014290` →
/// `1,4290·10⁻³`; μ/ν → científica; mientras que T (`255,65`), a (`320,55`,
/// `1.051,7`) y P imperial (`1.128,1`) quedan en decimal.
const double _sciLow = 1e-2;
const double _sciHigh = 1e4;

/// Cantidad de cifras significativas de presentación (ADR-005).
const int _defaultSigFigs = 5;

/// Formatea [value] con [sig] cifras significativas para presentación, locale
/// `es` (separador decimal `,`).
///
/// Reglas (ADR-005 — redondeo SOLO de presentación; el frontend no calcula):
/// - `value == 0` → `"0"` (nunca notación científica).
/// - `abs(value) < 1e-2` o `abs(value) >= 1e4` → notación científica
///   `m·10ⁿ` (mantissa con separador decimal `,`, exponente en superíndice),
///   p. ej. `5,4020·10⁴`, `1,6286·10⁻⁵`. Umbrales calibrados contra los valores
///   ejemplo del wireframe (ver [_sciLow]/[_sciHigh]).
/// - resto → decimal con `sig` cifras significativas y separador `,`,
///   p. ej. `255,65`, `0,73643`.
String formatSigFigs(num value, {int sig = _defaultSigFigs}) {
  final v = value.toDouble();
  if (v == 0) return '0';

  final abs = v.abs();
  if (abs < _sciLow || abs >= _sciHigh) {
    return _scientific(v, sig);
  }
  return _decimal(v, sig);
}

/// Formatea una altitud para el eco `{m, ft}` (locale `es`): separador de miles
/// `.`, decimal `,`, sin notación científica (el wireframe muestra `5.000 m ·
/// 16.404 ft`). Distinto de [formatSigFigs], que es para las magnitudes ISA.
String formatAltitude(num value) {
  final pattern = NumberFormat.decimalPattern('es')
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 2;
  return pattern.format(value);
}

/// Decimal con exactamente [sig] cifras significativas y separador decimal `es`.
///
/// Fija `min == max` fracción para mostrar las [sig] cifras aun cuando terminen
/// en cero (p. ej. `0,8872` → `0,88720`), cumpliendo ADR-005 y el formato de la
/// línea de relativos del wireframe.
String _decimal(double v, int sig) {
  final exponent = _exponent(v);
  // Decimales necesarios para [sig] cifras significativas dado el orden de magnitud.
  final fractionDigits = (sig - 1 - exponent).clamp(0, 20).toInt();
  final pattern = NumberFormat.decimalPattern('es')
    ..minimumFractionDigits = fractionDigits
    ..maximumFractionDigits = fractionDigits;
  return pattern.format(v);
}

/// Notación científica `m·10ⁿ` con la mantissa a [sig] cifras significativas.
String _scientific(double v, int sig) {
  final exponent = _exponent(v);
  final mantissa = v / math.pow(10, exponent);
  // La mantissa siempre tiene 1 dígito entero -> sig-1 decimales.
  final mantissaFmt = NumberFormat.decimalPattern('es')
    ..minimumFractionDigits = sig - 1
    ..maximumFractionDigits = sig - 1;
  return '${mantissaFmt.format(mantissa)}·10${_superscript(exponent)}';
}

/// Exponente decimal (orden de magnitud) de [v] (`v != 0`), robusto a la
/// imprecisión de `log10` en bordes como `1000` o `0.001`.
int _exponent(double v) {
  final abs = v.abs();
  var e = (math.log(abs) / math.ln10).floor();
  if (math.pow(10, e + 1) <= abs * (1 + 1e-12)) e += 1;
  if (abs < math.pow(10, e) * (1 - 1e-12)) e -= 1;
  return e;
}

/// Convierte un entero a superíndice Unicode (incluye el signo `⁻`).
String _superscript(int n) {
  const map = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '-': '⁻',
  };
  return n.toString().split('').map((c) => map[c] ?? c).join();
}
