import 'package:atmosphere_app/shared/models/altitude_unit.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculationResponse.fromJson (TS-1)', () {
    test('parsea la respuesta 200 analítica FG-2 con campos exactos', () {
      final json = <String, dynamic>{
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
      };

      final response = CalculationResponse.fromJson(json);

      expect(response.input.geopotentialAltitude.meters, 5000.0);
      expect(response.input.geopotentialAltitude.feet, 16404);
      expect(response.input.altitudeUnit, AltitudeUnit.feet);

      final r = response.analytical;
      expect(r.method, 'analytical');
      expect(r.temperature.si, 255.65);
      expect(r.temperature.imperial, 460.17);
      expect(r.pressure.si, 54020);
      expect(r.pressure.imperial, 1128.1);
      expect(r.density.si, 0.73643);
      expect(r.density.imperial, 0.0014290);
      expect(r.dynamicViscosity.si, 1.6286e-5);
      expect(r.dynamicViscosity.imperial, 3.401e-7);
      expect(r.kinematicViscosity.si, 2.2117e-5);
      expect(r.kinematicViscosity.imperial, 2.381e-4);
      expect(r.speedOfSound.si, 320.55);
      expect(r.speedOfSound.imperial, 1051.7);
      expect(r.theta, 0.8872);
      expect(r.delta, 0.5331);
      expect(r.sigma, 0.6009);
      expect(r.speedOfSoundRatio, 0.9420);
      expect(r.viscosityRatio, 0.9098);
    });

    test('interpolation/comparison/table ausentes -> null, no falla', () {
      final json = <String, dynamic>{
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
      };

      final response = CalculationResponse.fromJson(json);

      expect(response.interpolation, isNull);
    });
  });

  group('CalculationRequest.toJson', () {
    test('TS-2: serializa sin la clave tableStep', () {
      final json = const CalculationRequest(
        geopotentialAltitude: 16404,
        altitudeUnit: AltitudeUnit.feet,
      ).toJson();

      expect(json, {'geopotentialAltitude': 16404, 'altitudeUnit': 'ft'});
      expect(json.containsKey('tableStep'), isFalse);
    });

    test('TS-3: default de altitudeUnit serializa como "ft"', () {
      final json = const CalculationRequest(
        geopotentialAltitude: 5000,
      ).toJson();

      expect(json['altitudeUnit'], 'ft');
    });

    test('altitudeUnit = meters serializa como "m"', () {
      final json = const CalculationRequest(
        geopotentialAltitude: 5000,
        altitudeUnit: AltitudeUnit.meters,
      ).toJson();

      expect(json['altitudeUnit'], 'm');
    });
  });

  group('AltitudeUnit', () {
    test('fromWire mapea m/ft sin depender del índice', () {
      expect(AltitudeUnit.fromWire('m'), AltitudeUnit.meters);
      expect(AltitudeUnit.fromWire('ft'), AltitudeUnit.feet);
    });

    test('fromWire lanza ante valor desconocido', () {
      expect(() => AltitudeUnit.fromWire('km'), throwsArgumentError);
    });
  });
}
