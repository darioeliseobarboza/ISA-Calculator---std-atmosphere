import 'package:atmosphere_app/shared/format/number_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Valores ejemplo del wireframe `calculadora.md` (16.404 ft) — fuente de
  // verdad de la presentación.
  group('formatSigFigs (TS-13) — valores del wireframe', () {
    test('Temperatura SI 255,65 (decimal, separador ",")', () {
      expect(formatSigFigs(255.65), '255,65');
    });

    test('Temperatura imperial 460,17 (decimal)', () {
      expect(formatSigFigs(460.17), '460,17');
    });

    test('Presión SI 54020 -> 5,4020·10⁴ (científica)', () {
      expect(formatSigFigs(54020), '5,4020·10⁴');
    });

    test(
      'Presión imperial 1128,1 -> 1.128,1 (decimal, separador miles ".")',
      () {
        expect(formatSigFigs(1128.1), '1.128,1');
      },
    );

    test('Densidad SI 0,73643 (decimal)', () {
      expect(formatSigFigs(0.73643), '0,73643');
    });

    test('Densidad imperial 0,0014290 -> 1,4290·10⁻³ (científica)', () {
      expect(formatSigFigs(0.0014290), '1,4290·10⁻³');
    });

    test('Viscosidad dinámica SI 1.6286e-5 -> 1,6286·10⁻⁵', () {
      expect(formatSigFigs(1.6286e-5), '1,6286·10⁻⁵');
    });

    test('Viscosidad dinámica imperial 3.401e-7 -> científica con ⁻⁷', () {
      final s = formatSigFigs(3.401e-7);
      expect(s, contains('·10'));
      expect(s, endsWith('⁻⁷'));
      expect(s, startsWith('3,40'));
    });

    test('Viscosidad cinemática SI 2.2117e-5 -> 2,2117·10⁻⁵', () {
      expect(formatSigFigs(2.2117e-5), '2,2117·10⁻⁵');
    });

    test('Velocidad del sonido SI 320,55 (decimal)', () {
      expect(formatSigFigs(320.55), '320,55');
    });

    test('Velocidad del sonido imperial 1051,7 -> 1.051,7 (decimal)', () {
      expect(formatSigFigs(1051.7), '1.051,7');
    });
  });

  group('formatSigFigs — casos borde', () {
    test('cero -> "0", nunca científica', () {
      expect(formatSigFigs(0), '0');
      expect(formatSigFigs(0).contains('·10'), isFalse);
    });

    test('respeta 5 cifras significativas (mantissa con 4 decimales)', () {
      // 0.91015 (relativo μ/μ₀) decimal con 5 sig figs.
      expect(formatSigFigs(0.91015), '0,91015');
    });

    test('exponente positivo grande conserva 5 sig figs en mantissa', () {
      expect(formatSigFigs(54020000.0), '5,4020·10⁷');
    });
  });

  group('formatAltitude (eco {m, ft})', () {
    test('miles con "." y sin científica (wireframe 5.000 / 16.404)', () {
      expect(formatAltitude(5000.0), '5.000');
      expect(formatAltitude(16404), '16.404');
    });

    test('decimales de altitud con "," cuando aplica', () {
      expect(formatAltitude(5000.5), '5.000,5');
    });
  });
}
