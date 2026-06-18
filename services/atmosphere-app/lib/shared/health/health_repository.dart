/// Port del dominio de health (convención `networking`).
///
/// Los consumidores (notifier) dependen de esta interface, nunca del
/// `ApiClient`/`http.Client` directamente.
abstract interface class HealthRepository {
  /// Verifica que la API está disponible. Completa sin valor si está viva (200);
  /// lanza un `AppException` de dominio ante error de transporte o status >= 400.
  Future<void> check();
}
