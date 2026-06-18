import 'dart:io';

import 'package:atmosphere_app/shared/config/env.dart';
import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:atmosphere_app/shared/services/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost/'));
  });

  late _MockHttpClient httpClient;
  late ApiClient apiClient;

  setUp(() {
    httpClient = _MockHttpClient();
    apiClient = ApiClient(
      baseUrl: 'http://localhost:8080',
      inner: httpClient,
      timeout: const Duration(seconds: 15),
    );
  });

  group('ApiClient.getJson', () {
    test('TS-3: éxito 200 devuelve el body decodificado', () async {
      when(() => httpClient.get(any())).thenAnswer(
        (_) async => http.Response(
          '{"status":"ok","timestamp":"2026-06-12T16:00:00Z"}',
          200,
        ),
      );

      final result = await apiClient.getJson('/health');

      expect(result, {'status': 'ok', 'timestamp': '2026-06-12T16:00:00Z'});
      verify(
        () => httpClient.get(Uri.parse('http://localhost:8080/health')),
      ).called(1);
    });

    test(
      'TS-4: status >= 400 lanza AppException (UnexpectedException)',
      () async {
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response('{}', 503));

        await expectLater(
          () => apiClient.getJson('/health'),
          throwsA(isA<UnexpectedException>()),
        );
      },
    );

    test('TS-5: SocketException se traduce a NetworkException', () async {
      when(
        () => httpClient.get(any()),
      ).thenThrow(const SocketException('no route to host'));

      await expectLater(
        () => apiClient.getJson('/health'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('TS-5: TimeoutException se traduce a NetworkException', () async {
      when(() => httpClient.get(any())).thenAnswer(
        (_) => Future<http.Response>.delayed(
          const Duration(milliseconds: 50),
          () => http.Response('{}', 200),
        ),
      );
      // Cliente con timeout muy corto para forzar el timeout.
      final fastTimeout = ApiClient(
        baseUrl: 'http://localhost:8080',
        inner: httpClient,
        timeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        () => fastTimeout.getJson('/health'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('apiClientProvider (cross-origin / base URL desde env)', () {
    test(
      'TS-14: la URL es \${env.apiBaseUrl}/health (no hardcodeada)',
      () async {
        // Env con un origen DISTINTO al de la app (caso cross-origin web).
        final container = ProviderContainer(
          overrides: [
            envProvider.overrideWith(
              (_) => const EnvTestStub('https://api.example.com'),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Reemplazamos el http.Client interno por el mock vía un ApiClient
        // construido con la misma baseUrl que resolvió el provider desde el env.
        final providedClient = container.read(apiClientProvider);
        expect(providedClient.baseUrl, 'https://api.example.com');

        final probe = ApiClient(
          baseUrl: providedClient.baseUrl,
          inner: httpClient,
          timeout: const Duration(seconds: 15),
        );
        when(
          () => httpClient.get(any()),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await probe.getJson('/health');

        verify(
          () => httpClient.get(Uri.parse('https://api.example.com/health')),
        ).called(1);
      },
    );
  });
}

/// Stub de `Env` para tests: expone una base URL controlada.
class EnvTestStub implements Env {
  const EnvTestStub(this.apiBaseUrl);

  @override
  final String apiBaseUrl;
}
