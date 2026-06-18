import 'package:atmosphere_app/shared/health/health_repository.dart';
import 'package:atmosphere_app/shared/health/health_status.dart';
import 'package:atmosphere_app/shared/state/health_notifier.dart';
import 'package:atmosphere_app/shared/state/health_state.dart';

/// Repository de health que nunca toca la red (para tests deterministas).
class _NoopHealthRepository implements HealthRepository {
  const _NoopHealthRepository();

  @override
  Future<void> check() async {}
}

/// Notifier de health seedeado a un estado fijo. `checkHealth()` es no-op para
/// que el `initState` de la pantalla no altere el estado bajo test.
class FakeHealthNotifier extends HealthNotifier {
  FakeHealthNotifier(HealthStatus status, {String? error})
    : super(const _NoopHealthRepository()) {
    state = HealthState(status: status, error: error);
  }

  @override
  Future<void> checkHealth() async {
    // No-op: el estado lo fija el test al construir el fake.
  }
}
