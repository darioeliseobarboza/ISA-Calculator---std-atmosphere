import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:atmosphere_app/shared/calculation/calculation_repository_impl.dart';
import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:atmosphere_app/shared/models/altitude_unit.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

ApiClient _client(http.Client inner) => ApiClient(
  baseUrl: 'http://localhost:8080',
  inner: inner,
  timeout: const Duration(seconds: 15),
);

const _ok200Body = '''
{
  "input": { "geopotentialAltitude": {"m":5000.0,"ft":16404}, "altitudeUnit":"ft" },
  "results": {
    "analytical": {
      "method":"analytical",
      "temperature":{"si":255.65,"imperial":460.17},
      "pressure":{"si":54020,"imperial":1128.1},
      "density":{"si":0.73643,"imperial":0.0014290},
      "dynamicViscosity":{"si":1.6286e-5,"imperial":3.401e-7},
      "kinematicViscosity":{"si":2.2117e-5,"imperial":2.381e-4},
      "speedOfSound":{"si":320.55,"imperial":1051.7},
      "theta":0.8872, "delta":0.5331, "sigma":0.6009,
      "speedOfSoundRatio":0.9420, "viscosityRatio":0.9098
    }
  }
}
''';

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  group('ApiClient.postJson', () {
    test(
      '200 -> devuelve el dominio mapeado y postea el body correcto',
      () async {
        final inner = _MockHttpClient();
        when(
          () => inner.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response(_ok200Body, 200));

        final repo = CalculationRepositoryImpl(_client(inner));
        final result = await repo.calculate(
          const CalculationRequest(
            geopotentialAltitude: 16404,
            altitudeUnit: AltitudeUnit.feet,
          ),
        );

        expect(result.analytical.temperature.si, 255.65);
        expect(result.input.geopotentialAltitude.feet, 16404);

        final captured = verify(
          () => inner.post(
            captureAny(),
            headers: captureAny(named: 'headers'),
            body: captureAny(named: 'body'),
          ),
        ).captured;
        final uri = captured[0] as Uri;
        final headers = captured[1] as Map<String, String>;
        final body = jsonDecode(captured[2] as String) as Map<String, dynamic>;

        expect(uri.toString(), 'http://localhost:8080/v1/calculate');
        expect(headers['Content-Type'], 'application/json');
        expect(body, {'geopotentialAltitude': 16404, 'altitudeUnit': 'ft'});
      },
    );

    test('400 outOfRange -> ValidationException con mensaje y code', () async {
      final inner = _MockHttpClient();
      when(
        () => inner.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response.bytes(
          utf8.encode(
            '{"error":{"code":"outOfRange","message":"geopotentialAltitude out of range (0–36089 ft ≈ 0–11000 m)"}}',
          ),
          400,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final repo = CalculationRepositoryImpl(_client(inner));

      await expectLater(
        repo.calculate(const CalculationRequest(geopotentialAltitude: 40000)),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.message, 'message', contains('out of range'))
              .having((e) => e.fields['code'], 'code', 'outOfRange'),
        ),
      );
    });

    test('SocketException -> NetworkException', () async {
      final inner = _MockHttpClient();
      when(
        () => inner.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(const SocketException('no route'));

      final repo = CalculationRepositoryImpl(_client(inner));

      await expectLater(
        repo.calculate(const CalculationRequest(geopotentialAltitude: 16404)),
        throwsA(isA<NetworkException>()),
      );
    });

    test('TimeoutException -> NetworkException', () async {
      final inner = _MockHttpClient();
      when(
        () => inner.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(TimeoutException('timeout'));

      final repo = CalculationRepositoryImpl(_client(inner));

      await expectLater(
        repo.calculate(const CalculationRequest(geopotentialAltitude: 16404)),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
