import 'package:atmosphere_app/shared/health/health_status.dart';

/// Estado inmutable de la pantalla de health (convención `state-management`).
///
/// Las actualizaciones crean una instancia nueva vía [copyWith]. Estado inicial
/// [HealthStatus.loading] (la verificación se dispara al abrir la pantalla).
class HealthState {
  const HealthState({this.status = HealthStatus.loading, this.error});

  final HealthStatus status;

  /// Mensaje de error de dominio cuando [status] es [HealthStatus.error].
  final String? error;

  HealthState copyWith({HealthStatus? status, String? error}) {
    return HealthState(
      status: status ?? this.status,
      // En éxito se limpia el error; sólo se setea cuando se pasa explícito.
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HealthState && other.status == status && other.error == error;

  @override
  int get hashCode => Object.hash(status, error);
}
