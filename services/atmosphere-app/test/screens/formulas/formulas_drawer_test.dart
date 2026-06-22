import 'package:atmosphere_app/screens/calculator/calculator_screen.dart';
import 'package:atmosphere_app/shared/calculation/calculation_repository.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/providers/calculation_provider.dart';
import 'package:atmosphere_app/shared/state/calculation_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements CalculationRepository {}

class _FakeRequest extends Fake implements CalculationRequest {}

Override _fakeState(CalculatorState state) =>
    calculationProvider.overrideWith((ref) => FakeCalculationNotifier(state));

/// Abre el drawer O-01 desde P-01 (tap en `formulas-button`).
Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('formulas-button')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeRequest()));

  testWidgets('TS-1: el drawer renderiza el header y la intro estáticos', (
    tester,
  ) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        calculationRepositoryProvider.overrideWithValue(_MockRepository()),
      ],
    );
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    // Header del drawer (también es el label del botón en P-01 → findsWidgets).
    expect(find.text('Fórmulas de conversión'), findsWidgets);
    expect(
      find.text('Referencia estática · SI ↔ imperial y m ↔ ft. No calcula.'),
      findsOneWidget,
    );
  });

  testWidgets('TS-2: la lista muestra las 7 magnitudes con su fórmula/factor', (
    tester,
  ) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        calculationRepositoryProvider.overrideWithValue(_MockRepository()),
      ],
    );
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    expect(find.text('Altitud — 1 ft = 0,3048 m'), findsOneWidget);
    expect(find.text('Temperatura — °R = K × 1,8'), findsOneWidget);
    expect(find.text('Presión — 1 lbf/ft² (psf) = 47,8803 Pa'), findsOneWidget);
    expect(find.text('Densidad — 1 slug/ft³ = 515,379 kg/m³'), findsOneWidget);
    expect(
      find.text('Viscosidad dinámica — 1 slug/(ft·s) = 47,8803 Pa·s'),
      findsOneWidget,
    );
    expect(
      find.text('Viscosidad cinemática — 1 ft²/s = 0,092903 m²/s'),
      findsOneWidget,
    );
    expect(
      find.text('Velocidad del sonido — 1 ft/s = 0,3048 m/s'),
      findsOneWidget,
    );
  });

  testWidgets('TS-3: los relativos figuran como adimensionales (nota)', (
    tester,
  ) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        calculationRepositoryProvider.overrideWithValue(_MockRepository()),
      ],
    );
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    expect(
      find.text(
        'Relativos (θ, δ, σ, a/a₀, μ/μ₀): adimensionales, sin conversión.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('TS-4: btn-fórmulas abre el drawer O-01', (tester) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        calculationRepositoryProvider.overrideWithValue(_MockRepository()),
      ],
    );
    await tester.pumpAndSettle();

    // Antes del tap el drawer no está montado.
    expect(find.byKey(const Key('formulas-drawer')), findsNothing);

    await _openDrawer(tester);

    expect(find.byKey(const Key('formulas-drawer')), findsOneWidget);
  });

  testWidgets('TS-5: "Cerrar" cierra el drawer y vuelve a P-01', (
    tester,
  ) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        calculationRepositoryProvider.overrideWithValue(_MockRepository()),
      ],
    );
    await tester.pumpAndSettle();
    await _openDrawer(tester);
    expect(find.byKey(const Key('formulas-drawer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('formulas-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('formulas-drawer')), findsNothing);
    // P-01 sigue montada.
    expect(find.byKey(const Key('formulas-button')), findsOneWidget);
  });

  testWidgets('TS-6: abrir el drawer NO dispara ninguna llamada de cálculo', (
    tester,
  ) async {
    final repo = _MockRepository();

    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [calculationRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    verifyNever(() => repo.calculate(any()));
    // Sin loader de resultados dentro del drawer.
    expect(
      find.descendant(
        of: find.byKey(const Key('formulas-drawer')),
        matching: find.byKey(const Key('results-loader')),
      ),
      findsNothing,
    );
  });

  testWidgets('TS-7: UI íntegramente en español (sin claves crudas)', (
    tester,
  ) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        calculationRepositoryProvider.overrideWithValue(_MockRepository()),
      ],
    );
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    // Textos en español resueltos desde el ARB.
    expect(find.text('Por magnitud'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    // Ausencia de claves crudas (no resueltas).
    expect(find.textContaining('formulas.'), findsNothing);
    expect(find.textContaining('formulasTitle'), findsNothing);
    // Sin loader dentro del drawer.
    expect(
      find.descendant(
        of: find.byKey(const Key('formulas-drawer')),
        matching: find.byKey(const Key('results-loader')),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'TS-8: el drawer se abre sobre el estado de error de P-01 y lo conserva',
    (tester) async {
      await tester.pumpApp(
        const CalculatorScreen(),
        overrides: [
          _fakeState(
            const CalculatorState(
              status: CalculatorStatus.connectionError,
              error: 'sin conexión',
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // P-01 está en estado de error de sistema.
      expect(find.byKey(const Key('system-alert')), findsOneWidget);

      await _openDrawer(tester);
      // Mientras está abierto, el contenido de fórmulas es visible.
      expect(find.byKey(const Key('formulas-drawer')), findsOneWidget);
      expect(
        find.text('Referencia estática · SI ↔ imperial y m ↔ ft. No calcula.'),
        findsOneWidget,
      );

      // Al cerrar, P-01 conserva su estado de error.
      await tester.tap(find.byKey(const Key('formulas-close-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('formulas-drawer')), findsNothing);
      expect(find.byKey(const Key('system-alert')), findsOneWidget);
    },
  );
}
