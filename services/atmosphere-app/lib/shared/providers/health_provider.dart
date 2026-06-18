import 'package:atmosphere_app/shared/health/health_repository.dart';
import 'package:atmosphere_app/shared/health/health_repository_impl.dart';
import 'package:atmosphere_app/shared/services/api_client.dart';
import 'package:atmosphere_app/shared/state/health_notifier.dart';
import 'package:atmosphere_app/shared/state/health_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository de health, construido sobre el [apiClientProvider] (DI vía
/// Riverpod — no se hace `new` del cliente dentro del notifier).
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepositoryImpl(ref.read(apiClientProvider));
});

/// Estado del health check expuesto a la UI.
final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((
  ref,
) {
  return HealthNotifier(ref.read(healthRepositoryProvider));
});
