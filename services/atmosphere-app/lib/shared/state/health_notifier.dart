import 'package:atmosphere_app/shared/errors/app_exception.dart';
import 'package:atmosphere_app/shared/health/health_repository.dart';
import 'package:atmosphere_app/shared/health/health_status.dart';
import 'package:atmosphere_app/shared/state/health_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier del health check (convención `state-management`).
///
/// Expone el método de intención [checkHealth]; no setters crudos. Captura
/// `AppException` y la traduce a un estado `error` (nunca relanza).
class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier(this._repository) : super(const HealthState());

  final HealthRepository _repository;

  Future<void> checkHealth() async {
    state = state.copyWith(status: HealthStatus.loading);
    try {
      await _repository.check();
      state = state.copyWith(status: HealthStatus.alive);
    } on AppException catch (e) {
      state = state.copyWith(status: HealthStatus.error, error: e.message);
    }
  }
}
