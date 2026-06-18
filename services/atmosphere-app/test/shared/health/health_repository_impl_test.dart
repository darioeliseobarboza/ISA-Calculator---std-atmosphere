import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:atmosphere_app/shared/health/health_repository.dart';
import 'package:atmosphere_app/shared/health/health_repository_impl.dart';
import 'package:atmosphere_app/shared/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late HealthRepository repository;

  setUp(() {
    apiClient = _MockApiClient();
    repository = HealthRepositoryImpl(apiClient);
  });

  group('HealthRepositoryImpl.check', () {
    test('TS-6: mapea 200 a dominio (completa sin lanzar)', () async {
      when(() => apiClient.getJson('/health')).thenAnswer(
        (_) async => {'status': 'ok', 'timestamp': '2026-06-12T16:00:00Z'},
      );

      await expectLater(repository.check(), completes);
      verify(() => apiClient.getJson('/health')).called(1);
    });

    test('TS-7: propaga error de transporte (NetworkException)', () async {
      when(
        () => apiClient.getJson('/health'),
      ).thenThrow(const NetworkException());

      await expectLater(repository.check(), throwsA(isA<NetworkException>()));
    });
  });
}
