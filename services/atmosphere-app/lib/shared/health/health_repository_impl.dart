import 'package:atmosphere_app/shared/health/health_repository.dart';
import 'package:atmosphere_app/shared/services/api_client.dart';

/// Implementación del [HealthRepository] sobre el [ApiClient].
///
/// Devuelve dominio (aquí `void` = vivo); no filtra tipos de transporte a la UI.
/// El `ApiClient` ya mapea status >= 400 y errores de red a `AppException`, que
/// esta capa propaga tal cual.
class HealthRepositoryImpl implements HealthRepository {
  const HealthRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> check() async {
    // 200 -> el map se descarta (la UI sólo necesita "vivo"); >=400 / sin red
    // ya vienen como AppException desde el ApiClient.
    await _apiClient.getJson('/health');
  }
}
