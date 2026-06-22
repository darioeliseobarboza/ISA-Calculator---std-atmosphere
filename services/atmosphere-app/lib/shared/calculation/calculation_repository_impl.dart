import 'package:atmosphere_app/shared/calculation/calculation_repository.dart';
import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';
import 'package:atmosphere_app/shared/services/api_client.dart';

/// Implementación del [CalculationRepository] sobre el [ApiClient].
///
/// Mapea el request a JSON, llama `POST /v1/calculate` y decodea la respuesta a
/// dominio. Los tipos de transporte (status / body crudo) no llegan a la UI: el
/// `ApiClient` ya traduce status >= 400 y errores de red a `AppException`, que
/// esta capa propaga tal cual.
class CalculationRepositoryImpl implements CalculationRepository {
  const CalculationRepositoryImpl(this._apiClient);

  static const String _path = '/v1/calculate';

  final ApiClient _apiClient;

  @override
  Future<CalculationResponse> calculate(CalculationRequest request) async {
    final json = await _apiClient.postJson(_path, request.toJson());
    return CalculationResponse.fromJson(json);
  }
}
