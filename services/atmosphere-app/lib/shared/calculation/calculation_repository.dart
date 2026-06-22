import 'package:atmosphere_app/shared/models/calculation_request.dart';
import 'package:atmosphere_app/shared/models/calculation_response.dart';

/// Port del dominio `calculator` (convención `networking`).
///
/// Los consumidores (notifier) dependen de esta interface, nunca del
/// `ApiClient`/`http.Client` directamente. Devuelve dominio
/// ([CalculationResponse]); lanza un `AppException` ante error de transporte o
/// status >= 400 (ya mapeado por el `ApiClient`).
abstract interface class CalculationRepository {
  /// Resuelve `POST /v1/calculate` y devuelve el resultado de dominio.
  Future<CalculationResponse> calculate(CalculationRequest request);
}
