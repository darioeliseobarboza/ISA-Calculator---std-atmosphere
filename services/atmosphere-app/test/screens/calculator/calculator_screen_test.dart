import 'package:atmosphere_app/screens/calculator/calculator_screen.dart';
import 'package:atmosphere_app/shared/calculation/calculation_repository.dart';
import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
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

CalculationResponse _response() => CalculationResponse.fromJson({
  'input': {
    'geopotentialAltitude': {'m': 5000.0, 'ft': 16404},
    'altitudeUnit': 'ft',
  },
  'results': {
    'analytical': {
      'method': 'analytical',
      'temperature': {'si': 255.65, 'imperial': 460.17},
      'pressure': {'si': 54020, 'imperial': 1128.1},
      'density': {'si': 0.73643, 'imperial': 0.0014290},
      'dynamicViscosity': {'si': 1.6286e-5, 'imperial': 3.401e-7},
      'kinematicViscosity': {'si': 2.2117e-5, 'imperial': 2.381e-4},
      'speedOfSound': {'si': 320.55, 'imperial': 1051.7},
      'theta': 0.8872,
      'delta': 0.5331,
      'sigma': 0.6009,
      'speedOfSoundRatio': 0.9420,
      'viscosityRatio': 0.9098,
    },
  },
});

Override _fakeState(CalculatorState state) =>
    calculationProvider.overrideWith((ref) => FakeCalculationNotifier(state));

void main() {
  setUpAll(() => registerFallbackValue(_FakeRequest()));

  testWidgets('TS-7: estado inicial vacío', (tester) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        calculationRepositoryProvider.overrideWithValue(_MockRepository()),
      ],
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Ingresá una altitud y calculá para ver los parámetros ISA.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('results-table')), findsNothing);
    expect(find.byKey(const Key('altitude-echo')), findsNothing);
    // Botón calcular habilitado.
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('calculate-button')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('TS-8: formato no numérico bloquea el envío (verifyNever)', (
    tester,
  ) async {
    final repo = _MockRepository();

    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [calculationRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('altitude-field')), 'abc');
    await tester.tap(find.byKey(const Key('calculate-button')));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá un número'), findsOneWidget);
    verifyNever(() => repo.calculate(any()));
    expect(find.byKey(const Key('results-loader')), findsNothing);
  });

  testWidgets('TS-9: render doble unidad + altitud eco + español', (
    tester,
  ) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        _fakeState(
          CalculatorState(
            status: CalculatorStatus.success,
            result: _response(),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    // Tabla con magnitudes y doble unidad.
    expect(find.byKey(const Key('results-table')), findsOneWidget);
    expect(find.textContaining('255,65 K'), findsOneWidget);
    expect(find.textContaining('460,17 °R'), findsOneWidget);
    expect(find.text('Temperatura (T)'), findsOneWidget);
    // Relativos.
    expect(find.byKey(const Key('relative-values')), findsOneWidget);
    expect(find.textContaining('θ=0,88720'), findsOneWidget);
    // Altitud eco.
    expect(find.text('Altitud: 5.000 m · 16.404 ft'), findsOneWidget);
  });

  testWidgets('TS-10: estado de carga', (tester) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        _fakeState(const CalculatorState(status: CalculatorStatus.loading)),
      ],
    );
    await tester.pump();

    expect(find.byKey(const Key('results-loader')), findsOneWidget);
    expect(find.text('Calculando parámetros…'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('calculate-button')),
    );
    expect(button.onPressed, isNull); // deshabilitado
    expect(find.text('Calculando…'), findsOneWidget);
    expect(find.byKey(const Key('results-table')), findsNothing);
  });

  testWidgets('TS-11: estado error de validación', (tester) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        _fakeState(
          const CalculatorState(
            status: CalculatorStatus.validationError,
            errorCode: 'outOfRange',
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('validation-alert')), findsOneWidget);
    expect(find.textContaining('Altitud fuera de rango'), findsOneWidget);
    expect(find.byKey(const Key('results-table')), findsNothing);
  });

  testWidgets('TS-12: error de conexión muestra alerta y conserva la entrada', (
    tester,
  ) async {
    final repo = _MockRepository();
    when(() => repo.calculate(any())).thenThrow(const NetworkException());

    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [calculationRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('altitude-field')), '16404');
    await tester.tap(find.byKey(const Key('calculate-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('system-alert')), findsOneWidget);
    expect(
      find.textContaining('No se pudo conectar con la API'),
      findsOneWidget,
    );
    // El campo conserva lo ingresado para reintentar.
    expect(find.text('16404'), findsOneWidget);
    expect(find.byKey(const Key('results-table')), findsNothing);
  });

  testWidgets('TS-14: el selector de unidad cambia el request', (tester) async {
    final repo = _MockRepository();
    when(() => repo.calculate(any())).thenAnswer((_) async => _response());

    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [calculationRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    // Cambiar el selector a "m".
    await tester.tap(find.byKey(const Key('unit-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('m').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('altitude-field')), '5000');
    await tester.tap(find.byKey(const Key('calculate-button')));
    await tester.pumpAndSettle();

    final req =
        verify(() => repo.calculate(captureAny())).captured.single
            as CalculationRequest;
    expect(req.toJson(), {'geopotentialAltitude': 5000, 'altitudeUnit': 'm'});
  });

  testWidgets('TS-15: control de paso de tabla deshabilitado', (tester) async {
    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [
        calculationRepositoryProvider.overrideWithValue(_MockRepository()),
      ],
    );
    await tester.pumpAndSettle();

    final control = tester.widget<OutlinedButton>(
      find.byKey(const Key('table-step-control')),
    );
    expect(control.onPressed, isNull); // deshabilitado
  });

  testWidgets('TS-17: Enter en el campo dispara el cálculo', (tester) async {
    final repo = _MockRepository();
    when(() => repo.calculate(any())).thenAnswer((_) async => _response());

    await tester.pumpApp(
      const CalculatorScreen(),
      overrides: [calculationRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('altitude-field')), '16404');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final req =
        verify(() => repo.calculate(captureAny())).captured.single
            as CalculationRequest;
    expect(req.toJson(), {'geopotentialAltitude': 16404, 'altitudeUnit': 'ft'});
  });
}
