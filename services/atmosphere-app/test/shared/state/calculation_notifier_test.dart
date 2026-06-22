import 'package:atmosphere_app/shared/calculation/calculation_repository.dart';
import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:atmosphere_app/shared/models/altitude_unit.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:atmosphere_app/shared/state/calculation_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

void main() {
  setUpAll(() => registerFallbackValue(_FakeRequest()));

  late _MockRepository repository;
  late CalculationNotifier notifier;

  setUp(() {
    repository = _MockRepository();
    notifier = CalculationNotifier(repository);
  });

  test('estado inicial es empty', () {
    expect(notifier.state.status, CalculatorStatus.empty);
    expect(notifier.state.result, isNull);
  });

  test(
    'TS-4: happy path 200 -> success con result y request correcto',
    () async {
      when(
        () => repository.calculate(any()),
      ).thenAnswer((_) async => _response());

      final seen = <CalculatorStatus>[];
      notifier.addListener((s) => seen.add(s.status), fireImmediately: false);

      await notifier.calculate(
        geopotentialAltitude: 16404,
        altitudeUnit: AltitudeUnit.feet,
      );

      expect(seen, contains(CalculatorStatus.loading));
      expect(notifier.state.status, CalculatorStatus.success);
      expect(notifier.state.result, isNotNull);
      expect(notifier.state.error, isNull);

      final req =
          verify(() => repository.calculate(captureAny())).captured.single
              as CalculationRequest;
      expect(req.geopotentialAltitude, 16404);
      expect(req.altitudeUnit, AltitudeUnit.feet);
      expect(req.toJson(), {
        'geopotentialAltitude': 16404,
        'altitudeUnit': 'ft',
      });
    },
  );

  test('TS-5: 400 outOfRange -> validationError, sin result', () async {
    when(() => repository.calculate(any())).thenThrow(
      const ValidationException(
        'geopotentialAltitude out of range (0–36089 ft ≈ 0–11000 m)',
        {'code': 'outOfRange'},
      ),
    );

    await notifier.calculate(
      geopotentialAltitude: 40000,
      altitudeUnit: AltitudeUnit.feet,
    );

    expect(notifier.state.status, CalculatorStatus.validationError);
    expect(notifier.state.error, contains('out of range'));
    expect(notifier.state.errorCode, 'outOfRange');
    expect(notifier.state.result, isNull);
  });

  test('TS-5b: 400 invalidInput -> validationError con errorCode', () async {
    when(() => repository.calculate(any())).thenThrow(
      const ValidationException('invalid input', {'code': 'invalidInput'}),
    );

    await notifier.calculate(
      geopotentialAltitude: 0,
      altitudeUnit: AltitudeUnit.feet,
    );

    expect(notifier.state.status, CalculatorStatus.validationError);
    expect(notifier.state.errorCode, 'invalidInput');
    expect(notifier.state.result, isNull);
  });

  test('TS-6: NetworkException -> connectionError, input conservado', () async {
    when(() => repository.calculate(any())).thenThrow(const NetworkException());

    await notifier.calculate(
      geopotentialAltitude: 16404,
      altitudeUnit: AltitudeUnit.feet,
    );

    expect(notifier.state.status, CalculatorStatus.connectionError);
    expect(notifier.state.result, isNull);
    // El último input se conserva para reintentar.
    expect(notifier.state.lastAltitude, 16404);
    expect(notifier.state.lastUnit, AltitudeUnit.feet);
  });
}
